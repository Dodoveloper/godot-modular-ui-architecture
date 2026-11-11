extends GutTest
## Unit tests for [code]UiLayersRegistry[/code]: registration rules, sorting, and sealing.


const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const UiLayersRegistry = preload("res://addons/modular_ui_architecture/modules/ui_layers/registries/ui_layers.reg.gd")
const DefaultUiLayerNode = preload("res://addons/modular_ui_architecture/modules/ui_layers/nodes/default_ui_layer.gd")
const UiLayerNodeScript = preload("res://addons/modular_ui_architecture/modules/ui_layers/nodes/_base/ui_layer.gd")
const FakeBaseScript = preload("res://tests/fixtures/scripts/base_script.gd")

const TOKEN := &"my_layer"

var _registry: UiLayersRegistry


func before_each() -> void:
	_registry = UiLayersRegistry.new()


func _make(token: StringName, order: int, script: GDScript = UiLayerNodeScript) -> UiLayersTypes.UiLayerRegistration:
	return UiLayersTypes.UiLayerRegistration.new(token, script, order)


func test_register_layer_adds_it_to_registrations() -> void:
	_registry.register_layer(_make(TOKEN, 50))

	var registrations := _registry.get_layer_registrations()

	assert_eq(registrations.size(), 1)
	assert_eq(registrations[0].token, TOKEN)


func test_register_layer_rejects_empty_token() -> void:
	_registry.register_layer(_make(&"", 50))

	assert_true(_registry.get_layer_registrations().is_empty())
	assert_push_error("UI layer token cannot be empty")


func test_register_layer_rejects_duplicate_token() -> void:
	_registry.register_layer(_make(TOKEN, 50))

	_registry.register_layer(_make(TOKEN, 60))

	assert_eq(_registry.get_layer_registrations().size(), 1)
	assert_push_error("UI layer '%s' is already registered" % TOKEN)


func test_register_layer_rejects_script_that_is_not_a_layer_node() -> void:
	_registry.register_layer(_make(TOKEN, 50, FakeBaseScript))

	assert_true(_registry.get_layer_registrations().is_empty())
	assert_push_error("must use a script that extends UiLayerNode")


func test_register_layer_accepts_a_script_extending_ui_layer_node() -> void:
	_registry.register_layer(_make(TOKEN, 50, DefaultUiLayerNode))

	assert_eq(_registry.get_layer_registrations().size(), 1)


func test_register_layer_rejects_order_already_used_by_another_layer() -> void:
	_registry.register_layer(_make(&"first", 50))

	_registry.register_layer(_make(&"second", 50))

	assert_eq(_registry.get_layer_registrations().size(), 1)
	assert_push_error("it is already used by 'first'")


func test_get_layer_registrations_sorts_by_ascending_order() -> void:
	_registry.register_layer(_make(&"high", 300))
	_registry.register_layer(_make(&"low", 10))
	_registry.register_layer(_make(&"middle", 150))

	var tokens: Array[StringName] = []
	for registration in _registry.get_layer_registrations():
		tokens.append(registration.token)

	assert_eq(tokens, [&"low", &"middle", &"high"])


func test_layer_can_be_registered_between_two_predefined_anchors() -> void:
	_registry.register_layer(_make(&"popup", UiLayersTypes.Order.POPUP))
	_registry.register_layer(_make(&"between", (UiLayersTypes.Order.POPUP + UiLayersTypes.Order.TOOLTIP) / 2))
	_registry.register_layer(_make(&"tooltip", UiLayersTypes.Order.TOOLTIP))

	var tokens: Array[StringName] = []
	for registration in _registry.get_layer_registrations():
		tokens.append(registration.token)

	assert_eq(tokens, [&"popup", &"between", &"tooltip"])


func test_register_layer_after_seal_pushes_error_and_is_ignored() -> void:
	_registry.seal()

	_registry.register_layer(_make(TOKEN, 50))

	assert_true(_registry.get_layer_registrations().is_empty())
	assert_push_error("can't be registered after the layers are created")
