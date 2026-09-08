@tool
class_name AttachmentSlotConfig
extends Resource


## Path of the node that represents the slot, elements added to the slot will be added as
## children of this node.
@export_node_path("Control") var node_path: NodePath
## Maximum number of children that can be added to the slot.
@export var max_children := -1
## If [code]true[/code], this slot will maintain true screen centering and constrain its siblings.[br]
## [b]NOTE[/b]: only valid when parent is a [BoxContainer] with exactly 3 registered slots.
@export var protected_center := false


func _init(node_path_: NodePath = ^"", max_children_ := -1) -> void:
	node_path = node_path_
	max_children = max_children_
