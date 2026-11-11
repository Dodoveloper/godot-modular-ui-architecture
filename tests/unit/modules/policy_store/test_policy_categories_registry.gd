extends GutTest
## Unit tests for [code]PolicyCategoriesRegistry[/code].


const PolicyCategoriesRegistry = preload("res://addons/modular_ui_architecture/modules/policy_store/registries/policy_categories.reg.gd")

const CATEGORY := &"open_shop"

var _registry: PolicyCategoriesRegistry


func before_each() -> void:
	_registry = PolicyCategoriesRegistry.new()


func test_is_category_registered_is_false_by_default() -> void:
	assert_false(_registry.is_category_registered(CATEGORY))


func test_register_category_makes_it_registered() -> void:
	_registry.register_category(CATEGORY)

	assert_true(_registry.is_category_registered(CATEGORY))


func test_register_category_does_not_register_other_categories() -> void:
	_registry.register_category(CATEGORY)

	assert_false(_registry.is_category_registered(&"open_inventory"))


func test_register_duplicate_category_pushes_error() -> void:
	_registry.register_category(CATEGORY)

	_registry.register_category(CATEGORY)

	assert_push_error("Policy category 'open_shop' is already registered")
	assert_true(_registry.is_category_registered(CATEGORY))


func test_register_empty_category_pushes_error_and_does_not_register() -> void:
	_registry.register_category(&"")

	assert_push_error("Policy category cannot be empty")
	assert_false(_registry.is_category_registered(&""))


func test_unregister_category_removes_registration() -> void:
	_registry.register_category(CATEGORY)

	_registry.unregister_category(CATEGORY)

	assert_false(_registry.is_category_registered(CATEGORY))


func test_unregister_unknown_category_pushes_error() -> void:
	_registry.unregister_category(CATEGORY)

	assert_push_error("No policy category registered for 'open_shop'")
	assert_false(_registry.is_category_registered(CATEGORY))


func test_category_can_be_registered_again_after_unregister() -> void:
	_registry.register_category(CATEGORY)
	_registry.unregister_category(CATEGORY)

	_registry.register_category(CATEGORY)

	assert_true(_registry.is_category_registered(CATEGORY))
