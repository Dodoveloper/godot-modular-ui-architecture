class_name UiLayerNode
extends CanvasLayer


const UiLayersTypes = preload("../../types.gd")
const InputBindingsTypes = preload("../../../input_bindings/types.gd")
const SceneCache = preload("../../../../shared/classes/scene_cache.gd")

var ui_layer: UiLayersTypes.UiLayer
var should_block_inputs: bool

## List of input actions, cached for performance reasons.
var _input_actions: Array[StringName]

var _svc_ui_layers: CapUiLayers


func _init(svc_ui_layers: CapUiLayers) -> void:
	_svc_ui_layers = svc_ui_layers


func _ready() -> void:
	_input_actions = InputMap.get_actions()


# NOTE: intentionally _input, not _unhandled_input. Godot's pipeline runs
# Node._input -> Viewport GUI phase -> _unhandled_input.
# Broadcasting here lets a registered, executable binding claim keys like Tab/arrows before
# built-in focus-cycling can swallow them whenever a Control holds keyboard focus.
func _input(event: InputEvent) -> void:
	for action in _input_actions:
		if event.is_action_pressed(action):
			_svc_ui_layers.notify_input_triggered(
				action, ui_layer, InputBindingsTypes.InputActionType.PRESSED
			)
		elif event.is_action_released(action):
			_svc_ui_layers.notify_input_triggered(
				action, ui_layer, InputBindingsTypes.InputActionType.RELEASED
			)


func _unhandled_input(event: InputEvent) -> void:
	if should_block_inputs and get_mounted_nodes().size() > 0:
		get_viewport().set_input_as_handled()


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
