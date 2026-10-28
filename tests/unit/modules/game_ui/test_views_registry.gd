extends GutTest
## Unit tests for [code]ViewsRegistry[/code].


const GameUiTypes = preload("res://addons/modular_ui_architecture/modules/game_ui/types.gd")
const ViewsRegistry = preload("res://addons/modular_ui_architecture/modules/game_ui/registries/views.reg.gd")

const TOKEN := &"inventory"

var _registry: ViewsRegistry


func before_each() -> void:
	_registry = ViewsRegistry.new()


func test_get_view_registration_returns_null_for_unknown_token() -> void:
	assert_null(_registry.get_view_registration(TOKEN))


func test_register_view_is_returned_by_token() -> void:
	var registration := GameUiTypes.ViewRegistration.new(TOKEN, "res://some/view.tscn")

	_registry.register_view(registration)

	assert_eq(_registry.get_view_registration(TOKEN), registration)


func test_register_view_replaces_existing_registration_for_same_token() -> void:
	var first := GameUiTypes.ViewRegistration.new(TOKEN, "res://first.tscn")
	var second := GameUiTypes.ViewRegistration.new(TOKEN, "res://second.tscn")
	_registry.register_view(first)

	_registry.register_view(second)

	assert_eq(_registry.get_view_registration(TOKEN), second)


func test_unregister_view_removes_registration() -> void:
	_registry.register_view(GameUiTypes.ViewRegistration.new(TOKEN, "res://some/view.tscn"))

	_registry.unregister_view(TOKEN)

	assert_null(_registry.get_view_registration(TOKEN))


func test_unregister_unknown_view_pushes_error() -> void:
	_registry.unregister_view(TOKEN)

	assert_push_error("No view registered for token 'inventory'")
	assert_null(_registry.get_view_registration(TOKEN))
