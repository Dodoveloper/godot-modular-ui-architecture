## Test double for [code]InputBindingsTypes.InputBinding[/code].
## Records how many times it executed and lets each test decide whether it should run.
extends "res://addons/modular_ui_architecture/modules/input_bindings/types.gd".InputBinding

var execute_count := 0
var should_execute_result := true


func _execute() -> void:
	execute_count += 1


func _should_execute() -> bool:
	return should_execute_result
