extends GutTest
## Unit tests for [code]UiLayersService[/code].


const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const InputBindingsTypes = preload("res://addons/modular_ui_architecture/modules/input_bindings/types.gd")
const UiLayersService = preload("res://addons/modular_ui_architecture/modules/ui_layers/services/ui_layers.svc.gd")

const SCENE_PATH := "res://tests/fixtures/scenes/empty_control.tscn"
const POPUP_LAYER := UiLayersTypes.UiLayer.POPUP
const DEFAULT_LAYER := UiLayersTypes.UiLayer.DEFAULT

var _service: UiLayersService


func before_each() -> void:
	_service = UiLayersService.new()
	_service.enable()
	# The layer container is added to the root with call_deferred.
	await wait_process_frames(2)


func after_each() -> void:
	_service.disable()
	await wait_process_frames(1)


func test_enable_creates_one_layer_node_per_layer() -> void:
	assert_eq(_service.get_layers().size(), UiLayersTypes.UiLayer.size())


func test_get_layer_node_returns_node_matching_layer() -> void:
	for layer in UiLayersTypes.UiLayer.values():
		var layer_node := _service.get_layer_node(layer)

		assert_not_null(layer_node, "Layer %s has a node" % layer)
		assert_eq(layer_node.ui_layer, layer)


func test_get_world_ui_container_is_child_of_its_layer_node() -> void:
	var layer_node := _service.get_layer_node(UiLayersTypes.UiLayer.HUD)

	var container := _service.get_world_ui_container(UiLayersTypes.UiLayer.HUD)

	assert_not_null(container)
	assert_eq(container.get_parent(), layer_node)


func test_mount_ui_adds_node_to_requested_layer() -> void:
	var node := _service.mount_ui(SCENE_PATH, UiLayersTypes.UiLayer.HUD)

	assert_not_null(node)
	assert_eq(node.get_parent(), _service.get_layer_node(UiLayersTypes.UiLayer.HUD))


func test_mount_ui_returns_null_when_path_is_not_a_scene() -> void:
	var node := _service.mount_ui(
		"res://tests/fixtures/scripts/base_script.gd", UiLayersTypes.UiLayer.HUD
	)

	assert_null(node)
	assert_push_error("is not a PackedScene")


func test_unmount_ui_removes_mounted_node() -> void:
	var node := _service.mount_ui(SCENE_PATH, UiLayersTypes.UiLayer.HUD)

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
	var first := _service.mount_ui(SCENE_PATH, UiLayersTypes.UiLayer.WINDOW)
	var second := _service.mount_ui(SCENE_PATH, UiLayersTypes.UiLayer.WINDOW)

	assert_not_null(first)
	assert_null(second)


func test_input_is_not_blocked_when_nothing_is_mounted() -> void:
	assert_false(_service.is_layer_input_blocked(DEFAULT_LAYER))
	assert_false(_service.is_layer_input_blocked(UiLayersTypes.UiLayer.HUD))


func test_mounted_popup_blocks_input_of_lower_layers() -> void:
	_service.mount_ui(SCENE_PATH, POPUP_LAYER)

	assert_true(_service.is_layer_input_blocked(DEFAULT_LAYER))
	assert_true(_service.is_layer_input_blocked(UiLayersTypes.UiLayer.HUD))


func test_popup_layer_itself_is_not_blocked_by_its_own_popup() -> void:
	_service.mount_ui(SCENE_PATH, POPUP_LAYER)

	assert_false(_service.is_layer_input_blocked(POPUP_LAYER))


func test_tooltip_layer_is_not_blocked_by_popup() -> void:
	_service.mount_ui(SCENE_PATH, POPUP_LAYER)

	assert_false(_service.is_layer_input_blocked(UiLayersTypes.UiLayer.TOOLTIP))


func test_unmounting_blocking_popup_unblocks_lower_layers() -> void:
	var popup := _service.mount_ui(SCENE_PATH, POPUP_LAYER)

	_service.unmount_ui(popup)

	assert_false(_service.is_layer_input_blocked(DEFAULT_LAYER))


func test_notify_input_triggered_emits_layer_signal() -> void:
	watch_signals(_service)

	_service.notify_input_triggered(&"ui_accept", UiLayersTypes.UiLayer.HUD)

	assert_signal_emitted_with_parameters(
		_service, "ui_layer_input_triggered",
		[&"ui_accept", UiLayersTypes.UiLayer.HUD, InputBindingsTypes.InputActionType.PRESSED]
	)
