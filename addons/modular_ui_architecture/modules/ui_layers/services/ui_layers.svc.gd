extends CapUiLayers


var _reg_ui_layers: CapUiLayersRegistry

## Registration of each enabled layer, by token.
var _layer_registrations: Dictionary[StringName, UiLayersTypes.UiLayerRegistration] = {}
var _layers_to_nodes: Dictionary[StringName, UiLayerNode] = {}
var _world_ui_containers: Dictionary[StringName, Control] = {}


func _init(reg_ui_layers: CapUiLayersRegistry) -> void:
	_reg_ui_layers = reg_ui_layers


func enable() -> void:
	_instantiate_layer_nodes()


func disable() -> void:
	_free_layer_nodes()


func get_layer_node(layer: StringName) -> UiLayerNode:
	return _layers_to_nodes.get(layer, null)


func get_layers() -> Array[StringName]:
	var layers: Array[StringName] = []
	layers.assign(_layers_to_nodes.keys())
	return layers


func get_world_ui_container(layer: StringName) -> Control:
	return _world_ui_containers.get(layer, null)


func mount_ui(
	scene_path: String, layer: StringName, data: Dictionary[StringName, Variant] = {}
) -> Node:
	var layer_node := get_layer_node(layer)
	if not layer_node:
		push_error("No UI layer registered for token '%s'" % layer)
		return null
	
	return layer_node.mount_node(scene_path, data)


func unmount_ui(ui: Node) -> bool:
	var layer_node: UiLayerNode
	for layer in get_layers():
		var _layer_node := get_layer_node(layer)
		if _layer_node.get_mounted_nodes().has(ui):
			layer_node = _layer_node
			break
	
	if not layer_node:
		push_error("UI node '%s' not found in any layer" % [ui.name])
		return false
	
	return layer_node.unmount_node(ui)


func is_layer_input_blocked(layer: StringName) -> bool:
	var registration: UiLayersTypes.UiLayerRegistration = _layer_registrations.get(layer, null)
	if not registration:
		return false
	
	for other_layer in _layers_to_nodes.keys():
		var other := _layer_registrations[other_layer]
		if other.order <= registration.order:
			continue
		if not other.should_block_inputs:
			continue
		if _layers_to_nodes[other_layer].get_mounted_nodes().size() > 0:
			return true
	
	return false


func notify_input_triggered(
	action: StringName, layer := UiLayersTypes.DEFAULT_LAYER,
	input_type := InputBindingsTypes.InputActionType.PRESSED
) -> void:
	ui_layer_input_triggered.emit(action, layer, input_type)


func _instantiate_layer_nodes() -> void:
	_reg_ui_layers.seal()
	var tree := Engine.get_main_loop() as SceneTree
	var layer_container := Node.new()
	layer_container.name = LAYER_CONTAINER_NODE_NAME
	tree.root.add_child.call_deferred(layer_container)
	
	# Canvas indices are assigned densely in draw order, so the engine's CanvasLayer range never
	# limits how many layers a project can register.
	var canvas_index := 1
	for registration in _reg_ui_layers.get_layer_registrations():
		var layer := registration.token
		var layer_node: UiLayerNode = registration.node_script.new(self)
		layer_node.ui_layer = layer
		layer_node.layer = canvas_index
		layer_node.should_block_inputs = registration.should_block_inputs
		layer_node.name = layer.to_pascal_case()
		canvas_index += 1
		
		layer_container.add_child(layer_node)
		_layer_registrations[layer] = registration
		_layers_to_nodes[layer] = layer_node
		
		var world_ui_container := Control.new()
		world_ui_container.name = WORLD_UI_CONTAINER_NODE_NAME
		world_ui_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Full-rect so screen-space (AnchorMode.NONE) UI mounted here can resolve its own anchors
		# against the viewport. World-follow UI position is set per-frame and is unaffected.
		world_ui_container.set_anchors_preset(Control.PRESET_FULL_RECT)
		layer_node.add_child(world_ui_container)
		_world_ui_containers[layer] = world_ui_container


func _free_layer_nodes() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var layer_container := tree.root.get_node_or_null(NodePath(LAYER_CONTAINER_NODE_NAME))
	if not layer_container:
		push_warning("Layer Container node is not present in the tree")
		return
	
	layer_container.queue_free()
	_layers_to_nodes.clear()
	_layer_registrations.clear()
	_world_ui_containers.clear()
