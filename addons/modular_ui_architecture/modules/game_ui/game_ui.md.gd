const RegUiAttachments = preload("./registries/ui_attachments.reg.gd")
const RegViews = preload("./registries/views.reg.gd")
const SvcGameUi = preload("./services/game_ui.svc.gd")

#region Shared modules
const UiLayersModule = preload("../ui_layers/ui_layers.md.gd")
#endregion

static var PROVIDERS := {
	CapUiAttachmentsRegistry: {
		"use": RegUiAttachments,
	},
	CapViewsRegistry: {
		"use": RegViews,
	},
	CapGameUi: {
		"inject": [CapUiAttachmentsRegistry, CapViewsRegistry, CapUiLayers],
		"use": SvcGameUi,
	},
}

static var EXPORTS := [
	CapUiAttachmentsRegistry,
	CapViewsRegistry,
	CapGameUi,
]

static var IMPORTS := [
	UiLayersModule,
]

static var TREE_EXPORTS := [
	CapGameUi,
]


class GameUiModule extends GdlrModule:
	var svc_game_ui: CapGameUi
	
	
	func enable() -> void:
		svc_game_ui.enable()
	
	
	func disable() -> void:
		svc_game_ui.disable()
