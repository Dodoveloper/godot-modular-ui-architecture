extends InputBindingsTypes.InputBinding


const UiLayersTypes = preload("../../ui_layers/types.gd")
const InputBindingsTypes = preload("../../input_bindings/types.gd")
const PopupTypes = preload("../types.gd")

var _svc_popups: CapPopups


func _init(svc_popups: CapPopups, layer_ := UiLayersTypes.UiLayer.DEFAULT) -> void:
	super(layer_)
	_svc_popups = svc_popups


func _execute() -> void:
	_svc_popups.close_topmost_popup(PopupTypes.CloseReason.UI_CANCEL)


func _should_execute() -> bool:
	return _svc_popups.has_popups()
