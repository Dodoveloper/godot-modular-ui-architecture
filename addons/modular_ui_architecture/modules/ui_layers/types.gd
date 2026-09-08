enum UiLayer {
	## Fallback layer.
	DEFAULT,
	## Layer for HUDs.
	HUD,
	## Layer for HUD overlays.
	HUD_OVERLAY,
	## Layer for exclusive Views.
	WINDOW,
	## Layer for Overlays.
	OVERLAY,
	## Layer for Popups.
	POPUP,
	## Layer for Tooltips.
	TOOLTIP,
}


class UiLayerConfig extends RefCounted:
	var node_script: GDScript
	var canvas_layer_index: int
	var should_block_inputs: bool
	
	
	func _init(
		node_script_: GDScript, canvas_layer_index_: int, should_block_inputs_: bool
	) -> void:
		node_script = node_script_
		canvas_layer_index = canvas_layer_index_
		should_block_inputs = should_block_inputs_
