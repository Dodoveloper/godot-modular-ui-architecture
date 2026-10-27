@tool
extends Node
## Manages UiAttachment Slots for its parent View.
##
## This object is meant to be attached as a helper component.
## It allows configuring slots via the inspector, takes care of registering them on [signal ready]
## and provides a simple API for attaching UI to them.


const Utils = preload("../utils.gd")

## Slots configuration.
@export var slot_configs: Dictionary[StringName, AttachmentSlotConfig]

var _svc_game_ui: CapGameUi

## Slots exposed by this UI, indexed by tag ID.
## [codeblock]
## @shape: {
##   [tag_id: StringName]: [slot: AttachmentSlot]
## }
## [/codeblock]
var _slots: Dictionary[StringName, AttachmentSlot] = {}
## Mapping of UIs to their respective priorities.
var _priorities_by_ui: Dictionary[Control, int] = {}
## Tracks which slots have center protection enabled, mapped to their [BoxContainer] parent.
var _protected_center_slots: Dictionary[StringName, Node] = {}


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return
	
	await Utils.await_module_graph_started()
	
	_svc_game_ui = GdlrModuleManager.request(CapGameUi, self)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_initialize_slots()
	_debug_print_slots()
	_svc_game_ui.mount_attachments(owner, add_to_slot)


## Adds [param ui] to the slot tagged [param slot_tag], ordered by [param priority].[br]
## [br]
## Returns [code]true[/code] if the UI was placed, [code]false[/code] if the slot does not exist or
## has no space left. In that case, [param ui] is not added to the tree.
func add_to_slot(slot_tag: StringName, ui: Control, priority := 0) -> bool:
	var slot := get_slot(slot_tag)
	if not slot:
		push_warning("Slot '%s' not found. Ignoring" % slot_tag)
		return false
	if not slot.has_space():
		push_error("Slot '%s' does not have space left" % slot_tag)
		return false
	
	_priorities_by_ui[ui] = priority
	
	var insert_index := _calculate_insert_index(slot.node, priority)
	slot.node.add_child(ui)
	if insert_index >= 0:
		slot.node.move_child(ui, insert_index)
	# Check if this slot or any sibling is protected
	_refresh_protection_for_container(slot.node.get_parent())
	
	ui.tree_exiting.connect(_on_ui_tree_exiting.bind(ui), CONNECT_ONE_SHOT)
	return true


func has_slot(slot_tag: StringName) -> bool:
	return _slots.has(slot_tag)


func get_slot(slot_tag: StringName) -> AttachmentSlot:
	return _slots.get(slot_tag, null)


func _initialize_slots() -> void:
	for slot_tag: StringName in slot_configs.keys():
		var slot_config := slot_configs[slot_tag]
		var slot_node := get_node_or_null(slot_config.node_path)
		assert(
			slot_node,
			"Node for slot '%s' not found at path '%s'" % [slot_tag, slot_config.node_path]
		)
		_register_slot(slot_tag, slot_node, slot_config.max_children)
		
		if slot_config.protected_center:
			_register_protected_slot(slot_tag, slot_node)


func _register_slot(slot_tag: StringName, slot_node: Control, max_children := -1) -> void:
	var existing_slot := get_slot(slot_tag)
	if existing_slot:
		assert(false, "Slot '%s' already registered in HUD '%s' (node: %s)"
				% [slot_tag, name, get_path_to(existing_slot.node)])
		return
	
	_slots[slot_tag] = AttachmentSlot.new(slot_tag, slot_node, max_children)


func _register_protected_slot(slot_tag: StringName, slot_node: Control) -> void:
	if not _validate_protected_slot_structure(slot_tag):
		return
	
	var slot_parent := slot_node.get_parent()
	_protected_center_slots[slot_tag] = slot_parent
	slot_node.resized.connect(_on_protected_slot_resized.bind(slot_tag))
	slot_parent.resized.connect(_on_protected_container_resized.bind(slot_tag))
	
	# Apply initial constraints (deferred to ensure sizing is done)
	_apply_center_protection.call_deferred(slot_tag)


