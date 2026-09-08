@abstract
class_name CapViewsRegistry
extends GdlrCapability


const GameUiTypes = preload("../types.gd")


@abstract func register_view(view_registration: GameUiTypes.ViewRegistration) -> void
@abstract func unregister_view(token: StringName) -> void
@abstract func get_view_registration(token: StringName) -> GameUiTypes.ViewRegistration
