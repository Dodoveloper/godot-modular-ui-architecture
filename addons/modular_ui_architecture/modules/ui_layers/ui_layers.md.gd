const SvcUiLayers = preload("./services/ui_layers.svc.gd")
const UiLayersTypes = preload("./types.gd")

static var PROVIDERS := {
	CapUiLayers: {
		"use": SvcUiLayers,
	},
}

static var EXPORTS := [
	CapUiLayers,
]

static var TREE_EXPORTS := [
	CapUiLayers,
]


class UiLayersModule extends GdlrModule:
	var svc_ui_layers: CapUiLayers
	
	
	func enable() -> void:
		svc_ui_layers.enable()
	
	
	func disable() -> void:
		svc_ui_layers.disable()
