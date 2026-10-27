extends GutTest
## Unit tests for [code]InputBindingsService[/code].
## Uses a real registry and a real [code]UiLayersService[/code] signal source, so no mocks are needed.


const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const InputBindingsTypes = preload("res://addons/modular_ui_architecture/modules/input_bindings/types.gd")
const InputBindingsRegistry = preload("res://addons/modular_ui_architecture/modules/input_bindings/registries/input_bindings.reg.gd")
const InputBindingsService = preload("res://addons/modular_ui_architecture/modules/input_bindings/services/input_bindings.svc.gd")
const UiLayersService = preload("res://addons/modular_ui_architecture/modules/ui_layers/services/ui_layers.svc.gd")
const FakeBinding = preload("res://tests/fixtures/input_bindings/fake_binding.gd")

const ACTION := &"toggle_test"

var _registry: InputBindingsRegistry
var _ui_layers: UiLayersService
var _service: InputBindingsService


func before_each() -> void:
	_registry = InputBindingsRegistry.new()
	_ui_layers = UiLayersService.new()
	_service = InputBindingsService.new(_registry, _ui_layers)


func after_each() -> void:
	_service.disable()


func _make_binding(
	should_execute := true, layer := UiLayersTypes.UiLayer.DEFAULT,
	input_type := InputBindingsTypes.InputActionType.PRESSED, priority := 0
) -> FakeBinding:
	var binding := FakeBinding.new(layer, input_type)
	binding.should_execute_result = should_execute
	binding.priority = priority
	_registry.register_binding(ACTION, binding)
	return binding


func test_returns_false_when_no_bindings_for_action() -> void:
	assert_false(_service.trigger_bindings(ACTION))


func test_executes_matching_binding_and_returns_true() -> void:
	var binding := _make_binding()

	var executed := _service.trigger_bindings(ACTION)

	assert_true(executed)
	assert_eq(binding.execute_count, 1)


func test_skips_binding_when_should_execute_is_false() -> void:
	var binding := _make_binding(false)

	var executed := _service.trigger_bindings(ACTION)

	assert_false(executed)
	assert_eq(binding.execute_count, 0)


func test_skips_binding_on_different_layer() -> void:
	var binding := _make_binding(true, UiLayersTypes.UiLayer.HUD)

	var executed := _service.trigger_bindings(ACTION, UiLayersTypes.UiLayer.DEFAULT)

	assert_false(executed)
	assert_eq(binding.execute_count, 0)


func test_skips_binding_on_different_input_type() -> void:
	var binding := _make_binding(
		true, UiLayersTypes.UiLayer.DEFAULT, InputBindingsTypes.InputActionType.RELEASED
	)

	var executed := _service.trigger_bindings(ACTION, UiLayersTypes.UiLayer.DEFAULT,
		InputBindingsTypes.InputActionType.PRESSED)

	assert_false(executed)
	assert_eq(binding.execute_count, 0)


func test_executes_binding_matching_released_input_type() -> void:
	var binding := _make_binding(
		true, UiLayersTypes.UiLayer.DEFAULT, InputBindingsTypes.InputActionType.RELEASED
	)

	var executed := _service.trigger_bindings(ACTION, UiLayersTypes.UiLayer.DEFAULT,
		InputBindingsTypes.InputActionType.RELEASED)

	assert_true(executed)
	assert_eq(binding.execute_count, 1)


func test_only_first_eligible_binding_executes() -> void:
	var high := _make_binding(true, UiLayersTypes.UiLayer.DEFAULT,
		InputBindingsTypes.InputActionType.PRESSED, 10)
	var low := _make_binding(true, UiLayersTypes.UiLayer.DEFAULT,
		InputBindingsTypes.InputActionType.PRESSED, 0)

	_service.trigger_bindings(ACTION)

	assert_eq(high.execute_count, 1)
	assert_eq(low.execute_count, 0)


func test_falls_through_to_next_binding_when_higher_priority_declines() -> void:
	var high := _make_binding(false, UiLayersTypes.UiLayer.DEFAULT,
		InputBindingsTypes.InputActionType.PRESSED, 10)
	var low := _make_binding(true, UiLayersTypes.UiLayer.DEFAULT,
		InputBindingsTypes.InputActionType.PRESSED, 0)

	var executed := _service.trigger_bindings(ACTION)

	assert_true(executed)
	assert_eq(high.execute_count, 0)
	assert_eq(low.execute_count, 1)


func test_triggers_bindings_when_layer_signal_is_emitted() -> void:
	var binding := _make_binding()

	_ui_layers.ui_layer_input_triggered.emit(
		ACTION, UiLayersTypes.UiLayer.DEFAULT, InputBindingsTypes.InputActionType.PRESSED
	)

	assert_eq(binding.execute_count, 1)
