@abstract
class_name CapInputBindings
extends GdlrCapability


const UiLayersTypes = preload("../../ui_layers/types.gd")
const InputBindingsTypes = preload("../../input_bindings/types.gd")


@abstract func enable() -> void
@abstract func disable() -> void
## Executes the first applicable binding for the given action, layer, and input type.[br]
## Bindings are retrieved in priority order (highest first), with registration order as the
## stable tiebreaker within equal-priority groups. The first binding whose
## [method InputBinding.should_execute] returns [code]true[/code] is executed, and the input
## is marked as handled. Subsequent bindings are not evaluated (first-wins semantics).[br]
## [br]
## [param action] - The Input Action, it must be declared in the Project Settings.[br]
## [param layer] - The UI Layer on which the binding should be triggered.[br]
## [param input_type] - The type of input (pressed, released).[br]
## Returns [code]true[/code] if a binding was executed, [code]false[/code] otherwise.
@abstract func trigger_bindings(
	action: StringName, layer := UiLayersTypes.UiLayer.DEFAULT,
	input_type := InputBindingsTypes.InputActionType.PRESSED
) -> bool
