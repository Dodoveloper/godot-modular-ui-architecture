extends CapUiLayers


const Utils = preload("../../../shared/classes/utils.gd")
const WindowUiLayerNode = preload("../nodes/window_ui_layer.gd")
const PopupsUiLayerNode = preload("../nodes/popups_ui_layer.gd")
const TooltipUiLayerNode = preload("../nodes/tooltip_ui_layer.gd")

static var _layers_config: Dictionary[UiLayersTypes.UiLayer, UiLayersTypes.UiLayerConfig] = {
	UiLayersTypes.UiLayer.DEFAULT: UiLayersTypes.UiLayerConfig.new(UiLayerNode, 1, false),
	UiLayersTypes.UiLayer.HUD: UiLayersTypes.UiLayerConfig.new(UiLayerNode, 2, false),
	UiLayersTypes.UiLayer.HUD_OVERLAY: UiLayersTypes.UiLayerConfig.new(UiLayerNode, 3, false),
	UiLayersTypes.UiLayer.WINDOW: UiLayersTypes.UiLayerConfig.new(WindowUiLayerNode, 4, true),
	UiLayersTypes.UiLayer.OVERLAY: UiLayersTypes.UiLayerConfig.new(UiLayerNode, 5, true),
	UiLayersTypes.UiLayer.POPUP: UiLayersTypes.UiLayerConfig.new(PopupsUiLayerNode, 6, true),
	UiLayersTypes.UiLayer.TOOLTIP: UiLayersTypes.UiLayerConfig.new(TooltipUiLayerNode, 7, false),
}

var _layers_to_nodes: Dictionary[UiLayersTypes.UiLayer, UiLayerNode] = {}
var _world_ui_containers: Dictionary[UiLayersTypes.UiLayer, Control] = {}


func enable() -> void:
	_instantiate_layer_nodes()


func disable() -> void:
	_free_layer_nodes()


func get_layer_node(layer: UiLayersTypes.UiLayer) -> UiLayerNode:
	return _layers_to_nodes.get(layer, null)


func get_layers() -> Array[UiLayersTypes.UiLayer]:
	return _layers_to_nodes.keys()


func get_world_ui_container(layer: UiLayersTypes.UiLayer) -> Control:
	return _world_ui_containers.get(layer, null)


func notify_input_triggered(
	action: StringName, layer := UiLayersTypes.UiLayer.DEFAULT,
	input_type := InputBindingsTypes.InputActionType.PRESSED
) -> void:
	ui_layer_input_triggered.emit(action, layer, input_type)


func _instantiate_layer_nodes() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var layer_container := Node.new()
	layer_container.name = LAYER_CONTAINER_NODE_NAME
	tree.root.add_child.call_deferred(layer_container)
	
	for layer in _layers_config.keys():
		var layer_config := _layers_config[layer]
		var layer_node: UiLayerNode = layer_config.node_script.new(self)
		layer_node.ui_layer = layer
		layer_node.layer = layer_config.canvas_layer_index
		layer_node.should_block_inputs = layer_config.should_block_inputs
		layer_node.name = Utils.enum_to_str(UiLayersTypes.UiLayer, layer).to_pascal_case()
		
		layer_container.add_child(layer_node)
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
	_world_ui_containers.clear()
