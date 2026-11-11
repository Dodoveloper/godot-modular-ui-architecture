const RegUiLayers = preload("./registries/ui_layers.reg.gd")
const SvcUiLayers = preload("./services/ui_layers.svc.gd")
const UiLayersTypes = preload("./types.gd")
const DefaultUiLayerNode = preload("./nodes/default_ui_layer.gd")

static var PROVIDERS := {
	CapUiLayersRegistry: {
		"use": RegUiLayers,
	},
	CapUiLayers: {
		"inject": [CapUiLayersRegistry],
		"use": SvcUiLayers,
	},
}

static var EXPORTS := [
	CapUiLayersRegistry,
	CapUiLayers,
]

static var TREE_EXPORTS := [
	CapUiLayers,
]


class UiLayersModule extends GdlrModule:
	var reg_ui_layers: CapUiLayersRegistry
	var svc_ui_layers: CapUiLayers
	
	
	func register() -> void:
		# The DEFAULT layer is the fallback every View and binding uses, so the addon always provides it.
		reg_ui_layers.register_layer(UiLayersTypes.UiLayerRegistration.new(
			UiLayersTypes.DEFAULT_LAYER, DefaultUiLayerNode, UiLayersTypes.Order.DEFAULT
		))
	
	
	func enable() -> void:
		svc_ui_layers.enable()
	
	
	func disable() -> void:
		svc_ui_layers.disable()
