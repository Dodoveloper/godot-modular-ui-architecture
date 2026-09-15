extends InputBindingsTypes.InputBinding


const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const InputBindingsTypes = preload("res://addons/modular_ui_architecture/modules/input_bindings/types.gd")
const PolicyStoreTypes = preload("res://addons/modular_ui_architecture/modules/policy_store/types.gd")

const RENAME_DISPLAY_PATH := "res://demo/modules/rename_ui/content/ui/rename_display.tscn"

var _svc_popups: CapPopups
var _svc_policy_store: CapPolicyStore


func _init(
	svc_popups: CapPopups, svc_policy_store: CapPolicyStore, layer_: UiLayersTypes.UiLayer
) -> void:
	_svc_popups = svc_popups
	_svc_policy_store = svc_policy_store
	super(layer_)


func _execute() -> void:
	_svc_popups.open_popup(
		RENAME_DISPLAY_PATH, null, Vector2.ZERO, false, Color(0.0, 0.0, 0.0, 0.5), true
	)


func _should_execute() -> bool:
	return (
		not _svc_popups.has_popups()
		and _svc_policy_store.is_allowed(PolicyStoreTypes.Category.OPEN_POPUP_UI)
	)
