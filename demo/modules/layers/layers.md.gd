const UiLayersModule = preload("res://addons/modular_ui_architecture/modules/ui_layers/ui_layers.md.gd")

const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const HudUiLayerNode = preload("./nodes/hud_ui_layer.gd")
const WindowUiLayerNode = preload("./nodes/window_ui_layer.gd")

static var IMPORTS := [
	UiLayersModule,
]


class LayersDemoModule extends GdlrModule:
	var reg_ui_layers: CapUiLayersRegistry
	
	
	func register() -> void:
		reg_ui_layers.register_layer(UiLayersTypes.UiLayerRegistration.new(
			Tokens.Layers.HUD, HudUiLayerNode, UiLayersTypes.Order.HUD
		))
		reg_ui_layers.register_layer(UiLayersTypes.UiLayerRegistration.new(
			Tokens.Layers.WINDOW, WindowUiLayerNode, UiLayersTypes.Order.WINDOW, true
		))
