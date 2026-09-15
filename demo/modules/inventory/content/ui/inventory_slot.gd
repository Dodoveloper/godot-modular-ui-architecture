extends Panel


const InventoryItemTooltip = preload("res://demo/modules/inventory/content/ui/inventory_item_tooltip.tscn")

## Display name shown as the tooltip's title.
@export var item_name := ""
## Flavor text shown in the tooltip's body.
@export var item_description := ""

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


func _on_mouse_entered() -> void:
	if item_name.is_empty():
		return

	var contents: Dictionary[String, Variant] = {
		"title": item_name,
		"description": item_description,
	}
	_svc_tooltips.show_tooltip(
		InventoryItemTooltip.resource_path, self, contents, get_viewport().get_visible_rect()
	)


func _on_mouse_exited() -> void:
	_svc_tooltips.hide_tooltip()
