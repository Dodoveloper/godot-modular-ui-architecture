const InputBindingsModule := preload("../input_bindings/input_bindings.md.gd")
const UiLayersModule := preload("../ui_layers/ui_layers.md.gd")

const UiLayersTypes := preload("../ui_layers/types.gd")
const PopupsTypes := preload("./types.gd")
const PopupsUiLayerNode := preload("./nodes/popups_ui_layer.gd")
const ClosePopupBinding = preload("./bindings/close_popup.bind.gd")
const SvcPopups = preload("./services/popups.svc.gd")

static var IMPORTS := [
	InputBindingsModule,
	UiLayersModule,
]

static var PROVIDERS := {
	CapPopups: {
		"inject": [CapUiLayers],
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
	var reg_ui_layers: CapUiLayersRegistry
	var svc_popups: CapPopups
	
	
	func register() -> void:
		_register_layer()
		_register_bindings()
	
	
	func _register_layer() -> void:
		reg_ui_layers.register_layer(UiLayersTypes.UiLayerRegistration.new(
			PopupsTypes.POPUPS_LAYER, PopupsUiLayerNode, UiLayersTypes.Order.POPUP, true
		))
	
	
	func _register_bindings() -> void:
		var close_popup_binding := ClosePopupBinding.new(
			svc_popups, PopupsTypes.POPUPS_LAYER
		)
		reg_input_bindings.register_binding(&"ui_cancel", close_popup_binding)
