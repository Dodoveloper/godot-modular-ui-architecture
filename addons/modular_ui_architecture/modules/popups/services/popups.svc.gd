extends CapPopups


const PopupsUiLayer = preload("../../ui_layers/nodes/popups_ui_layer.gd")

var _svc_ui_layers: CapUiLayers


func _init(svc_ui_layers: CapUiLayers) -> void:
	_svc_ui_layers = svc_ui_layers


func enable() -> void:
	print("CapPopups enabled")


func disable() -> void:
	print("CapPopups disabled")


func open_popup(
	popup_path: String, parent: Control = null, position := Vector2.ZERO,
	is_blocking := false, color := Color(0.0, 0.0, 0.0, 0.0),
	dismiss_on_click_outside := true
) -> Control:
	var popup_data: Dictionary[StringName, Variant] = {}
	popup_data.parent = parent
	popup_data.position = position
	popup_data.is_blocking = is_blocking
	popup_data.color = color
	popup_data.dismiss_on_click_outside = dismiss_on_click_outside

	return _svc_ui_layers.mount_ui(popup_path, UiLayersTypes.UiLayer.POPUP, popup_data)


func open_popup_queued(
	popup_path: String, color := Color(0.0, 0.0, 0.0, 0.5), setup := Callable(),
	dismiss_on_click_outside := false
) -> void:
	var popups_layer: PopupsUiLayer = _svc_ui_layers.get_layer_node(UiLayersTypes.UiLayer.POPUP)
	popups_layer.enqueue_popup(popup_path, color, setup, dismiss_on_click_outside)


func close_popup(popup: Control) -> bool:
	return _svc_ui_layers.unmount_ui(popup)


func has_popups() -> bool:
	var popups_layer: PopupsUiLayer = _svc_ui_layers.get_layer_node(UiLayersTypes.UiLayer.POPUP)
	return popups_layer.has_popups()


func close_topmost_popup(reason := PopupTypes.CloseReason.SERVICE) -> void:
	var popups_layer: PopupsUiLayer = _svc_ui_layers.get_layer_node(UiLayersTypes.UiLayer.POPUP)
	popups_layer.close_topmost_popup(reason)
