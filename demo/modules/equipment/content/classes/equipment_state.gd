extends RefCounted
## Shared state between this module's two Attachments (the Inventory's Equip button and the
## HUD's equipped-item label).


signal equipped_item_changed(item_name: String)

var equipped_item_name := "":
	set(value):
		if equipped_item_name == value:
			return
		
		equipped_item_name = value
		equipped_item_changed.emit(equipped_item_name)
