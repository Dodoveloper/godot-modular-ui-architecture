extends UiLayerNode


const PopupTypes = preload("../../popups/types.gd")
const Utils = preload("../../../shared/classes/utils.gd")

const BEGIN_CLOSE_TRANSITION_METHOD := &"begin_close_transition"
const CLOSE_TRANSITION_FINISHED_SIGNAL := &"close_transition_finished"
const CLOSE_REQUESTED_SIGNAL := &"close_requested"
const CLOSE_TRANSITION_TIMEOUT_SEC := 5.0

## Maps currently-open popups to their correspoding info. Entries are inserted and removed in a 
## stack-like manner, ensuring the last entry is the currently-focused popup (topmost).
var _popups: Dictionary[Control, PopupInfo] = {}

## Pending popup requests submitted via [method enqueue_popup]. Requests are
## processed in FIFO order: the next entry opens only after the active queued
## popup is removed from the tree.
var _popup_queue: Array[QueuedPopupRequest] = []
## The queued popup currently being displayed, if any.
var _active_queued_popup: Control = null


func _mount_node(node: Node, data: Dictionary[StringName, Variant] = {}) -> Node:
	if _popups.has(node):
		push_error("Trying to mount an already-mounted node")
		return null
	
	# Validate close transition contract — both sides must be present
	var node_has_method := node.has_method(BEGIN_CLOSE_TRANSITION_METHOD)
	var node_has_signal := node.has_signal(CLOSE_TRANSITION_FINISHED_SIGNAL)
	if node_has_method != node_has_signal:
		push_warning(
			("Popup '%s' partially implements the close transition API: "
			+ "has_method=%s has_signal=%s. The transition will be skipped.")
			% [node.name, node_has_method, node_has_signal]
		)
	
	# Extract popup-specific data
	var parent: Control = data.get(&"parent", null)
	var position: Vector2 = data.get(&"position", Vector2.ZERO)
	var is_blocking: bool = data.get(&"is_blocking", false)
	var color: Color = data.get(&"color", Color(0, 0, 0, 0))
	var dismiss_on_click_outside: bool = data.get(&"dismiss_on_click_outside", true)

	# Create background
	var background := ColorRect.new()
	background.name = &"Background" + node.name
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = color

	# Track popup
	var info := PopupInfo.new(node, background, parent, is_blocking)
	info.dismiss_on_click_outside = dismiss_on_click_outside
	_popups[node as Control] = info
	
	# Handle hierarchy
	if parent:
		if not _popups.has(parent):
			push_warning("Trying to register a popup, but parent argument is not a registered one, ignoring it")
		else:
			_popups[parent].children.append(node)
	
	# Mount (deferred, because this node may be busy setting up children at this time)
	add_child.call_deferred(background)
	background.gui_input.connect(_on_background_gui_input.bind(node))
	_register_popup_close_requested_listener(node as Control)
	if position != Vector2.ZERO:
		node.position = position
	background.add_child(node)
	
	return node


func _unmount_node(node: Node) -> bool:
	return _request_close_popup(node as Control)


func _can_mount_scene(Scene: PackedScene) -> bool:
	return Utils.is_scene_of_native_type(Scene, &"Control")


func _get_mounted_nodes() -> Array[Node]:
	var nodes: Array[Node] = []
	nodes.assign(_popups.keys())
	return nodes


func has_popups() -> bool:
	return not _popups.is_empty()


# NOTE: descendant popups in the same subtree are force-closed immediately
# when their ancestor finalizes closure.
func _request_close_popup(popup: Control, reason := PopupTypes.CloseReason.SERVICE) -> bool:
	if not _can_close_popup(popup):
		return false
	
	var popup_info := _popups[popup]
	if popup_info.is_closing:
		return false
	
	# Perform some operations before closing, if the popup scene supports it
	if (
		popup.has_method(BEGIN_CLOSE_TRANSITION_METHOD)
		and popup.has_signal(CLOSE_TRANSITION_FINISHED_SIGNAL)
	):
		popup_info.is_closing = true
		popup.connect(
			CLOSE_TRANSITION_FINISHED_SIGNAL,
			_on_popup_close_transition_finished.bind(popup),
			CONNECT_ONE_SHOT
		)
		popup.call(BEGIN_CLOSE_TRANSITION_METHOD, reason)
		
		# Safety net: force-close if the popup never emits the signal
		var timer := get_tree().create_timer(CLOSE_TRANSITION_TIMEOUT_SEC)
		var popup_id := popup.get_instance_id()
		timer.timeout.connect(func():
			var p := instance_from_id(popup_id) as Control
			if not is_instance_valid(p):
				return
			
			_on_close_transition_timeout(p)
		, CONNECT_ONE_SHOT)
		return true
	
	_close_popup_recursive(popup)
	return true


