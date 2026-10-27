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
## Returns [code]true[/code] if [param layer] is currently obstructed by a layer drawn above it
## that blocks inputs and has mounted UI.
@abstract func is_layer_input_blocked(layer: UiLayersTypes.UiLayer) -> bool
## Mounts a scene as a child of [param layer] and returns the mounted node.[br]
## [br]
## [param scene_path] - Path of the scene to instantiate.[br]
## [param layer] - Layer the node will be mounted in.[br]
## [param data] - Data forwarded when mounting the node.[br]
## [br]
## Returns the mounted node, or [code]null[/code] if it could not be mounted.
@abstract func mount_ui(
	scene_path: String, layer: UiLayersTypes.UiLayer, data: Dictionary[StringName, Variant] = {}
) -> Node
## Unmounts and frees a node mounted in any layer.[br]
## [br]
## Returns [code]true[/code] if successful, [code]false[/code] if the node is not mounted in a layer.
@abstract func unmount_ui(ui: Node) -> bool
@abstract func notify_input_triggered(
	action: StringName, layer := UiLayersTypes.UiLayer.DEFAULT,
	input_type := InputBindingsTypes.InputActionType.PRESSED
) -> void
