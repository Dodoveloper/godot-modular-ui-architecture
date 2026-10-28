extends GutTest
## Unit tests for AttachmentSlotsController: slot registration, capacity, priority ordering,
## priority cleanup, and protected-center validation and layout.
##
## The controller is never added to the tree. Its _enter_tree() waits for the Godular module graph,
## which these tests do not start. Slots are configured and registered through _initialize_slots(),
## exactly as _ready() does, and slot nodes are children of the controller so node paths resolve.


const AttachmentSlotsController = preload("res://addons/modular_ui_architecture/shared/classes/attachment_slots_controller/attachment_slots_controller.gd")

var _controller: AttachmentSlotsController


func before_each() -> void:
	_controller = AttachmentSlotsController.new()
	autofree(_controller)


## Adds a plain Control named [param node_name] under [param parent] (default: the controller).
func _make_control(node_name: String, parent: Node = null) -> Control:
	var control := Control.new()
	control.name = node_name
	(parent if parent else _controller).add_child(control)
	return control


## Configures [param tag] to point at [param node_path] and initializes the controller.
func _setup_slot(tag: StringName, node_path: String, max_children := -1, protected := false) -> void:
	var config := AttachmentSlotConfig.new(NodePath(node_path), max_children)
	config.protected_center = protected
	_controller.slot_configs[tag] = config
	_controller._initialize_slots()


## Builds a plain Control holding one slot node, and registers that slot as [param tag].
func _setup_plain_slot(tag: StringName, max_children := -1) -> Control:
	var box := _make_control("Box")
	var slot_node := _make_control(String(tag), box)
	_setup_slot(tag, "Box/%s" % tag, max_children)
	return slot_node


func test_unknown_slot_tag_is_not_registered() -> void:
	assert_false(_controller.has_slot(&"missing"))
	assert_null(_controller.get_slot(&"missing"))


func test_initialize_registers_configured_slot_with_its_node_and_capacity() -> void:
	var slot_node := _setup_plain_slot(&"top", 2)

	assert_true(_controller.has_slot(&"top"))
	assert_same(_controller.get_slot(&"top").node, slot_node)
	assert_eq(_controller.get_slot(&"top").max_children, 2)


func test_duplicate_slot_registration_asserts_and_keeps_the_first_slot() -> void:
	var first := _make_control("First")
	var second := _make_control("Second")
	_controller._register_slot(&"top", first, -1)

	_controller._register_slot(&"top", second, -1)

	assert_engine_error("already registered")
	assert_same(_controller.get_slot(&"top").node, first)


func test_add_to_missing_slot_warns_and_does_not_place_ui() -> void:
	var ui := Control.new()
	autofree(ui)

	var is_placed := _controller.add_to_slot(&"missing", ui)

	assert_false(is_placed)
	assert_push_warning("not found")
	assert_null(ui.get_parent())


func test_add_to_full_slot_is_rejected_and_ui_is_not_placed() -> void:
	var slot_node := _setup_plain_slot(&"top", 1)
	var first := Control.new()
	var second := Control.new()
	autofree(first)
	autofree(second)
	_controller.add_to_slot(&"top", first)

	var is_placed := _controller.add_to_slot(&"top", second)

	assert_false(is_placed)
	assert_push_error("does not have space left")
	assert_eq(slot_node.get_child_count(), 1)
	assert_null(second.get_parent())


func test_add_to_unlimited_slot_accepts_every_ui() -> void:
	var slot_node := _setup_plain_slot(&"top", -1)
	for i in range(3):
		var ui := Control.new()
		autofree(ui)
		assert_true(_controller.add_to_slot(&"top", ui))

	assert_eq(slot_node.get_child_count(), 3)


func test_higher_priority_ui_is_inserted_before_lower_priority_siblings() -> void:
	var slot_node := _setup_plain_slot(&"top")
	var low := Control.new()
	var high := Control.new()
	autofree(low)
	autofree(high)
	_controller.add_to_slot(&"top", low, 0)

	_controller.add_to_slot(&"top", high, 5)

	assert_eq(slot_node.get_child(0), high)
	assert_eq(slot_node.get_child(1), low)


func test_equal_priority_keeps_arrival_order_among_mixed_priorities() -> void:
	var slot_node := _setup_plain_slot(&"top")
	var first := Control.new()
	var second := Control.new()
	var low := Control.new()
	autofree(first)
	autofree(second)
	autofree(low)
	_controller.add_to_slot(&"top", first, 5)
	_controller.add_to_slot(&"top", low, 0)

	_controller.add_to_slot(&"top", second, 5)

	assert_eq(slot_node.get_child(0), first)
	assert_eq(slot_node.get_child(1), second)
	assert_eq(slot_node.get_child(2), low)


func test_tree_exiting_handler_drops_stored_priority() -> void:
	_setup_plain_slot(&"top")
	var ui := Control.new()
	autofree(ui)
	_controller.add_to_slot(&"top", ui, 3)
	assert_true(_controller._priorities_by_ui.has(ui))

	# An out-of-tree Control never emits tree_exiting, so the handler is called directly.
	_controller._on_ui_tree_exiting(ui)

	assert_false(_controller._priorities_by_ui.has(ui))


func test_protected_slot_on_non_box_container_pushes_error() -> void:
	var row := _make_control("Row")
	_make_control("Left", row)
	_make_control("Center", row)
	_make_control("Right", row)

	_setup_slot(&"center", "Row/Center", -1, true)

	assert_push_error("is not a BoxContainer")


func test_protected_slot_with_wrong_child_count_pushes_error() -> void:
	var row := HBoxContainer.new()
	row.name = "Row"
	_controller.add_child(row)
	_make_control("Center", row)
	_make_control("Right", row)

	_setup_slot(&"center", "Row/Center", -1, true)

	assert_push_error("has 2 children (should have 3)")


func test_protected_slot_not_at_index_one_pushes_error() -> void:
	var row := HBoxContainer.new()
	row.name = "Row"
	_controller.add_child(row)
	_make_control("Center", row)
	_make_control("Left", row)
	_make_control("Right", row)

	_setup_slot(&"center", "Row/Center", -1, true)

	assert_push_error("is at index 0 (should be 1)")


func test_protected_center_gives_side_slots_equal_widths_and_shrinks_center() -> void:
	var row := HBoxContainer.new()
	row.name = "Row"
	_controller.add_child(row)
	var left := _make_control("Left", row)
	var center := _make_control("Center", row)
	var right := _make_control("Right", row)
	center.custom_minimum_size = Vector2(100, 0)
	row.size = Vector2(600, 40)

	_setup_slot(&"center", "Row/Center", -1, true)
	# _initialize_slots() defers the first apply, so run it now on the known sizes.
	_controller._apply_center_protection(&"center")

	var gap := row.get_theme_constant(&"separation")
	var expected_side := (600.0 - 100.0 - 2.0 * gap) / 2.0
	assert_almost_eq(left.custom_minimum_size.x, expected_side, 0.01)
	assert_almost_eq(right.custom_minimum_size.x, expected_side, 0.01)
	assert_eq(left.size_flags_horizontal, Control.SIZE_FILL)
	assert_eq(right.size_flags_horizontal, Control.SIZE_FILL)
	assert_eq(center.size_flags_horizontal, Control.SIZE_SHRINK_CENTER)
