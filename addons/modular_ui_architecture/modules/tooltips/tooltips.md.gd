const UiLayersModule = preload("../ui_layers/ui_layers.md.gd")
const GameUiModule = preload("../game_ui/game_ui.md.gd")

const SvcTooltips = preload("./services/tooltips.svc.gd")

static var IMPORTS := [
	UiLayersModule,
	GameUiModule,
]

static var PROVIDERS := {
	CapTooltips: {
		"inject": [CapGameUi, CapUiLayers],
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
	var svc_tooltips: CapTooltips
	
	
	func enable() -> void:
		svc_tooltips.enable()
	
	
	func disable() -> void:
		svc_tooltips.disable()
