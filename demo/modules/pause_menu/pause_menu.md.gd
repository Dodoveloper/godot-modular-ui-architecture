const GameUiModule = preload("res://addons/modular_ui_architecture/modules/game_ui/game_ui.md.gd")
const InputBindingsModule = preload("res://addons/modular_ui_architecture/modules/input_bindings/input_bindings.md.gd")

const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const GameUiTypes = preload("res://addons/modular_ui_architecture/modules/game_ui/types.gd")
const TogglePauseMenuBinding = preload("./bindings/toggle_pause_menu.bind.gd")
const PauseMenuButtonAttachment = preload("./attachments/pause_menu_button.attach.gd")
const Hud = preload("res://demo/modules/hud/content/ui/hud.gd")
const PauseMenu = preload("res://demo/modules/pause_menu/content/ui/pause_menu.gd")

const PAUSE_MENU_PATH := "res://demo/modules/pause_menu/content/ui/pause_menu.tscn"
const TOGGLE_PAUSE_ACTION := &"toggle_pause"

static var IMPORTS := [
	GameUiModule,
	InputBindingsModule,
]


class PauseMenuModule extends GdlrModule:
	var reg_input_bindings: CapInputBindingsRegistry
	var reg_views: CapViewsRegistry
	var reg_attachments: CapUiAttachmentsRegistry
	var svc_game_ui: CapGameUi
	var svc_input_bindings: CapInputBindings
	
	
	func register() -> void:
		_register_bindings()
		_register_views()
		_register_attachments()
	
	
	func _register_bindings() -> void:
		var toggle_pm_binding := TogglePauseMenuBinding.new(
			svc_game_ui, UiLayersTypes.UiLayer.WINDOW
		)
		reg_input_bindings.register_binding(TOGGLE_PAUSE_ACTION, toggle_pm_binding)
	
	
	func _register_views() -> void:
		var pm_registration := GameUiTypes.ViewRegistration.new(
			Tokens.Scenes.Views.PAUSE_MENU_TOKEN,
			PAUSE_MENU_PATH,
		)
		reg_views.register_view(pm_registration)
		
		svc_game_ui.view_mounted.connect(_on_game_ui_view_mounted)
	
	
	func _register_attachments() -> void:
		var button_attachment := PauseMenuButtonAttachment.new(svc_input_bindings)
		reg_attachments.register_attachment(button_attachment)
	
	
	func _on_game_ui_view_mounted(token: StringName) -> void:
		if token != Tokens.Scenes.Views.PAUSE_MENU_TOKEN:
			return
		
		var pause_menu: PauseMenu = svc_game_ui.get_view(token)
		pause_menu.close_requested.connect(_on_pause_menu_close_requested.bind(token))
		pause_menu.quit_requested.connect(_on_pause_menu_quit_requested)
	
	
	func _on_pause_menu_close_requested(token: StringName) -> void:
		svc_game_ui.unmount_view(token)
	
	
	func _on_pause_menu_quit_requested() -> void:
		var tree := Engine.get_main_loop() as SceneTree
		tree.quit()
