@tool
extends ToggleableDisplay


const InputManager = preload("res://demo/shared/classes/input_manager.gd")


func _on_block_inputs() -> void:
	InputManager.block()


func _on_unblock_inputs() -> void:
	InputManager.unblock()
