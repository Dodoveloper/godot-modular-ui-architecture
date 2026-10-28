extends GutTest
## Unit tests for the InputBindingsTypes.InputBinding base: constructor defaults, stored arguments,
## and the execute()/should_execute() delegation to the abstract virtuals.


const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const InputBindingsTypes = preload("res://addons/modular_ui_architecture/modules/input_bindings/types.gd")


func test_defaults_are_default_layer_pressed_and_zero_priority() -> void:
	var binding := RecordingBinding.new()

	assert_eq(binding.layer, UiLayersTypes.UiLayer.DEFAULT)
	assert_eq(binding.input_type, InputBindingsTypes.InputActionType.PRESSED)
	assert_eq(binding.priority, 0)


func test_constructor_arguments_are_stored() -> void:
	var binding := RecordingBinding.new(
		UiLayersTypes.UiLayer.HUD, InputBindingsTypes.InputActionType.RELEASED
	)

	assert_eq(binding.layer, UiLayersTypes.UiLayer.HUD)
	assert_eq(binding.input_type, InputBindingsTypes.InputActionType.RELEASED)


func test_execute_delegates_to_execute_virtual() -> void:
	var binding := RecordingBinding.new()

	binding.execute()

	assert_eq(binding.executed, 1)


func test_should_execute_delegates_to_should_execute_virtual() -> void:
	var binding := RecordingBinding.new()

	var result := binding.should_execute()

	assert_true(result)
	assert_eq(binding.checked, 1)



## Concrete subclass of the abstract base, recording which virtuals ran.
class RecordingBinding extends InputBindingsTypes.InputBinding:
	var executed := 0
	var checked := 0

	func _init(layer_ := UiLayersTypes.UiLayer.DEFAULT, input_type_ := InputBindingsTypes.InputActionType.PRESSED) -> void:
		super(layer_, input_type_)

	func _execute() -> void:
		executed += 1

	func _should_execute() -> bool:
		checked += 1
		return true
