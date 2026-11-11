const LayersModule = preload("res://demo/modules/layers/layers.md.gd")
const HudModule = preload("res://demo/modules/hud/hud.md.gd")
const PlayerModule = preload("res://demo/modules/player/player.md.gd")
const PauseMenuModule = preload("res://demo/modules/pause_menu/pause_menu.md.gd")
const RenameUiModule = preload("res://demo/modules/rename_ui/rename_ui.md.gd")
const InventoryModule = preload("res://demo/modules/inventory/inventory.md.gd")
const ChestModule = preload("res://demo/modules/chest/chest.md.gd")
const EquipmentModule = preload("res://demo/modules/equipment/equipment.md.gd")
const PoliciesModule = preload("res://demo/modules/policies/policies.md.gd")

static var IMPORTS := [
	LayersModule,
	HudModule,
	PlayerModule,
	PauseMenuModule,
	RenameUiModule,
	InventoryModule,
	ChestModule,
	EquipmentModule,
	PoliciesModule,
]


class DemoModule extends GdlrModule:
	pass
