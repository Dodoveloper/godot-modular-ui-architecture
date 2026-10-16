const GameUiModule = preload("res://addons/modular_ui_architecture/modules/game_ui/game_ui.md.gd")

const EquipmentState = preload("./content/classes/equipment_state.gd")
const EquipButtonAttachment = preload("./attachments/equip_button.attach.gd")
const EquippedItemLabelAttachment = preload("./attachments/equipped_item_label.attach.gd")

static var IMPORTS := [
	GameUiModule,
]


class EquipmentModule extends GdlrModule:
	var reg_attachments: CapUiAttachmentsRegistry
	
	
	func register() -> void:
		var state := EquipmentState.new()
		
		reg_attachments.register_attachment(EquipButtonAttachment.new(state))
		reg_attachments.register_attachment(EquippedItemLabelAttachment.new(state))
