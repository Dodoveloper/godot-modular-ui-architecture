extends CapGameUi


const AttachmentSlotsController = preload("../../../shared/classes/attachment_slots_controller.gd")
const WindowUiLayerNode = preload("../../ui_layers/nodes/window_ui_layer.gd")

const VIEW_CONTEXT_PROP_NAME := &"context"
## Squared threshold for detecting teleports/corrections in world-anchored UI.
## If an anchor moves more than sqrt(this) distance in a single physics tick, it's treated as a teleport
## and interpolation is reset (prev = curr = new) to avoid gliding from old to new position.
## Heuristic: must be larger than max legitimate single-tick movement (~10px for typical gameplay)
## and smaller than typical teleport distance. Using squared distance to avoid [code]sqrt[/code] cost.
const TELEPORT_RESET_DISTANCE_SQ := 10000.0


var _reg_views: CapViewsRegistry
var _reg_attachments: CapUiAttachmentsRegistry
var _svc_ui_layers: CapUiLayers

var _mounted_views_by_token: Dictionary[StringName, Node] = {}
var _uis_by_attachment: Dictionary[GameUiTypes.UiAttachment, Control] = {}
## List of attachments mounted for each View.
## [codeblock]
## @shape: {
##   [view: Node]: [attachments: Array[GameUiTypes.UiAttachment]]
## }
## [/codeblock]
var _attachments_by_view: Dictionary[Node, Array] = {}
## Cached context values per View.[br]
## [codeblock]
## @shape: {
##   [view: Node]: [context_values: {
##     [property_name: String]: [property_value: Variant]
##   }
## }
## [/codeblock]
var _cached_context_values: Dictionary[Node, Dictionary] = {}
## Maps world-anchored UI nodes to their [WorldAnchorInfo].
## Position updates run each physics frame.[br]
var _world_anchors: Dictionary[Control, WorldAnchorInfo] = {}


func _init(
	reg_attachments: CapUiAttachmentsRegistry, reg_views: CapViewsRegistry, svc_ui_layers: CapUiLayers
) -> void:
	_reg_attachments = reg_attachments
	_reg_views = reg_views
	_svc_ui_layers = svc_ui_layers


func enable() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	tree.physics_frame.connect(_on_scene_tree_physics_frame)
	tree.process_frame.connect(_on_scene_tree_process_frame)


func disable() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree.physics_frame.is_connected(_on_scene_tree_physics_frame):
		tree.physics_frame.disconnect(_on_scene_tree_physics_frame)
	if tree.process_frame.is_connected(_on_scene_tree_process_frame):
		tree.process_frame.disconnect(_on_scene_tree_process_frame)


# TODO: eventually, Views may override convention methods (e.g. on_open, on_close)
# to implement animations, staying in the tree, or reusing instances.
func mount_view(token: StringName, layer := UiLayersTypes.UiLayer.DEFAULT) -> Node:
	var view_registration := _reg_views.get_view_registration(token)
	if not view_registration:
		push_error("No registered View found for token '%s'" % [token])
		return null
	if get_view(token):
		push_error("There is already a mounted View for token '%s'" % [token])
		return null
	
	var view := mount_ui(view_registration.scene, layer)
	if not view:
		return null
	
	_mounted_views_by_token[token] = view
	_cached_context_values[view] = _extract_property_values(view.get(VIEW_CONTEXT_PROP_NAME))
	view.tree_exiting.connect(_on_view_tree_exiting.bind(token))
	view_mounted.emit(token)
	
	return view


func unmount_view(token: StringName) -> bool:
	var view := get_view(token)
	if not view:
		push_error("No mounted View found for token '%s'" % [token])
		return false
	
	var is_success := unmount_ui(view)
	if is_success:
		_mounted_views_by_token.erase(token)
		_cached_context_values.erase(view)
		_attachments_by_view.erase(view)
	
	return is_success


func is_view_mounted(token: StringName) -> bool:
	return _mounted_views_by_token.has(token)


func get_view(token: StringName) -> Node:
	return _mounted_views_by_token.get(token)


