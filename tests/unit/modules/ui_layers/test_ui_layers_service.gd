extends GutTest
## Unit tests for [code]UiLayersService[/code].


const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const TooltipsTypes = preload("res://addons/modular_ui_architecture/modules/tooltips/types.gd")
const PopupsTypes = preload("res://addons/modular_ui_architecture/modules/popups/types.gd")
const UiLayersFixture = preload("res://tests/fixtures/ui_layers/layers.gd")
const InputBindingsTypes = preload("res://addons/modular_ui_architecture/modules/input_bindings/types.gd")
const UiLayersService = preload("res://addons/modular_ui_architecture/modules/ui_layers/services/ui_layers.svc.gd")
const HudUiLayerNode = preload("res://demo/modules/layers/nodes/hud_ui_layer.gd")

const SCENE_PATH := "res://tests/fixtures/scenes/empty_control.tscn"
const POPUP_LAYER := PopupsTypes.POPUPS_LAYER
const DEFAULT_LAYER := UiLayersTypes.DEFAULT_LAYER

var _service: UiLayersService


func before_each() -> void:
	_service = UiLayersFixture.make_service()
	_service.enable()
	# The layer container is added to the root with call_deferred.
	await wait_process_frames(2)


func after_each() -> void:
	_service.disable()
	await wait_process_frames(1)


func test_enable_creates_one_layer_node_per_layer() -> void:
	assert_eq(_service.get_layers().size(), UiLayersFixture.make_registry().get_layer_registrations().size())


func test_get_layer_node_returns_node_matching_layer() -> void:
	for layer in _service.get_layers():
		var layer_node := _service.get_layer_node(layer)

		assert_not_null(layer_node, "Layer %s has a node" % layer)
		assert_eq(layer_node.ui_layer, layer)


func test_get_world_ui_container_is_child_of_its_layer_node() -> void:
	var layer_node := _service.get_layer_node(UiLayersFixture.DemoTokens.Layers.HUD)

	var container := _service.get_world_ui_container(UiLayersFixture.DemoTokens.Layers.HUD)

	assert_not_null(container)
	assert_eq(container.get_parent(), layer_node)


func test_mount_ui_adds_node_to_requested_layer() -> void:
	var node := _service.mount_ui(SCENE_PATH, UiLayersFixture.DemoTokens.Layers.HUD)

	assert_not_null(node)
	assert_eq(node.get_parent(), _service.get_layer_node(UiLayersFixture.DemoTokens.Layers.HUD))


func test_mount_ui_returns_null_when_path_is_not_a_scene() -> void:
	var node := _service.mount_ui(
		"res://tests/fixtures/scripts/base_script.gd", UiLayersFixture.DemoTokens.Layers.HUD
	)

	assert_null(node)
	assert_push_error("is not a PackedScene")


func test_unmount_ui_finds_plain_node_mounted_in_a_non_popup_layer() -> void:
	var node := _service.mount_ui(SCENE_PATH, UiLayersFixture.DemoTokens.Layers.HUD)

	var is_success := _service.unmount_ui(node)

	assert_true(is_success)


func test_unmount_ui_removes_mounted_node() -> void:
	var node := _service.mount_ui(SCENE_PATH, UiLayersFixture.DemoTokens.Layers.HUD)

	var is_success := _service.unmount_ui(node)

	assert_true(is_success)
	assert_null(node.get_parent())


func test_unmount_ui_returns_false_for_node_in_no_layer() -> void:
	var stray := Node.new()
	autofree(stray)

	var is_success := _service.unmount_ui(stray)

	assert_false(is_success)
	assert_push_error("not found in any layer")


func test_window_layer_accepts_only_one_mounted_node() -> void:
	var first := _service.mount_ui(SCENE_PATH, UiLayersFixture.DemoTokens.Layers.WINDOW)
	var second := _service.mount_ui(SCENE_PATH, UiLayersFixture.DemoTokens.Layers.WINDOW)

	assert_not_null(first)
	assert_null(second)


func test_hud_layer_uses_hud_ui_layer_script() -> void:
	var layer := _service.get_layer_node(UiLayersFixture.DemoTokens.Layers.HUD)

	assert_eq(layer.get_script(), HudUiLayerNode)


func test_every_layer_uses_the_script_it_registered() -> void:
	for registration in UiLayersFixture.make_registry().get_layer_registrations():
		var layer_node := _service.get_layer_node(registration.token)

		assert_eq(layer_node.get_script(), registration.node_script, "Layer '%s'" % registration.token)


func test_hud_layer_accepts_only_one_mounted_node() -> void:
	var first := _service.mount_ui(SCENE_PATH, UiLayersFixture.DemoTokens.Layers.HUD)
	var second := _service.mount_ui(SCENE_PATH, UiLayersFixture.DemoTokens.Layers.HUD)

	assert_not_null(first)
	assert_null(second)


func test_input_is_not_blocked_when_nothing_is_mounted() -> void:
	assert_false(_service.is_layer_input_blocked(DEFAULT_LAYER))
	assert_false(_service.is_layer_input_blocked(UiLayersFixture.DemoTokens.Layers.HUD))


func test_mounted_popup_blocks_input_of_lower_layers() -> void:
	_service.mount_ui(SCENE_PATH, POPUP_LAYER)

	assert_true(_service.is_layer_input_blocked(DEFAULT_LAYER))
	assert_true(_service.is_layer_input_blocked(UiLayersFixture.DemoTokens.Layers.HUD))


func test_popup_layer_itself_is_not_blocked_by_its_own_popup() -> void:
	_service.mount_ui(SCENE_PATH, POPUP_LAYER)

	assert_false(_service.is_layer_input_blocked(POPUP_LAYER))


func test_tooltip_layer_is_not_blocked_by_popup() -> void:
	_service.mount_ui(SCENE_PATH, POPUP_LAYER)

	assert_false(_service.is_layer_input_blocked(TooltipsTypes.TOOLTIPS_LAYER))


func test_unmounting_blocking_popup_unblocks_lower_layers() -> void:
	var popup := _service.mount_ui(SCENE_PATH, POPUP_LAYER)

	_service.unmount_ui(popup)

	assert_false(_service.is_layer_input_blocked(DEFAULT_LAYER))


func test_notify_input_triggered_emits_layer_signal() -> void:
	watch_signals(_service)

	_service.notify_input_triggered(&"ui_accept", UiLayersFixture.DemoTokens.Layers.HUD)

	assert_signal_emitted_with_parameters(
		_service, "ui_layer_input_triggered",
		[&"ui_accept", UiLayersFixture.DemoTokens.Layers.HUD, InputBindingsTypes.InputActionType.PRESSED]
	)


func test_disable_without_layer_container_warns_and_does_not_fail() -> void:
	var container := get_tree().root.get_node_or_null(NodePath(UiLayersService.LAYER_CONTAINER_NODE_NAME))
	assert_not_null(container)
	container.free()

	_service.disable()

	assert_push_warning("Layer Container node is not present in the tree")
