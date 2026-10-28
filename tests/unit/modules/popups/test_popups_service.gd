extends GutTest
## Unit tests for [code]PopupsService[/code], backed by a real [code]UiLayersService[/code].


const PopupsService = preload("res://addons/modular_ui_architecture/modules/popups/services/popups.svc.gd")
const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const UiLayersService = preload("res://addons/modular_ui_architecture/modules/ui_layers/services/ui_layers.svc.gd")
const PopupsUiLayer = preload("res://addons/modular_ui_architecture/modules/ui_layers/nodes/popups_ui_layer.gd")

const SCENE_PATH := "res://tests/fixtures/scenes/empty_control.tscn"

var _ui_layers: UiLayersService
var _popups_layer: PopupsUiLayer
var _service: PopupsService


func before_each() -> void:
	_ui_layers = UiLayersService.new()
	_ui_layers.enable()
	await wait_process_frames(2)
	_popups_layer = _ui_layers.get_layer_node(UiLayersTypes.UiLayer.POPUP)
	_service = PopupsService.new(_ui_layers)


func after_each() -> void:
	_service.disable()
	_ui_layers.disable()
	await wait_process_frames(1)


func test_has_popups_is_false_initially() -> void:
	assert_false(_service.has_popups())


func test_open_popup_mounts_and_returns_popup() -> void:
	var popup := _service.open_popup(SCENE_PATH)

	assert_not_null(popup)
	assert_true(_service.has_popups())


func test_open_popup_applies_background_color() -> void:
	var popup := _service.open_popup(SCENE_PATH, null, Vector2.ZERO, false, Color.BLUE)

	assert_eq((popup.get_parent() as ColorRect).color, Color.BLUE)


func test_close_popup_closes_the_given_popup() -> void:
	var popup := _service.open_popup(SCENE_PATH)

	var is_success := _service.close_popup(popup)

	assert_true(is_success)
	assert_false(_service.has_popups())


func test_close_topmost_popup_closes_the_most_recent_one() -> void:
	var bottom := _service.open_popup(SCENE_PATH)
	var top := _service.open_popup(SCENE_PATH)

	_service.close_topmost_popup()

	assert_has(_popups_layer.get_mounted_nodes(), bottom)
	assert_false(_popups_layer.get_mounted_nodes().has(top))


func test_close_topmost_popup_pushes_error_when_nothing_is_open() -> void:
	_service.close_topmost_popup()

	assert_push_error("There are no popups to be closed")


func test_queued_popup_waits_until_active_one_leaves_the_tree() -> void:
	_service.open_popup_queued(SCENE_PATH)
	_service.open_popup_queued(SCENE_PATH)
	assert_eq(_popups_layer.get_mounted_nodes().size(), 1, "Second request is queued")

	var first: Control = _popups_layer.get_mounted_nodes()[0]
	_service.close_popup(first)
	await wait_process_frames(2)

	assert_false(is_instance_valid(first), "Active queued popup was closed")
	assert_eq(_popups_layer.get_mounted_nodes().size(), 1, "Next queued popup is now open")


func test_open_popup_queued_forwards_arguments_to_popup_layer_queue() -> void:
	var setup := func(_popup: Control) -> void: pass

	_service.open_popup_queued(SCENE_PATH, Color.GREEN, setup, true)

	var popup: Control = _popups_layer.get_mounted_nodes()[0]
	assert_eq((popup.get_parent() as ColorRect).color, Color.GREEN)
	assert_true(_popups_layer._popups[popup].dismiss_on_click_outside)
	assert_true(_popups_layer._popups[popup].is_blocking)