func close_topmost_popup(reason := PopupTypes.CloseReason.SERVICE) -> void:
	if _popups.is_empty():
		push_error("There are no popups to be closed")
		return
	
	var popup: Control = _popups.keys()[-1]
	_request_close_popup(popup, reason)


## Enqueues a popup to be shown after all currently-queued ones.
## If no queued popup is currently open, it opens it immediately.
func enqueue_popup(
	scene_path: String, color: Color, setup: Callable, dismiss_on_click_outside := false
) -> void:
	if _active_queued_popup:
		_popup_queue.append(QueuedPopupRequest.new(scene_path, color, setup, dismiss_on_click_outside))
		return
	
	_open_queued_popup(scene_path, color, setup, dismiss_on_click_outside)


func _open_queued_popup(
	scene_path: String, color: Color, setup: Callable, dismiss_on_click_outside := false
) -> void:
	var popup_data: Dictionary[StringName, Variant] = {
		&"is_blocking": true,
		&"color": color,
		&"dismiss_on_click_outside": dismiss_on_click_outside,
	}
	var popup := mount_node(scene_path, popup_data) as Control
	if not popup:
		_advance_queue()
		return
	
	_active_queued_popup = popup
	if setup.is_valid():
		setup.call(popup)
	popup.tree_exiting.connect(_on_queued_popup_tree_exiting.bind(popup), CONNECT_ONE_SHOT)


func _advance_queue() -> void:
	if _active_queued_popup:
		return
	if _popup_queue.is_empty():
		return
	
	var next: QueuedPopupRequest = _popup_queue.pop_front()
	_open_queued_popup(next.scene_path, next.color, next.setup, next.dismiss_on_click_outside)


func _can_close_popup(popup: Control) -> bool:
	if not _popups.has(popup):
		return false
	if _popups[popup].is_closing:
		return false
	if popup.has_method(&"can_close_popup") and not popup.call(&"can_close_popup"):
		return false
	
	for child in _popups[popup].children:
		if _popups[child].is_blocking:
			return false
		if not _can_close_popup(child):
			return false
	
	return true


func _is_left_click_pressed(event: InputEvent) -> bool:
	return (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
	)


func _close_popup_recursive(popup: Control) -> void:
	if not _popups.has(popup):
		return
	
	var popup_info := _popups[popup]
	popup_info.is_closing = false
	for child in popup_info.children.duplicate():
		_close_popup_recursive(child)
	
	_popups.erase(popup)
	for info in _popups.values().filter(
		func(_info: PopupInfo): return _info.children.has(popup)
	):
		info.children.erase(popup)
	
	popup_info.background.queue_free()


func _register_popup_close_requested_listener(popup: Control) -> void:
	if not popup.has_signal(CLOSE_REQUESTED_SIGNAL):
		return
	
	popup.close_requested.connect(_on_popup_close_requested.bind(popup))


func _on_close_transition_timeout(popup: Control) -> void:
	if not _popups.has(popup):
		# Already closed cleanly — timeout fired but we don't care
		return
	
	push_warning("Popup '%s' close transition timed out, force-closing." % popup.name)
	_close_popup_recursive(popup)


func _on_popup_close_transition_finished(popup: Control) -> void:
	_close_popup_recursive(popup)


func _on_queued_popup_tree_exiting(popup: Control) -> void:
	if popup != _active_queued_popup:
		return
	
	_active_queued_popup = null
	_advance_queue()


# NOTE: this handles mouse clicks outside the topmost popup's rect.
func _on_background_gui_input(event: InputEvent, popup: Control) -> void:
	if _is_left_click_pressed(event):
		var info: PopupInfo = _popups.get(popup)
		if info != null and not info.dismiss_on_click_outside:
			return
		_request_close_popup(popup, PopupTypes.CloseReason.BACKGROUND_CLICK)


func _on_popup_close_requested(popup: Control) -> void:
	_request_close_popup(popup, PopupTypes.CloseReason.POPUP)


class PopupInfo:
	var node: Control
	var background: Control
	var parent: Control
	var children: Array[Control] = []
	var is_blocking := false
	var is_closing := false
	var dismiss_on_click_outside := true


	func _init(node_: Control, background_: Control, parent_: Control, is_blocking_: bool) -> void:
		node = node_
		background = background_
		parent = parent_
		is_blocking = is_blocking_


class QueuedPopupRequest:
	var scene_path: String
	var color: Color
	var setup: Callable
	var dismiss_on_click_outside: bool
	
	func _init(
		scene_path_: String, color_: Color, setup_: Callable, dismiss_on_click_outside_ := false
	) -> void:
		scene_path = scene_path_
		color = color_
		setup = setup_
		dismiss_on_click_outside = dismiss_on_click_outside_
