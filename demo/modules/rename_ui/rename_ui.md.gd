const InputBindingsModule = preload("res://addons/modular_ui_architecture/modules/input_bindings/input_bindings.md.gd")
const GameUiModule = preload("res://addons/modular_ui_architecture/modules/game_ui/game_ui.md.gd")

const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const GameUiTypes = preload("res://addons/modular_ui_architecture/modules/game_ui/types.gd")
const ToggleRenameBinding = preload("./bindings/toggle_rename.bind.gd")
const RenameButtonAttachment = preload("./attachments/rename_button.attach.gd")
const RenameDisplay = preload("res://demo/modules/rename_ui/content/ui/rename_display.gd")

const TOGGLE_RENAME_ACTION := &"toggle_rename"
const RENAME_UI_PATH := "res://demo/modules/rename_ui/content/ui/rename_display.tscn"

static var IMPORTS := [
	InputBindingsModule,
	GameUiModule,
]


class RenameUiModule extends GdlrModule:
	var reg_input_bindings: CapInputBindingsRegistry
	var reg_views: CapViewsRegistry
	var reg_attachments: CapUiAttachmentsRegistry
	var svc_input_bindings: CapInputBindings
	var svc_game_ui: CapGameUi
	
	
	func register() -> void:
		_register_bindings()
		_register_views()
		_register_attachments()
	
	
	func _register_bindings() -> void:
		var toggle_rename_binding := ToggleRenameBinding.new(
			svc_game_ui, UiLayersTypes.UiLayer.WINDOW
		)
		reg_input_bindings.register_binding(TOGGLE_RENAME_ACTION, toggle_rename_binding)
	
	
	func _register_views() -> void:
		var rename_ui_registration := GameUiTypes.ViewRegistration.new(
			Tokens.Scenes.Views.RENAME_UI_TOKEN, RENAME_UI_PATH
		)
		reg_views.register_view(rename_ui_registration)
		
		svc_game_ui.view_mounted.connect(_on_game_ui_view_mounted)
	
	
	func _register_attachments() -> void:
		var button_attachment := RenameButtonAttachment.new(svc_input_bindings)
		reg_attachments.register_attachment(button_attachment)
	
	
	func _on_game_ui_view_mounted(token: StringName) -> void:
		if not token == Tokens.Scenes.Views.RENAME_UI_TOKEN:
			return
		
		var rename_display: RenameDisplay = svc_game_ui.get_view(token)
		rename_display.close_requested.connect(_on_rename_display_close_requested.bind(token))
	
	
	func _on_rename_display_close_requested(token: StringName) -> void:
		svc_game_ui.unmount_view(token)
