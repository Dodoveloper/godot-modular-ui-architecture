class_name Tokens
extends RefCounted


class Scenes:
	const Views: Dictionary[StringName, StringName] = {
		&"PAUSE_MENU_TOKEN": &"pause_menu",
		&"HUD_TOKEN": &"hud",
		&"INVENTORY_TOKEN": &"inventory",
		&"RENAME_UI_TOKEN": &"rename_ui",
	}


class Layers:
	## Layers registered by the demo's [code]layers[/code] module. The addon's default layer is
	## [code]UiLayersTypes.DEFAULT_LAYER[/code].
	const HUD := &"hud"
	const WINDOW := &"window"


class Policies:
	const Categories: Dictionary[StringName, StringName] = {
		## Whether opening popups triggered by gameplay events is allowed.
		&"OPEN_GAMEPLAY_POPUP_UI": &"open_gameplay_popup_ui",
	}
