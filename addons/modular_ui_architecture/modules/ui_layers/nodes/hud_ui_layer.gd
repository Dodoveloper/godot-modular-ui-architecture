extends UiLayerNode


func _can_mount_scene(_Scene: PackedScene) -> bool:
	return get_mounted_nodes().is_empty()
