const GameUiModule = preload("res://addons/modular_ui_architecture/modules/game_ui/game_ui.md.gd")

const GameUiTypes = preload("res://addons/modular_ui_architecture/modules/game_ui/types.gd")

const HUD_PATH := "res://demo/modules/hud/content/ui/hud.tscn"

static var IMPORTS := [
	GameUiModule,
]


class HudModule extends GdlrModule:
	var reg_views: CapViewsRegistry
	
	
	func register() -> void:
		_register_views()
	
	
	func _register_views() -> void:
		var hud_registration := GameUiTypes.ViewRegistration.new(
			Tokens.Scenes.Views.HUD_TOKEN,
			HUD_PATH,
		)
		reg_views.register_view(hud_registration)
