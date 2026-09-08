@abstract
class_name CapInputBindingsRegistry
extends GdlrCapability


const InputBindingsTypes = preload("../types.gd")


## Registers an input binding with a corresponding action.[br]
## [br]
## [param action] - Godot's Input Action, must be declared in the Project Settings.[br]
## [param binding] - The binding for this input action.
@abstract func register_binding(action: StringName, binding: InputBindingsTypes.InputBinding) -> void
## Unregisters an input binding for a certain action.
@abstract func unregister_binding(action: StringName, binding: InputBindingsTypes.InputBinding) -> void
## Returns the registered input bindings for [param action].
@abstract func get_bindings(action: StringName) -> Array[InputBindingsTypes.InputBinding]
## Returns the list of registered actions.
@abstract func get_actions() -> Array[StringName]
