class_name UiLayerNode
extends CanvasLayer


const UiLayersTypes = preload("../../types.gd")
const InputBindingsTypes = preload("../../../input_bindings/types.gd")
const SceneCache = preload("../../../../shared/classes/scene_cache.gd")

## Actions Godot's Viewport GUI phase special-cases for keyboard/joypad focus navigation.[br]
## Whenever a [Control] holds keyboard focus, the GUI phase intercepts events matching these
## — by physical key/button, not by action name — and marks them handled [b]before[/b]
## [method Node._unhandled_input] ever runs.[br]
## Any binding sharing a key with one of these (e.g. [i]Tab[/i]) would never reach a normal
## [method Node._unhandled_input] broadcast while something holds focus, so those specific events
## are broadcast a phase earlier, via [method Node._input].[br]
## Every other action keeps using [method Node._unhandled_input], so e.g. typing into a
## focused [LineEdit] is not pre-empted by unrelated bindings.
const _FOCUS_NAV_ACTIONS: Array[StringName] = [
	&"ui_focus_next", &"ui_focus_prev",
	&"ui_up", &"ui_down", &"ui_left", &"ui_right",
]

var ui_layer: UiLayersTypes.UiLayer
var should_block_inputs: bool

## List of input actions, cached for performance reasons.
var _input_actions: Array[StringName]

var _svc_ui_layers: CapUiLayers


func _init(svc_ui_layers: CapUiLayers) -> void:
	_svc_ui_layers = svc_ui_layers


func _ready() -> void:
	_input_actions = InputMap.get_actions()


func _input(event: InputEvent) -> void:
	if not _collides_with_focus_nav(event):
		return
	# Unlike _unhandled_input, nothing here marks the event as handled (that would starve the
	# GUI phase of focus navigation), so layers obstructed by a blocking layer must opt out.
	if _svc_ui_layers.is_layer_input_blocked(ui_layer):
		return
	
	_broadcast_input(event)


func _unhandled_input(event: InputEvent) -> void:
	if should_block_inputs and get_mounted_nodes().size() > 0:
		get_viewport().set_input_as_handled()
	
	_broadcast_input(event)


func _broadcast_input(event: InputEvent) -> void:
	for action in _input_actions:
		if event.is_action_pressed(action):
			_svc_ui_layers.notify_input_triggered(
				action, ui_layer, InputBindingsTypes.InputActionType.PRESSED
			)
		elif event.is_action_released(action):
			_svc_ui_layers.notify_input_triggered(
				action, ui_layer, InputBindingsTypes.InputActionType.RELEASED
			)


func _collides_with_focus_nav(event: InputEvent) -> bool:
	for nav_action in _FOCUS_NAV_ACTIONS:
		if event.is_action(nav_action, true):
			return true
	
	return false


@warning_ignore("unused_parameter")
func _mount_node(node: Node, data: Dictionary[StringName, Variant] = {}) -> Node:
	add_child(node)
	return node


func _unmount_node(node: Node) -> bool:
	if not is_instance_valid(node):
		return false
	
	if node.get_parent() == self:
		remove_child(node)
	node.queue_free()
	
	return true


@warning_ignore("unused_parameter")
func _can_mount_scene(Scene: PackedScene) -> bool:
	return true


func _get_mounted_nodes() -> Array:
	return get_children().filter(func(c: Node):
		return c.name != CapUiLayers.WORLD_UI_CONTAINER_NODE_NAME
	)


## Mounts a node and returns it. It returns [code]null[/code] if it can't be mounted.
func mount_node(scene_path: String, data: Dictionary[StringName, Variant] = {}) -> Node:
	var Scene := SceneCache.load_scene(scene_path)
	if not Scene:
		return null
	if not _can_mount_scene(Scene):
		return null
	
	var node := Scene.instantiate()
	return _mount_node(node, data)


## Unmounts and frees [param node]. Returns [code]false[/code] if the node is already invalid.
func unmount_node(node: Node) -> bool:
	return _unmount_node(node)


## Returns the UI nodes mounted in this layer.[br]
## [b]NOTE[/b]: world-anchored UI nodes are excluded.
## Do not use [method Node.get_children] as a substitute — it includes infrastructure children
## that are not mounted UI.
func get_mounted_nodes() -> Array:
	return _get_mounted_nodes()
