extends GameUiTypes.UiAttachment
## Mounts a label into the HUD showing the currently equipped item, updated whenever
## [member EquipmentState.equipped_item_name] changes.


const GameUiTypes = preload("res://addons/modular_ui_architecture/modules/game_ui/types.gd")
const Hud = preload("res://demo/modules/hud/content/ui/hud.gd")
const EquipmentState = preload("res://demo/modules/equipment/content/classes/equipment_state.gd")

const EQUIPPED_ITEM_LABEL_PATH := "res://demo/modules/equipment/content/ui/equipped_item_label.tscn"

var _state: EquipmentState


func _init(state: EquipmentState) -> void:
	_state = state
	_Scene = load(EQUIPPED_ITEM_LABEL_PATH)
	_slot_tag = &"bottom_left"
	_priority = 10


func _should_mount(host_ui: Node, _context: RefCounted) -> bool:
	return host_ui is Hud


func _build(host_ui: Node, context: RefCounted) -> Control:
	var label: Label = super(host_ui, context)
	_state.equipped_item_changed.connect(_on_equipped_item_changed)
	_refresh(label)
	
	return label


func _refresh(label: Label) -> void:
	if not label:
		return
	
	var item_name := _state.equipped_item_name
	label.text = "Equipped: none" if item_name.is_empty() else "Equipped: %s" % item_name


func _on_instance_tree_exiting() -> void:
	if _state.equipped_item_changed.is_connected(_on_equipped_item_changed):
		_state.equipped_item_changed.disconnect(_on_equipped_item_changed)


func _on_equipped_item_changed(_item_name: String) -> void:
	_refresh(get_instance())
