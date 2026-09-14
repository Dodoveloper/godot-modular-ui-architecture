const HudModule = preload("res://demo/modules/hud/hud.md.gd")
const PlayerModule = preload("res://demo/modules/player/player.md.gd")
const PauseMenuModule = preload("res://demo/modules/pause_menu/pause_menu.md.gd")
const RenameUiModule = preload("res://demo/modules/rename_ui/rename_ui.md.gd")

static var IMPORTS := [
	HudModule,
	PlayerModule,
	PauseMenuModule,
	RenameUiModule,
]


class DemoModule extends GdlrModule:
	pass
