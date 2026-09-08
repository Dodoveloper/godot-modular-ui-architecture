@abstract
class_name CapUiLayers
extends GdlrCapability


const UiLayersTypes = preload("../types.gd")
const InputBindingsTypes = preload("../../input_bindings/types.gd")

@warning_ignore("unused_signal")
## Emitted when an input [param action] for a certain [param layer] is triggered.
## [param input_type] is the type of input (pressed or released).
signal ui_layer_input_triggered(
	action: StringName, layer: UiLayersTypes.UiLayer, input_type: InputBindingsTypes.InputActionType
)

const LAYER_CONTAINER_NODE_NAME := &"UiLayerContainer"
const WORLD_UI_CONTAINER_NODE_NAME := &"GameWorldUi"


@abstract func enable() -> void
@abstract func disable() -> void
## Returns the mounted layer node for [param layer].
@abstract func get_layer_node(layer: UiLayersTypes.UiLayer) -> UiLayerNode
## Returns the list of mounted layers.
@abstract func get_layers() -> Array[UiLayersTypes.UiLayer]
## Returns the world-UI container node for [param layer].
@abstract func get_world_ui_container(layer: UiLayersTypes.UiLayer) -> Control
@abstract func notify_input_triggered(
	action: StringName, layer := UiLayersTypes.UiLayer.DEFAULT,
	input_type := InputBindingsTypes.InputActionType.PRESSED
) -> void
