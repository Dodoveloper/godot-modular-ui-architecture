extends CapUiLayersRegistry


const Utils = preload("../../../shared/classes/utils.gd")
const UiLayerNodeScript = preload("../nodes/_base/ui_layer.gd")

var _registrations: Dictionary[StringName, UiLayersTypes.UiLayerRegistration] = {}
var _is_sealed := false


func register_layer(registration: UiLayersTypes.UiLayerRegistration) -> void:
	if _is_sealed:
		push_error("UI layer '%s' can't be registered after the layers are created" % registration.token)
		return
	if registration.token.is_empty():
		push_error("UI layer token cannot be empty")
		return
	if _registrations.has(registration.token):
		push_error("UI layer '%s' is already registered" % registration.token)
		return
	if not Utils.static_is_type(registration.node_script, UiLayerNodeScript):
		push_error("UI layer '%s' must use a script that extends UiLayerNode" % registration.token)
		return
	for other: UiLayersTypes.UiLayerRegistration in _registrations.values():
		if other.order == registration.order:
			push_error(
"UI layer '%s' can't use order %s, it is already used by '%s'"
% [registration.token, registration.order, other.token]
)
			return
	
	_registrations[registration.token] = registration


func get_layer_registrations() -> Array[UiLayersTypes.UiLayerRegistration]:
	var registrations: Array[UiLayersTypes.UiLayerRegistration] = []
	registrations.assign(_registrations.values())
	registrations.sort_custom(func(a, b): return a.order < b.order)
	return registrations


func seal() -> void:
	_is_sealed = true
