extends Panel


const InventoryItemTooltip = preload("res://demo/modules/inventory/content/ui/inventory_item_tooltip.tscn")

## Emitted when this slot gains focus and holds an item (empty slots don't emit this).[br]
## [br]
## [param item_name] - Same value as [member item_name] at the time of selection.
signal item_selected(item_name: String)

## Display name shown as the tooltip's title.
@export var item_name := ""
## Flavor text shown in the tooltip's body.
@export_multiline() var item_description := ""
## Visual highlight applied while this slot has focus .
@export var selected_modulate := Color(1.3, 1.3, 1.1, 1.0)

var _svc_tooltips: CapTooltips


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return
	
	_svc_tooltips = GdlrModuleManager.request(CapTooltips, self)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)


func _gui_input(event: InputEvent) -> void:
	if (
		event is InputEventMouseButton
		and event.pressed
		and event.button_index == MOUSE_BUTTON_LEFT
	):
		grab_focus()


func _on_mouse_entered() -> void:
	if item_name.is_empty():
		return
	
	var contents: Dictionary[StringName, Variant] = {
		&"title": item_name,
		&"description": item_description,
	}
	_svc_tooltips.show_tooltip(
		InventoryItemTooltip.resource_path, self, contents, get_viewport().get_visible_rect()
	)


func _on_mouse_exited() -> void:
	_svc_tooltips.hide_tooltip()


func _on_focus_entered() -> void:
	self_modulate = selected_modulate
	if not item_name.is_empty():
		item_selected.emit(item_name)


func _on_focus_exited() -> void:
	self_modulate = Color.WHITE
