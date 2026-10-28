extends CapViewsRegistry


var _views: Dictionary[StringName, GameUiTypes.ViewRegistration] = {}


func register_view(view_registration: GameUiTypes.ViewRegistration) -> void:
	_views[view_registration.token] = view_registration


func unregister_view(token: StringName) -> void:
	if not _views.has(token):
		push_error("No view registered for token '%s'" % token)
		return
	
	_views.erase(token)


func get_view_registration(token: StringName) -> GameUiTypes.ViewRegistration:
	return _views.get(token, null)
