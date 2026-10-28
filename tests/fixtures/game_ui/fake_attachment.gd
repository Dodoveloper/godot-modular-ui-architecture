## Test double for [code]GameUiTypes.UiAttachment[/code].
## Records lifecycle hook calls so tests can assert on them.
extends "res://addons/modular_ui_architecture/modules/game_ui/types.gd".UiAttachment

var built_count := 0
var exited_count := 0
var should_mount_result := true
var last_context: RefCounted


func _init(slot_tag: StringName, Scene: PackedScene = null) -> void:
	super(slot_tag, Scene)


func _on_instance_built() -> void:
	built_count += 1


func _on_instance_tree_exiting() -> void:
	exited_count += 1


func _on_context_changed(new_context: RefCounted) -> void:
	last_context = new_context


func _should_mount(_host_ui: Node, _context: RefCounted) -> bool:
	return should_mount_result
