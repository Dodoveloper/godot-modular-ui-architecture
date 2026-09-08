const UiLayersTypes = preload("../ui_layers/types.gd")

enum InputActionType {
	PRESSED,
	RELEASED,
}


## Base input binding, represents an action scoped to a specific [enum UiLayer].
@abstract class InputBinding extends RefCounted:
	var layer: UiLayersTypes.UiLayer
	var input_type: InputActionType
	## Execution priority relative to other bindings on the same action and layer.
	## Higher values execute first. Bindings with equal priority run in registration order (stable).
	var priority: int = 0
	
	
	func _init(
		layer_ := UiLayersTypes.UiLayer.DEFAULT, input_type_ := InputActionType.PRESSED
	) -> void:
		layer = layer_
		input_type = input_type_
	
	
	@abstract func _execute() -> void
	@abstract func _should_execute() -> bool
	
	
	func execute() -> void:
		_execute()
	
	
	func should_execute() -> bool:
		return _should_execute()
