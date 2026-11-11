extends GutTest
## Unit tests for the UiLayerNode base: mounted-node listing, unmounting, PRESSED/RELEASED
## broadcast, and blocking vs non-blocking input handling.
##
## Input methods are called directly, since headless tests do not run the engine's input pipeline.
## The blocking checks read the viewport's handled state, so the layers are real nodes in the tree.


const PopupsTypes = preload("res://addons/modular_ui_architecture/modules/popups/types.gd")
const UiLayersFixture = preload("res://tests/fixtures/ui_layers/layers.gd")
const UiLayersService = preload("res://addons/modular_ui_architecture/modules/ui_layers/services/ui_layers.svc.gd")
const InputBindingsTypes = preload("res://addons/modular_ui_architecture/modules/input_bindings/types.gd")

const SCENE_PATH := "res://tests/fixtures/scenes/empty_control.tscn"
const SIGNAL_NAME := "ui_layer_input_triggered"

var _service: UiLayersService


func before_each() -> void:
	_service = UiLayersFixture.make_service()
	_service.enable()
	await wait_process_frames(2)
	# The layers only cache their input actions in _ready(), so they must be in the tree. Adding
	# them to the tree is what makes _broadcast_input() see the project's actions.
	for layer in _service.get_layers():
		var layer_node := _service.get_layer_node(layer)
		if not layer_node.is_inside_tree():
			add_child_autofree(layer_node)
	await wait_process_frames(1)
	watch_signals(_service)


func after_each() -> void:
	_service.disable()
	await wait_process_frames(1)


func _action_event(action: StringName, pressed: bool) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	return event


func test_get_mounted_nodes_is_empty_for_fresh_layer() -> void:
	var layer := _service.get_layer_node(UiLayersFixture.DemoTokens.Layers.HUD)

	assert_true(layer.get_mounted_nodes().is_empty())


func test_get_mounted_nodes_excludes_world_ui_container() -> void:
	var layer := _service.get_layer_node(UiLayersFixture.DemoTokens.Layers.HUD)
	var world_container := _service.get_world_ui_container(UiLayersFixture.DemoTokens.Layers.HUD)
	var node := _service.mount_ui(SCENE_PATH, UiLayersFixture.DemoTokens.Layers.HUD)

	var mounted := layer.get_mounted_nodes()

	# The world container is a real child of the layer, but it is infrastructure, not mounted UI.
	assert_eq(world_container.get_parent(), layer)
	assert_eq(mounted.size(), 1)
	assert_has(mounted, node)
	assert_does_not_have(mounted, world_container)


func test_unmount_node_removes_and_frees_mounted_node() -> void:
	var layer := _service.get_layer_node(UiLayersFixture.DemoTokens.Layers.HUD)
	var node := _service.mount_ui(SCENE_PATH, UiLayersFixture.DemoTokens.Layers.HUD)

	var is_success := layer.unmount_node(node)
	await wait_process_frames(2)

	assert_true(is_success)
	assert_freed(node)


func test_broadcast_sends_pressed_then_released() -> void:
	var layer := _service.get_layer_node(UiLayersFixture.DemoTokens.Layers.HUD)

	# assert_signal_emitted_with_parameters() checks the most recent emission, so check each in turn.
	layer._broadcast_input(_action_event(&"ui_accept", true))
	assert_signal_emitted_with_parameters(
		_service, SIGNAL_NAME,
		[&"ui_accept", UiLayersFixture.DemoTokens.Layers.HUD, InputBindingsTypes.InputActionType.PRESSED]
	)

	layer._broadcast_input(_action_event(&"ui_accept", false))
	assert_signal_emitted_with_parameters(
		_service, SIGNAL_NAME,
		[&"ui_accept", UiLayersFixture.DemoTokens.Layers.HUD, InputBindingsTypes.InputActionType.RELEASED]
	)


## _unhandled_input() marks the viewport handled only when the layer blocks and has mounted nodes.
## The viewport flag itself is shared by every test and never reset, so these tests check that
## condition on the layer's state instead of the flag. See tests/README.md.
func test_blocking_layer_with_mounted_node_meets_handling_condition() -> void:
	var popups := _service.get_layer_node(PopupsTypes.POPUPS_LAYER)
	_service.mount_ui(SCENE_PATH, PopupsTypes.POPUPS_LAYER)
	await wait_process_frames(1)

	assert_true(popups.should_block_inputs and popups.get_mounted_nodes().size() > 0)


func test_non_blocking_layer_never_meets_handling_condition() -> void:
	var hud := _service.get_layer_node(UiLayersFixture.DemoTokens.Layers.HUD)
	_service.mount_ui(SCENE_PATH, UiLayersFixture.DemoTokens.Layers.HUD)
	await wait_process_frames(1)

	assert_false(hud.should_block_inputs and hud.get_mounted_nodes().size() > 0)


func test_blocking_layer_without_mounted_nodes_does_not_meet_handling_condition() -> void:
	var popups := _service.get_layer_node(PopupsTypes.POPUPS_LAYER)
	await wait_process_frames(1)

	assert_false(popups.should_block_inputs and popups.get_mounted_nodes().size() > 0)
