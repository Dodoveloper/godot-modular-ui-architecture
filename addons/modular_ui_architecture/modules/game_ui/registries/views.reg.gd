extends CapViewsRegistry


var _views: Dictionary[StringName, GameUiTypes.ViewRegistration] = {}


func register_view(view_registration: GameUiTypes.ViewRegistration) -> void:
	_views[view_registration.token] = view_registration


func unregister_view(token: StringName) -> void:
	_views.erase(token)


func get_view_registration(token: StringName) -> GameUiTypes.ViewRegistration:
	return _views.get(token, null)