func mount_world_ui(
	ui: Control, anchor: CanvasItem = null, layer := UiLayersTypes.UiLayer.DEFAULT,
	offset := Vector2.ZERO, mirror_anchor_visuals := false
) -> Control:
	var world_ui_container := _svc_ui_layers.get_world_ui_container(layer)
	if not world_ui_container:
		push_error("Failed to get world UI container for layer %s" % layer)
		return null
	
	if ui.get_parent():
		# When anchor is null, the UI owns its own screen-space layout (anchors/offsets).
		# Keeping the global transform would bake the old parent's world position into the offsets
		# and destroy that layout. With anchor present, keep the transform since
		# the position will be overridden every frame from the anchor anyway.
		ui.reparent(world_ui_container, anchor != null)
	else:
		world_ui_container.add_child(ui)
	
	# Seed interpolation buffers from anchor's current position to avoid origin-frame flash.
	var info := WorldAnchorInfo.new(anchor, offset, mirror_anchor_visuals, ui.scale)
	var pos := _get_canvas_item_global_position(anchor)
	info.curr_world_pos = pos
	info.prev_world_pos = pos
	_world_anchors[ui] = info
	
	ui.tree_exiting.connect(_on_world_ui_tree_exiting.bind(ui), CONNECT_ONE_SHOT)
	
	return ui


func unmount_world_ui(ui: Node) -> bool:
	if not _world_anchors.has(ui):
		push_error("UI node '%s' is not tracked as world-anchored" % ui.name)
		return false
	
	_world_anchors.erase(ui)
	ui.queue_free()
	return true


func mount_ui(
	scene_path: String, layer: UiLayersTypes.UiLayer, data: Dictionary[StringName, Variant] = {}
) -> Node:
	var layer_node := _svc_ui_layers.get_layer_node(layer)
	return layer_node.mount_node(scene_path, data)


func unmount_ui(ui: Node) -> bool:
	var layer_node: UiLayerNode
	for layer in _svc_ui_layers.get_layers():
		var _layer_node := _svc_ui_layers.get_layer_node(layer)
		if _layer_node.get_mounted_nodes().has(ui):
			layer_node = _layer_node
			break
	
	if not layer_node:
		push_error("UI node '%s' not found in any layer" % [ui.name])
		return false
	
	return layer_node.unmount_node(ui)


func mount_attachments(view: Node, slots_controller: AttachmentSlotsController) -> void:
	var context: RefCounted = view.get(VIEW_CONTEXT_PROP_NAME)
	for attachment in _reg_attachments.get_attachments():
		if not attachment.should_mount(view, context):
			continue
		
		var ui := attachment.build(view, context)
		slots_controller.add_to_slot(attachment.get_slot_tag(), ui, attachment.get_priority())
		
		if ui.is_inside_tree():
			_uis_by_attachment[attachment] = ui
			(
				_attachments_by_view
				.get_or_add(view, [] as Array[GameUiTypes.UiAttachment])
				.append(attachment)
			)
			ui.tree_exiting.connect(_on_attachment_ui_tree_exiting.bind(attachment))


func unmount_attachment(attachment: GameUiTypes.UiAttachment) -> void:
	var ui := _get_mounted_attachment(attachment)
	if not ui:
		return
	
	ui.queue_free()


func _poll_view_context(view: Node) -> void:
	var context: RefCounted = view.get(VIEW_CONTEXT_PROP_NAME)
	if not context:
		return
	
	var prev_context_values: Dictionary[String, Variant] = _cached_context_values.get(view, {})
	var new_context_values := _extract_property_values(context)
	if prev_context_values != new_context_values:
		_notify_attachments(view, context)
		_cached_context_values[view] = new_context_values


func _extract_property_values(context: RefCounted) -> Dictionary[String, Variant]:
	var values: Dictionary[String, Variant] = {}
	if not context:
		return values
	
	var property_list := context.get_property_list()
	for property in property_list.filter(
		func(_property: Dictionary): return _property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE
	):
		var property_name: String = property.name
		values[property_name] = context.get(property_name)
	
	return values


## Notifies mounted attachments that their View's context has changed.
func _notify_attachments(view: Node, new_context: RefCounted) -> void:
	var attachments: Array[GameUiTypes.UiAttachment] = (
		_attachments_by_view.get(view, [] as Array[GameUiTypes.UiAttachment])
	)
	for attachment in attachments:
		attachment.notify_context_changed(new_context)


func _get_mounted_attachment(attachment: GameUiTypes.UiAttachment) -> Control:
	return _uis_by_attachment.get(attachment, null)


func _get_canvas_item_global_position(node: CanvasItem) -> Vector2:
	if not is_instance_valid(node):
		return Vector2.ZERO
	
	if node is Node2D:
		return (node as Node2D).global_position
	return (node as Control).global_position


