## Token of the fallback layer. Views and bindings use it when they don't name a layer.
const DEFAULT_LAYER := &"default"


## Predefined draw-order anchors. Layers with a higher order are drawn on top and receive input
## first. A module can register any integer order, so these are anchors to build on, not a closed
## list. Leave gaps between them so a module can register a layer in between.
enum Order {
	DEFAULT = 0,
	HUD = 100,
	HUD_OVERLAY = 200,
	WINDOW = 300,
	OVERLAY = 400,
	POPUP = 500,
	TOOLTIP = 600,
}


## Describes a UI layer that a module registers.
class UiLayerRegistration extends RefCounted:
	## Unique token identifying the layer, for example [code]&"hud"[/code].
	var token: StringName
	## Script of the layer's node. It must extend [UiLayerNode]. Don't override [method Object._init],
	## because the addon creates the node with the layers service as its only argument.
	var node_script: GDScript
	## Draw and input order. Layers with a higher order are drawn on top. Orders must be unique.
	var order: int
	## Whether the layer blocks the input of the layers below it while it has UI mounted.
	var should_block_inputs: bool
	
	
	func _init(
		token_: StringName, node_script_: GDScript, order_: int, should_block_inputs_ := false
	) -> void:
		token = token_
		node_script = node_script_
		order = order_
		should_block_inputs = should_block_inputs_
