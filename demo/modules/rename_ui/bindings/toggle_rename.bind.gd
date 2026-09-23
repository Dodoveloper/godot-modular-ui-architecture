extends InputBindingsTypes.InputBinding


const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const InputBindingsTypes = preload("res://addons/modular_ui_architecture/modules/input_bindings/types.gd")
const PolicyStoreTypes = preload("res://addons/modular_ui_architecture/modules/policy_store/types.gd")

const RENAME_DISPLAY_PATH := "res://demo/modules/rename_ui/content/ui/rename_display.tscn"

var _svc_game_ui: CapGameUi


func _init(
	svc_game_ui: CapGameUi, layer_: UiLayersTypes.UiLayer
) -> void:
	_svc_game_ui = svc_game_ui
	super(layer_)


func _execute() -> void:
	if not _svc_game_ui.get_view(Tokens.Scenes.Views.RENAME_UI_TOKEN):
		_svc_game_ui.mount_view(Tokens.Scenes.Views.RENAME_UI_TOKEN, layer)
	else:
		_svc_game_ui.unmount_view(Tokens.Scenes.Views.RENAME_UI_TOKEN)


func _should_execute() -> bool:
	return true
