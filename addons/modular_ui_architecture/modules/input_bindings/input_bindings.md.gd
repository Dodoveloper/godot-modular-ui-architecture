const RegInputBindings = preload("./registries/input_bindings.reg.gd")
const SvcInputBindings = preload("./services/input_bindings.svc.gd")

const UiLayersModule = preload("../ui_layers/ui_layers.md.gd")

static var PROVIDERS := {
	CapInputBindingsRegistry: {
		"use": RegInputBindings,
	},
	CapInputBindings: {
		"inject": [CapInputBindingsRegistry, CapUiLayers],
		"use": SvcInputBindings,
	},
}

static var IMPORTS := [
	UiLayersModule,
]

static var EXPORTS := [
	CapInputBindingsRegistry,
	CapInputBindings,
]

static var TREE_EXPORTS := [
	CapInputBindings,
]


class InputBindingsModule extends GdlrModule:
	var svc_input_bindings: CapInputBindings
	
	
	func enable() -> void:
		svc_input_bindings.enable()
	
	
	func disable() -> void:
		svc_input_bindings.disable()
