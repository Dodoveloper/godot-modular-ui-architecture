extends GutTest
## Unit tests for the input broadcast split in [code]UiLayerNode[/code] (see ADR-001).[br]
## Events are fed directly to [code]_input[/code] / [code]_unhandled_input[/code] so the test
## checks which phase broadcasts which action, without depending on focus state.


const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const InputBindingsTypes = preload("res://addons/modular_ui_architecture/modules/input_bindings/types.gd")
const UiLayersService = preload("res://addons/modular_ui_architecture/modules/ui_layers/services/ui_layers.svc.gd")

const SCENE_PATH := "res://tests/fixtures/scenes/empty_control.tscn"
const DEFAULT_LAYER := UiLayersTypes.UiLayer.DEFAULT
const SIGNAL_NAME := "ui_layer_input_triggered"

var _service: UiLayersService


func before_each() -> void:
	_service = UiLayersService.new()
	_service.enable()
	await wait_process_frames(2)
	watch_signals(_service)


func after_each() -> void:
	_service.disable()
	await wait_process_frames(1)


func _make_pressed_event(action: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func test_focus_nav_action_is_broadcast_from_input_phase() -> void:
	var layer := _service.get_layer_node(DEFAULT_LAYER)

	layer._input(_make_pressed_event(&"ui_up"))

	assert_signal_emitted(_service, SIGNAL_NAME)


func test_non_focus_nav_action_is_not_broadcast_from_input_phase() -> void:
	var layer := _service.get_layer_node(DEFAULT_LAYER)

	layer._input(_make_pressed_event(&"ui_accept"))

	assert_signal_not_emitted(_service, SIGNAL_NAME)


func test_non_focus_nav_action_is_broadcast_from_unhandled_input_phase() -> void:
	var layer := _service.get_layer_node(DEFAULT_LAYER)

	layer._unhandled_input(_make_pressed_event(&"ui_accept"))

	assert_signal_emitted(_service, SIGNAL_NAME)


func test_focus_nav_broadcast_from_input_is_skipped_when_layer_is_obstructed() -> void:
	# A mounted popup blocks input of every lower layer, so the DEFAULT layer must not pre-empt it.
	_service.mount_ui(SCENE_PATH, UiLayersTypes.UiLayer.POPUP)
	var layer := _service.get_layer_node(DEFAULT_LAYER)

	layer._input(_make_pressed_event(&"ui_up"))

	assert_signal_not_emitted(_service, SIGNAL_NAME)


func test_released_event_is_broadcast_as_released() -> void:
	var layer := _service.get_layer_node(DEFAULT_LAYER)
	var event := InputEventAction.new()
	event.action = &"ui_accept"
	event.pressed = false

	layer._unhandled_input(event)

	assert_signal_emitted_with_parameters(
		_service, SIGNAL_NAME,
		[&"ui_accept", DEFAULT_LAYER, InputBindingsTypes.InputActionType.RELEASED]
	)
