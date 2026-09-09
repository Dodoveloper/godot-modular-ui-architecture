extends UiLayerNode


const Utils = preload("../../../shared/classes/utils.gd")

var _tooltip: Tooltip
var _anchor: Control
var _available_rect: Rect2


func _mount_node(node: Node, data: Dictionary[StringName, Variant] = {}) -> Node:
	unmount_tooltip()
	
	_anchor = data.get(&"anchor")
	if not is_instance_valid(_anchor):
		node.queue_free()
		push_error("Invalid anchor node")
		return null
	# If mouse is outside the anchor's rect, don't mount
	if not _anchor.get_global_rect().has_point(_anchor.get_global_mouse_position()):
		node.queue_free()
		return null
	
	_available_rect = data.get(&"available_rect", get_viewport().get_visible_rect())
	_tooltip = node
	var contents: Dictionary[String, Variant] = (
		data.get(&"contents", {} as Dictionary[String, Variant])
	)
	
	add_child(_tooltip)
	_tooltip.visible = true
	_tooltip.modulate.a = 0.0
	_tooltip.scale = _anchor.get_global_transform().get_scale()
	_tooltip.initialize(contents)
	
	_tooltip.global_position = _anchor.global_position
	_reposition_and_show.call_deferred()
	
	return node


func _unmount_node(node: Node) -> bool:
	if node != _tooltip:
		push_error("Trying to unmount a non-tracked tooltip")
		return false
	
	remove_child(_tooltip)
	_tooltip.queue_free()
	_tooltip = null
	_anchor = null
	return true


func _can_mount_scene(Scene: PackedScene) -> bool:
	return Utils.is_scene_of_type(Scene, Tooltip) and get_mounted_nodes().is_empty()


func unmount_tooltip() -> bool:
	if not is_instance_valid(_tooltip):
		return false
	
	return _unmount_node(_tooltip)


func _reposition_and_show() -> void:
	if not is_instance_valid(_tooltip) or not is_instance_valid(_anchor):
		unmount_tooltip()
		return
	
	# NOTE: we need to wait one extra frame for the tooltip's size to update properly.
	await get_tree().process_frame
	if not is_instance_valid(_tooltip) or not is_instance_valid(_anchor):
		unmount_tooltip()
		return
	
	_reposition()
	_tooltip.modulate.a = 1.0


func _reposition() -> void:
	var anchor_rect := _anchor.get_global_rect()
	var tooltip_size := _tooltip.get_bubble_size()
	var pivot: Vector2
	var h_dir: int
	var v_dir: int
	var axis := _tooltip.get_placement_axis()
	
	if axis == Tooltip.PlacementAxis.HORIZONTAL:
		var can_show_left := anchor_rect.position.x - tooltip_size.x >= _available_rect.position.x
		h_dir = -1 if can_show_left else 1
		v_dir = 0
		pivot = Vector2(
			anchor_rect.position.x if h_dir == -1 else anchor_rect.end.x,
			clampf(
				anchor_rect.get_center().y,
				_available_rect.position.y + tooltip_size.y / 2.0,
				_available_rect.end.y - tooltip_size.y / 2.0
			)
		)
	elif axis == Tooltip.PlacementAxis.VERTICAL:
		var can_show_above := anchor_rect.position.y - tooltip_size.y >= _available_rect.position.y
		h_dir = 0
		v_dir = -1 if can_show_above else 1
		pivot = Vector2(
			clampf(
				anchor_rect.get_center().x,
				_available_rect.position.x + tooltip_size.x / 2.0,
				_available_rect.end.x - tooltip_size.x / 2.0
			),
			anchor_rect.position.y if v_dir == -1 else anchor_rect.end.y
		)
	else:
		var can_show_right := anchor_rect.end.x + tooltip_size.x <= _available_rect.end.x
		var can_show_bottom := anchor_rect.end.y + tooltip_size.y <= _available_rect.end.y
		h_dir = 1 if can_show_right else -1
		v_dir = 1 if can_show_bottom else -1
		pivot = Vector2(
			anchor_rect.end.x if h_dir == 1 else anchor_rect.position.x,
			anchor_rect.end.y if v_dir == 1 else anchor_rect.position.y
		)
	
	_tooltip.set_location_from_policy(h_dir, v_dir)
	_tooltip.global_position = pivot
