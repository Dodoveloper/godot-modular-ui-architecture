extends GameUiTypes.UiAttachment
## Mounts an [i]Equip[/i] button into the Inventory's [code]footer[/code] Attachment Slot.[br]
## The Inventory never imports this module and knows nothing about equipment — it only exposes
## the slot and its own [member Inventory.context]. This is the cross-module Attachment example:
## a module other than [code]inventory[/code] contributing UI into the Inventory View.


const GameUiTypes = preload("res://addons/modular_ui_architecture/modules/game_ui/types.gd")
const Inventory = preload("res://demo/modules/inventory/content/ui/inventory.gd")
const EquipmentState = preload("res://demo/modules/equipment/content/classes/equipment_state.gd")

const EQUIP_BUTTON_PATH := "res://demo/modules/equipment/content/ui/equip_button.tscn"

var _state: EquipmentState
var _inventory: Inventory


func _init(state: EquipmentState) -> void:
	_state = state
	_Scene = load(EQUIP_BUTTON_PATH)
	_slot_tag = &"footer"


func _should_mount(host_ui: Node, _context: RefCounted) -> bool:
	return host_ui is Inventory


func _build(host_ui: Node, context: RefCounted) -> Control:
	_inventory = host_ui as Inventory
	
	var button: Button = super(host_ui, context)
	button.pressed.connect(_on_button_pressed)
	_refresh(button, context)
	
	return button


func _refresh(button: Button, context: RefCounted) -> void:
	if not button:
		return
	
	var selected_item_name: String = context.selected_item_name if context else ""
	button.disabled = (
		selected_item_name.is_empty() or selected_item_name == _state.equipped_item_name
	)
	button.text = "Equip" if selected_item_name.is_empty() else "Equip %s" % selected_item_name


func _on_context_changed(new_context: RefCounted) -> void:
	_refresh(get_instance(), new_context)


func _on_button_pressed() -> void:
	_state.equipped_item_name = _inventory.context.selected_item_name
