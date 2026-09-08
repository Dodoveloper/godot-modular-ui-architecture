const InputBindingsModule := preload("../input_bindings/input_bindings.md.gd")
const UiLayersModule := preload("../ui_layers/ui_layers.md.gd")
const GameUiModule := preload("../game_ui/game_ui.md.gd")

const UiLayersTypes := preload("../ui_layers/types.gd")
const GameUiTypes := preload("../game_ui/types.gd")
const ClosePopupBinding = preload("./input_bindings/close_popup.bind.gd")
const SvcPopups = preload("./services/popups.svc.gd")

static var IMPORTS := [
	InputBindingsModule,
	UiLayersModule,
	GameUiModule,
]

static var PROVIDERS := {
	CapPopups: {
		"inject": [CapGameUi, CapUiLayers],
		"use": SvcPopups,
	},
}

static var EXPORTS := [
	CapPopups,
]

static var TREE_EXPORTS := [
	CapPopups,
]


class PopupsModule extends GdlrModule:
	var reg_input_bindings: CapInputBindingsRegistry
	var svc_popups: CapPopups
	
	
	func register() -> void:
		_register_bindings()
	
	
	func _register_bindings() -> void:
		var close_popup_binding := ClosePopupBinding.new(
			svc_popups, UiLayersTypes.UiLayer.POPUP
		)
		reg_input_bindings.register_binding(&"ui_cancel", close_popup_binding)
