extends CapTooltips


const TooltipUiLayer = preload("../../ui_layers/nodes/tooltip_ui_layer.gd")

var _svc_game_ui: CapGameUi
var _svc_ui_layers: CapUiLayers


func _init(svc_game_ui: CapGameUi, svc_ui_layers: CapUiLayers) -> void:
	_svc_game_ui = svc_game_ui
	_svc_ui_layers = svc_ui_layers


func enable() -> void:
	print("CapTooltips enabled")


func disable() -> void:
	print("CapTooltips disabled")


func show_tooltip(
	tooltip_path: String, anchor: Control, contents: Dictionary[String, Variant], available_rect: Rect2,
) -> Tooltip:
	var tooltip_data: Dictionary[StringName, Variant] = {}
	tooltip_data.anchor = anchor
	tooltip_data.contents = contents
	tooltip_data.available_rect = available_rect
	
	return _svc_game_ui.mount_ui(tooltip_path, UiLayersTypes.UiLayer.TOOLTIP, tooltip_data)


func hide_tooltip() -> bool:
	var tooltip_ui_layer: TooltipUiLayer = _svc_ui_layers.get_layer_node(UiLayersTypes.UiLayer.TOOLTIP)
	return tooltip_ui_layer.unmount_tooltip()
