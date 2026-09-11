const GameUiModule = preload("res://addons/modular_ui_architecture/modules/game_ui/game_ui.md.gd")
const InputBindingsModule = preload("res://addons/modular_ui_architecture/modules/input_bindings/input_bindings.md.gd")

const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const GameUiTypes = preload("res://addons/modular_ui_architecture/modules/game_ui/types.gd")
const TogglePauseMenuBinding = preload("./bindings/toggle_pause_menu.bind.gd")
const Hud = preload("res://demo/modules/hud/content/ui/hud.gd")

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
	
	
	func _register_attachments() -> void:
		pass