func _apply_center_protection(slot_tag: StringName) -> void:
	if not _validate_protected_slot_structure(slot_tag):
		return
	
	var slot := get_slot(slot_tag)
	var parent := slot.node.get_parent() as BoxContainer
	var children := parent.get_children()
	var left_slot := children[0] as Control
	var center_slot := children[1] as Control
	var right_slot := children[2] as Control
	# Measure widths
	var parent_width := parent.size.x
	var center_width := center_slot.get_combined_minimum_size().x
	var gap := parent.get_theme_constant(&"separation")
	var total_gap := gap * 2 # two gaps between three items
	var remaining_space := parent_width - center_width - total_gap
	var side_width := remaining_space / 2.0
	
	# Apply constraints to both sides
	if left_slot:
		left_slot.custom_minimum_size.x = maxf(0.0, side_width)
		left_slot.size_flags_horizontal = Control.SIZE_FILL
	if right_slot:
		right_slot.custom_minimum_size.x = maxf(0.0, side_width)
		right_slot.size_flags_horizontal = Control.SIZE_FILL
	
	# Center slot doesn't need explicit constraints, it sizes to content
	center_slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func _validate_protected_slot_structure(slot_tag: StringName) -> bool:
	var slot := get_slot(slot_tag)
	if not slot:
		return false
	var parent := slot.node.get_parent()
	if parent is not BoxContainer:
		push_error("Parent of protected slot '%s' is not a BoxContainer" % slot_tag)
		return false
	var children := parent.get_children()
	if children.size() != 3:
		push_error("Parent of protected slot '%s' has %d children (should have 3)" % [slot_tag, children.size()])
		return false
	var slot_index := slot.node.get_index()
	if slot_index != 1:
		push_error("Protected slot '%s' is at index %d (should be 1)" % [slot_tag, slot_index])
		return false
	
	return true


func _refresh_protection_for_container(container: Node) -> void:
	for slot_tag: StringName in _protected_center_slots.keys():
		var slot := get_slot(slot_tag)
		if slot.node.get_parent() == container:
			_apply_center_protection(slot_tag)
			return


func _calculate_insert_index(container: Node, priority: int) -> int:
	for i in range(container.get_child_count()):
		var child_priority := _get_ui_priority(container.get_child(i))
		if priority > child_priority:
			return i
	return -1


func _get_ui_priority(ui: Control) -> int:
	return _priorities_by_ui.get(ui, 0)


func _debug_print_slots() -> void:
	print("%s slots" % name)
	for slot_tag in _slots.keys():
		var slot := get_slot(slot_tag)
		var max_space_str: String = ""
		if slot.max_children == -1:
			max_space_str = "unlimited"
		else:
			max_space_str = "%s" % slot.max_children
		print("- ")
		print(slot_tag)
		print("(%s) [usage: %s/%s]" % [get_path_to(slot.node), slot.get_space_used(), max_space_str])


func _on_ui_tree_exiting(ui: Control) -> void:
	_priorities_by_ui.erase(ui)


func _on_protected_slot_resized(slot_tag: StringName) -> void:
	_apply_center_protection(slot_tag)


func _on_protected_container_resized(slot_tag: StringName) -> void:
	_apply_center_protection(slot_tag)


class AttachmentSlot:
	var tag: StringName
	var node: Control
	var max_children: int
	
	
	func _init(tag_: StringName, node_: Control, max_children_: int) -> void:
		tag = tag_
		node = node_
		max_children = max_children_
	
	
	func get_space_available() -> int:
		return max_children - node.get_child_count()
	
	
	func get_space_used() -> int:
		return node.get_child_count()
	
	
	func has_space() -> bool:
		if max_children == -1:
			return true
		return get_space_available() > 0
	
	
	func get_children() -> Array:
		return node.get_children()