func _update_world_anchor(ui: Control, info: WorldAnchorInfo) -> void:
	if not info.is_anchor_valid():
		return
	
	# Reconstruct Godot's 2D physics interpolation: lerp between the previous and current
	# physics-tick positions using the render-frame interpolation fraction.
	# This ensures the nameplate rides the character sprite pixel-perfectly at any refresh rate.
	var f := Engine.get_physics_interpolation_fraction()
	var world_pos := info.prev_world_pos.lerp(info.curr_world_pos, f)
	ui.global_position = info.anchor.get_canvas_transform() * world_pos + info.offset
	
	if info.mirror_anchor_visuals:
		_mirror_anchor_visuals(ui, info)


## Mirrors the anchor's [code]visible[/code], [code]modulate[/code], and [code]scale[/code] onto
## [param ui], so a scene that authors visibility/animation on the anchor (e.g. via toggle
## actions or an [AnimationPlayer]) keeps affecting [param ui] even though it's no longer a
## descendant of the anchor after being reparented into the world UI layer.
func _mirror_anchor_visuals(ui: Control, info: WorldAnchorInfo) -> void:
	var anchor := info.anchor
	ui.visible = anchor.visible
	ui.modulate = anchor.modulate
	ui.scale = info.base_scale * anchor.scale


func _on_scene_tree_physics_frame() -> void:
	for view in _mounted_views_by_token.values():
		_poll_view_context(view)
	
	# Capture anchor positions at physics-tick rate for interpolation.
	for ui: Control in _world_anchors.keys():
		var info := _world_anchors[ui]
		if info.is_anchor_valid():
			var new_pos := _get_canvas_item_global_position(info.anchor)
			# If delta is too large, it's a teleport, so snap.
			if info.curr_world_pos.distance_squared_to(new_pos) > TELEPORT_RESET_DISTANCE_SQ:
				info.prev_world_pos = new_pos
			else:
				info.prev_world_pos = info.curr_world_pos
			info.curr_world_pos = new_pos


func _on_scene_tree_process_frame() -> void:
	# Detect and clean up stale anchors (anchors freed externally without unmounting the UI).
	# NOTE: at pathological scale (thousands of world-anchored UIs), this loop
	# could become a profiling target.
	var stale: Array[Control] = []
	for ui: Control in _world_anchors.keys():
		var info := _world_anchors[ui]
		if info.is_anchor_stale():
			stale.append(ui)
		else:
			_update_world_anchor(ui, info)
	for ui in stale:
		push_warning("World anchor for '%s' was freed externally; unmounting." % ui.name)
		unmount_world_ui(ui)


func _on_world_ui_tree_exiting(ui: Control) -> void:
	_world_anchors.erase(ui)


func _on_attachment_ui_tree_exiting(attachment: GameUiTypes.UiAttachment) -> void:
	_uis_by_attachment.erase(attachment)
	for view in _attachments_by_view.keys():
		var attachments := _attachments_by_view[view]
		if attachments.has(attachment):
			attachments.erase(attachment)


func _on_view_tree_exiting(token: StringName) -> void:
	var view := get_view(token)
	_mounted_views_by_token.erase(token)
	_cached_context_values.erase(view)
	_attachments_by_view.erase(view)


class WorldAnchorInfo:
	var anchor: CanvasItem
	var offset: Vector2
	## Previous physics-tick world position of the anchor (for interpolation).
	var prev_world_pos: Vector2
	## Current physics-tick world position of the anchor (for interpolation).
	var curr_world_pos: Vector2
	## Whether to mirror [member anchor]'s [code]visible[/code], [code]modulate[/code], and
	## [code]scale[/code] onto the mounted UI every frame.
	var mirror_anchor_visuals: bool
	## The mounted UI's own authored scale at mount time, used as a baseline that
	## [member anchor]'s scale is multiplied onto (so mirroring doesn't clobber it).
	var base_scale: Vector2
	
	
	func _init(
		anchor_: CanvasItem, offset_: Vector2, mirror_anchor_visuals_: bool = false,
		base_scale_: Vector2 = Vector2.ONE
	) -> void:
		anchor = anchor_
		offset = offset_
		prev_world_pos = Vector2.ZERO
		curr_world_pos = Vector2.ZERO
		mirror_anchor_visuals = mirror_anchor_visuals_
		base_scale = base_scale_
	
	
	## Returns [code]true[/code] if the anchor is set and still alive.
	func is_anchor_valid() -> bool:
		return anchor != null and is_instance_valid(anchor)
	
	
	## Returns [code]true[/code] if the anchor was set at mount time but has since been freed.
	## A deliberately [code]null[/code] anchor is not considered stale.
	func is_anchor_stale() -> bool:
		return anchor != null and not is_instance_valid(anchor)
