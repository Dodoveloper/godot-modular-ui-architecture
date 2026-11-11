extends GutTest
## Unit tests for how registered layers are ordered and how they block each other. These cover the
## behaviour that depends on the registry's order: layers are drawn in order, and a blocking layer
## blocks only the layers below it.


const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const UiLayersService = preload("res://addons/modular_ui_architecture/modules/ui_layers/services/ui_layers.svc.gd")
const UiLayersFixture = preload("res://tests/fixtures/ui_layers/layers.gd")
const DemoTokens = preload("res://demo/shared/classes/tokens.gd")
const PopupsTypes = preload("res://addons/modular_ui_architecture/modules/popups/types.gd")
const TooltipsTypes = preload("res://addons/modular_ui_architecture/modules/tooltips/types.gd")
const DefaultUiLayerNode = preload("res://addons/modular_ui_architecture/modules/ui_layers/nodes/default_ui_layer.gd")

const SCENE_PATH := "res://tests/fixtures/scenes/empty_control.tscn"

var _service: UiLayersService


func before_each() -> void:
	_service = UiLayersFixture.make_service()
	_service.enable()
	await wait_process_frames(2)


func after_each() -> void:
	_service.disable()
	await wait_process_frames(1)


func test_get_layers_starts_with_the_default_layer() -> void:
	assert_eq(_service.get_layers()[0], UiLayersTypes.DEFAULT_LAYER)


func test_canvas_indices_are_dense_and_follow_draw_order() -> void:
	var canvas_indices: Array[int] = []
	for layer in _service.get_layers():
		canvas_indices.append(_service.get_layer_node(layer).layer)

	var expected: Array[int] = []
	for i in canvas_indices.size():
		expected.append(i + 1)
	assert_eq(canvas_indices, expected)


func test_tooltip_layer_is_drawn_above_popup_layer() -> void:
	var popup_index := _service.get_layer_node(PopupsTypes.POPUPS_LAYER).layer
	var tooltip_index := _service.get_layer_node(TooltipsTypes.TOOLTIPS_LAYER).layer

	assert_gt(tooltip_index, popup_index)


func test_popup_blocks_input_of_window_below_it() -> void:
	_service.mount_ui(SCENE_PATH, PopupsTypes.POPUPS_LAYER)

	assert_true(_service.is_layer_input_blocked(DemoTokens.Layers.WINDOW))


func test_window_blocks_input_of_hud_below_it() -> void:
	_service.mount_ui(SCENE_PATH, DemoTokens.Layers.WINDOW)

	assert_true(_service.is_layer_input_blocked(DemoTokens.Layers.HUD))


func test_tooltip_does_not_block_popup_below_it() -> void:
	_service.mount_ui(SCENE_PATH, TooltipsTypes.TOOLTIPS_LAYER)

	assert_false(_service.is_layer_input_blocked(PopupsTypes.POPUPS_LAYER))


func test_layer_registered_between_two_layers_takes_its_place_in_draw_order() -> void:
	var registry := UiLayersFixture.make_registry()
	registry.register_layer(UiLayersTypes.UiLayerRegistration.new(
&"between", DefaultUiLayerNode, UiLayersTypes.Order.WINDOW + 50
	))
	var service := UiLayersService.new(registry)
	service.enable()
	await wait_process_frames(2)

	var layers := service.get_layers()
	var window_at := layers.find(DemoTokens.Layers.WINDOW)
	var between_at := layers.find(&"between")
	var popup_at := layers.find(PopupsTypes.POPUPS_LAYER)

	assert_gt(between_at, window_at)
	assert_lt(between_at, popup_at)
	service.disable()
	await wait_process_frames(1)


func test_layer_registered_between_two_layers_does_not_block_below_it() -> void:
	var registry := UiLayersFixture.make_registry()
	registry.register_layer(UiLayersTypes.UiLayerRegistration.new(
&"between", DefaultUiLayerNode, UiLayersTypes.Order.WINDOW + 50
	))
	var service := UiLayersService.new(registry)
	service.enable()
	await wait_process_frames(2)

	service.mount_ui(SCENE_PATH, &"between")

	assert_false(service.is_layer_input_blocked(DemoTokens.Layers.WINDOW))
	service.disable()
	await wait_process_frames(1)
