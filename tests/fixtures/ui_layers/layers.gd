## Test fixture that builds a [UiLayersService] with the layers a project normally registers.
##
## It reuses the real registry and the real layer scripts, so tests exercise the same code paths
## as the addon. Each token here mirrors one registered by a module.
const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const UiLayersRegistry = preload("res://addons/modular_ui_architecture/modules/ui_layers/registries/ui_layers.reg.gd")
const UiLayersService = preload("res://addons/modular_ui_architecture/modules/ui_layers/services/ui_layers.svc.gd")
const DefaultUiLayerNode = preload("res://addons/modular_ui_architecture/modules/ui_layers/nodes/default_ui_layer.gd")
const PopupsTypes = preload("res://addons/modular_ui_architecture/modules/popups/types.gd")
const PopupsUiLayerNode = preload("res://addons/modular_ui_architecture/modules/popups/nodes/popups_ui_layer.gd")
const TooltipsTypes = preload("res://addons/modular_ui_architecture/modules/tooltips/types.gd")
const TooltipUiLayerNode = preload("res://addons/modular_ui_architecture/modules/tooltips/nodes/tooltip_ui_layer.gd")
const HudUiLayerNode = preload("res://demo/modules/layers/nodes/hud_ui_layer.gd")
const WindowUiLayerNode = preload("res://demo/modules/layers/nodes/window_ui_layer.gd")
const DemoTokens = preload("res://demo/shared/classes/tokens.gd")


## Returns a registry with every layer the project registers, in the same order as the modules.
static func make_registry() -> UiLayersRegistry:
	var registry := UiLayersRegistry.new()
	registry.register_layer(UiLayersTypes.UiLayerRegistration.new(
		UiLayersTypes.DEFAULT_LAYER, DefaultUiLayerNode, UiLayersTypes.Order.DEFAULT
	))
	registry.register_layer(UiLayersTypes.UiLayerRegistration.new(
		DemoTokens.Layers.HUD, HudUiLayerNode, UiLayersTypes.Order.HUD
	))
	registry.register_layer(UiLayersTypes.UiLayerRegistration.new(
		DemoTokens.Layers.WINDOW, WindowUiLayerNode, UiLayersTypes.Order.WINDOW, true
	))
	registry.register_layer(UiLayersTypes.UiLayerRegistration.new(
		PopupsTypes.POPUPS_LAYER, PopupsUiLayerNode, UiLayersTypes.Order.POPUP, true
	))
	registry.register_layer(UiLayersTypes.UiLayerRegistration.new(
		TooltipsTypes.TOOLTIPS_LAYER, TooltipUiLayerNode, UiLayersTypes.Order.TOOLTIP
	))
	return registry


## Returns a [UiLayersService] backed by [method make_registry]. Call [method UiLayersService.enable]
## on it, then wait for the layer container as usual.
static func make_service() -> UiLayersService:
	return UiLayersService.new(make_registry())
