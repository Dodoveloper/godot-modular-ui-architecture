extends GutTest
## Unit tests for [code]PopupsUiLayer[/code] (mounting, hierarchy, closing rules, close transition).


const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const UiLayersService = preload("res://addons/modular_ui_architecture/modules/ui_layers/services/ui_layers.svc.gd")
const PopupTypes = preload("res://addons/modular_ui_architecture/modules/popups/types.gd")
const PopupsUiLayer = preload("res://addons/modular_ui_architecture/modules/ui_layers/nodes/popups_ui_layer.gd")

const SCENE_PATH := "res://tests/fixtures/scenes/empty_control.tscn"
const TRANSITION_SCENE_PATH := "res://tests/fixtures/scenes/transition_popup.tscn"
const POPUP_LAYER := UiLayersTypes.UiLayer.POPUP

var _service: UiLayersService
var _layer: PopupsUiLayer


func before_each() -> void:
	_service = UiLayersService.new()
	_service.enable()
	await wait_process_frames(2)
	_layer = _service.get_layer_node(POPUP_LAYER)


func after_each() -> void:
	_service.disable()
	await wait_process_frames(1)


func _mount(path := SCENE_PATH, data: Dictionary[StringName, Variant] = {}) -> Control:
	return _service.mount_ui(path, POPUP_LAYER, data) as Control


func _click(button: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	return event


func test_has_popups_is_false_when_empty() -> void:
	assert_false(_layer.has_popups())


func test_mounted_popup_is_tracked() -> void:
	var popup := _mount()

	assert_true(_layer.has_popups())
	assert_has(_layer.get_mounted_nodes(), popup)


func test_popup_is_placed_inside_a_background_rect() -> void:
	var popup := _mount()

	assert_true(popup.get_parent() is ColorRect)


func test_background_takes_requested_color() -> void:
	var popup := _mount(SCENE_PATH, {&"color": Color.RED} as Dictionary[StringName, Variant])

	assert_eq((popup.get_parent() as ColorRect).color, Color.RED)


func test_popup_takes_requested_position() -> void:
	var popup := _mount(SCENE_PATH, {&"position": Vector2(10, 20)} as Dictionary[StringName, Variant])

	assert_eq(popup.position, Vector2(10, 20))


func test_unmount_closes_popup_and_clears_tracking() -> void:
	var popup := _mount()

	var is_success := _service.unmount_ui(popup)

	assert_true(is_success)
	assert_false(_layer.has_popups())


func test_blocking_child_prevents_parent_from_closing() -> void:
	var parent := _mount()
	var child_data: Dictionary[StringName, Variant] = {&"parent": parent, &"is_blocking": true}
	_mount(SCENE_PATH, child_data)

	var is_success := _service.unmount_ui(parent)

	assert_false(is_success)
	assert_eq(_layer.get_mounted_nodes().size(), 2)


func test_non_blocking_child_is_closed_together_with_parent() -> void:
	var parent := _mount()
	var child_data: Dictionary[StringName, Variant] = {&"parent": parent, &"is_blocking": false}
	_mount(SCENE_PATH, child_data)

	var is_success := _service.unmount_ui(parent)

	assert_true(is_success)
	assert_false(_layer.has_popups())


func test_popup_with_unregistered_parent_is_mounted_without_hierarchy() -> void:
	var unregistered_parent := Control.new()
	autofree(unregistered_parent)
	var data: Dictionary[StringName, Variant] = {&"parent": unregistered_parent}

	var popup := _mount(SCENE_PATH, data)

	assert_not_null(popup)
	assert_push_warning("parent argument is not a registered one")


func test_background_click_closes_popup() -> void:
	var popup := _mount()
	var background := popup.get_parent() as Control

	background.gui_input.emit(_click(MOUSE_BUTTON_LEFT))

	assert_false(_layer.has_popups())


func test_background_click_is_ignored_when_dismiss_on_click_outside_is_disabled() -> void:
	var data: Dictionary[StringName, Variant] = {&"dismiss_on_click_outside": false}
	var popup := _mount(SCENE_PATH, data)
	var background := popup.get_parent() as Control

	background.gui_input.emit(_click(MOUSE_BUTTON_LEFT))

	assert_true(_layer.has_popups())


func test_right_click_on_background_does_not_close_popup() -> void:
	var popup := _mount()
	var background := popup.get_parent() as Control

	background.gui_input.emit(_click(MOUSE_BUTTON_RIGHT))

	assert_true(_layer.has_popups())


func test_close_transition_defers_unmount_until_transition_finishes() -> void:
	var popup := _mount(TRANSITION_SCENE_PATH)

	var is_success := _service.unmount_ui(popup)

	assert_true(is_success)
	assert_eq(popup.begin_close_count, 1)
	assert_true(_layer.has_popups(), "Still tracked while the transition plays")

	popup.close_transition_finished.emit()

	assert_false(_layer.has_popups())


func test_close_transition_receives_close_reason() -> void:
	var popup := _mount(TRANSITION_SCENE_PATH)

	_service.unmount_ui(popup)

	# unmount_ui() goes through the default close path, which is CloseReason.SERVICE.
	assert_eq(popup.last_close_reason, PopupTypes.CloseReason.SERVICE)


func test_second_close_request_during_transition_is_ignored() -> void:
	var popup := _mount(TRANSITION_SCENE_PATH)
	_service.unmount_ui(popup)

	var is_second_success := _service.unmount_ui(popup)

	assert_false(is_second_success)
	assert_eq(popup.begin_close_count, 1)
