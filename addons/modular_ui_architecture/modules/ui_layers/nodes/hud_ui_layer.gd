#extends UiLayerNode
#
#
#var _current_hud: Hud
#
#
#func _mount_node(node: Node, data: Dictionary[StringName, Variant] = {}) -> Node:
	#if is_instance_valid(_current_hud):
		#_unmount_node(_current_hud)
	#
	#_current_hud = super(node, data)
	#
	#return _current_hud
#
#
#func _can_mount_scene(Scene: PackedScene) -> bool:
	#return ScUtils.is_scene_of_type(Scene, Hud)
