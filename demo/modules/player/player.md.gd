const GameUiModule = preload("res://addons/modular_ui_architecture/modules/game_ui/game_ui.md.gd")

## No providers of its own — [Player] and its [Nameplate] resolve [CapGameUi] directly via
## [code]GdlrModuleManager.request()[/code] (see [WorldUiPortal]). Importing [GameUiModule] here
## makes that dependency explicit rather than relying on another module incidentally pulling it
## into the graph.
static var IMPORTS := [
	GameUiModule,
]


class PlayerModule extends GdlrModule:
	pass
