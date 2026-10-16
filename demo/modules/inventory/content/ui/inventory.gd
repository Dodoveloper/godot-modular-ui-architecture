@tool
extends ToggleableDisplay


const InputManager = preload("res://demo/shared/classes/input_manager.gd")
const InventorySlot = preload("res://demo/modules/inventory/content/ui/inventory_slot.gd")

var context := Context.new()

@onready var _slots_grid: GridContainer = %SlotsGrid


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return
	
	for slot in _slots_grid.get_children():
		if slot is InventorySlot:
			(slot as InventorySlot).item_selected.connect(_on_slot_item_selected)


func _on_block_inputs() -> void:
	InputManager.block()


func _on_unblock_inputs() -> void:
	InputManager.unblock()


func _on_slot_item_selected(item_name: String) -> void:
	context.selected_item_name = item_name


class Context extends RefCounted:
	## Display name of the currently-selected item, or an empty string if none is selected.
	var selected_item_name := ""
