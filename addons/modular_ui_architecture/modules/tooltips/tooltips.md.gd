const UiLayersModule = preload("../ui_layers/ui_layers.md.gd")

const UiLayersTypes := preload("../ui_layers/types.gd")
const TooltipsTypes := preload("./types.gd")
const TooltipUiLayerNode := preload("./nodes/tooltip_ui_layer.gd")
const SvcTooltips = preload("./services/tooltips.svc.gd")

static var IMPORTS := [
	UiLayersModule,
]

static var PROVIDERS := {
	CapTooltips: {
		"inject": [CapUiLayers],
		"use": SvcTooltips,
	},
}

static var EXPORTS := [
	CapTooltips,
]

static var TREE_EXPORTS := [
	CapTooltips,
]


class TooltipsModule extends GdlrModule:
	var reg_ui_layers: CapUiLayersRegistry
	var svc_tooltips: CapTooltips
	
	
	func register() -> void:
		reg_ui_layers.register_layer(UiLayersTypes.UiLayerRegistration.new(
			TooltipsTypes.TOOLTIPS_LAYER, TooltipUiLayerNode, UiLayersTypes.Order.TOOLTIP
		))
	
	
	func enable() -> void:
		svc_tooltips.enable()
	
	
	func disable() -> void:
		svc_tooltips.disable()
