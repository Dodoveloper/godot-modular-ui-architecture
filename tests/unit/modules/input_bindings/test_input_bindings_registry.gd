extends GutTest
## Unit tests for [code]InputBindingsRegistry[/code].


const InputBindingsTypes = preload("res://addons/modular_ui_architecture/modules/input_bindings/types.gd")
const InputBindingsRegistry = preload("res://addons/modular_ui_architecture/modules/input_bindings/registries/input_bindings.reg.gd")
const FakeBinding = preload("res://tests/fixtures/input_bindings/fake_binding.gd")

const ACTION := &"toggle_test"

var _registry: InputBindingsRegistry


func before_each() -> void:
	_registry = InputBindingsRegistry.new()


func _make_binding(priority: int) -> FakeBinding:
	var binding := FakeBinding.new()
	binding.priority = priority
	return binding


func test_get_bindings_is_empty_for_unknown_action() -> void:
	assert_true(_registry.get_bindings(ACTION).is_empty())


func test_register_binding_is_returned_by_get_bindings() -> void:
	var binding := _make_binding(0)

	_registry.register_binding(ACTION, binding)

	assert_eq(_registry.get_bindings(ACTION), [binding])


func test_bindings_are_ordered_by_descending_priority() -> void:
	var low := _make_binding(0)
	var high := _make_binding(10)
	var mid := _make_binding(5)

	_registry.register_binding(ACTION, low)
	_registry.register_binding(ACTION, high)
	_registry.register_binding(ACTION, mid)

	assert_eq(_registry.get_bindings(ACTION), [high, mid, low])


func test_equal_priority_keeps_registration_order() -> void:
	var first := _make_binding(3)
	var second := _make_binding(3)
	var third := _make_binding(3)

	_registry.register_binding(ACTION, first)
	_registry.register_binding(ACTION, second)
	_registry.register_binding(ACTION, third)

	assert_eq(_registry.get_bindings(ACTION), [first, second, third])


func test_unregister_binding_removes_only_that_binding() -> void:
	var keep := _make_binding(0)
	var remove := _make_binding(1)
	_registry.register_binding(ACTION, keep)
	_registry.register_binding(ACTION, remove)

	_registry.unregister_binding(ACTION, remove)

	assert_eq(_registry.get_bindings(ACTION), [keep])


func test_get_actions_lists_registered_actions() -> void:
	_registry.register_binding(ACTION, _make_binding(0))
	_registry.register_binding(&"other_action", _make_binding(0))

	var actions := _registry.get_actions()

	assert_eq(actions.size(), 2)
	assert_has(actions, ACTION)
	assert_has(actions, &"other_action")
