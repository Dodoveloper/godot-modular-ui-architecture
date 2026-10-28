extends GutTest
## Unit tests for GameUiService attachment mounting: mount_attachments() and unmount_attachment().
## Uses real registries and UiLayersService. Slot placement is simulated with a recording Callable,
## which stands in for AttachmentSlotsController.add_to_slot.


const GameUiService = preload("res://addons/modular_ui_architecture/modules/game_ui/services/game_ui.svc.gd")
const UiAttachmentsRegistry = preload("res://addons/modular_ui_architecture/modules/game_ui/registries/ui_attachments.reg.gd")
const ViewsRegistry = preload("res://addons/modular_ui_architecture/modules/game_ui/registries/views.reg.gd")
const UiLayersService = preload("res://addons/modular_ui_architecture/modules/ui_layers/services/ui_layers.svc.gd")
const FakeAttachment = preload("res://tests/fixtures/game_ui/fake_attachment.gd")
const EmptyControlScene = preload("res://tests/fixtures/scenes/empty_control.tscn")

const SLOT := &"bottom_right"

var _ui_layers: UiLayersService
var _attachments: UiAttachmentsRegistry
var _game_ui: GameUiService


func before_each() -> void:
	_ui_layers = UiLayersService.new()
	_ui_layers.enable()
	await wait_process_frames(2)
	_attachments = UiAttachmentsRegistry.new()
	_game_ui = GameUiService.new(_attachments, ViewsRegistry.new(), _ui_layers)


func after_each() -> void:
	_game_ui.disable()
	_ui_layers.disable()
	await wait_process_frames(1)


func _make_host() -> Node:
	var host := Node.new()
	add_child_autofree(host)
	return host


## Returns [code]calls[/code] (an Array of [slot_tag, ui, priority]) and [code]add_to_slot[/code].
## When [param accept] is true, the placed UI is added to [param host], like a real slot would do.
func _recorder(host: Node, accept := true) -> Dictionary:
	var calls := []
	var add_to_slot := func(slot_tag: StringName, ui: Control, priority: int) -> bool:
		calls.append([slot_tag, ui, priority])
		if accept:
			host.add_child(ui)
		return accept
	return {"calls": calls, "add_to_slot": add_to_slot}


func test_mount_attachments_places_built_ui_in_attachment_slot() -> void:
	var attachment := FakeAttachment.new(SLOT, EmptyControlScene)
	_attachments.register_attachment(attachment)
	var host := _make_host()
	var recorder := _recorder(host)

	_game_ui.mount_attachments(host, recorder.add_to_slot)

	assert_eq(recorder.calls.size(), 1)
	assert_eq(recorder.calls[0][0], SLOT)
	assert_same(recorder.calls[0][1], attachment.get_instance())
	assert_eq(attachment.built_count, 1)


func test_mount_attachments_forwards_attachment_priority() -> void:
	var attachment := FakeAttachment.new(SLOT, EmptyControlScene)
	attachment._priority = 7
	_attachments.register_attachment(attachment)
	var host := _make_host()
	var recorder := _recorder(host)

	_game_ui.mount_attachments(host, recorder.add_to_slot)

	assert_eq(recorder.calls[0][2], 7)


func test_mount_attachments_skips_attachment_that_should_not_mount() -> void:
	var attachment := FakeAttachment.new(SLOT, EmptyControlScene)
	attachment.should_mount_result = false
	_attachments.register_attachment(attachment)
	var host := _make_host()
	var recorder := _recorder(host)

	_game_ui.mount_attachments(host, recorder.add_to_slot)

	assert_true(recorder.calls.is_empty())
	assert_eq(attachment.built_count, 0)
	assert_null(attachment.get_instance())


func test_mount_attachments_with_no_registered_attachments_places_nothing() -> void:
	var host := _make_host()
	var recorder := _recorder(host)

	_game_ui.mount_attachments(host, recorder.add_to_slot)

	assert_true(recorder.calls.is_empty())


func test_mount_attachments_discards_ui_when_slot_rejects_placement() -> void:
	var attachment := FakeAttachment.new(SLOT, EmptyControlScene)
	_attachments.register_attachment(attachment)
	var host := _make_host()
	var recorder := _recorder(host, false)

	_game_ui.mount_attachments(host, recorder.add_to_slot)
	assert_push_warning("was not placed")
	await wait_process_frames(1)

	assert_eq(recorder.calls.size(), 1, "The slot was offered the UI")
	assert_null(attachment.get_instance())
	assert_eq(attachment.exited_count, 1, "Teardown runs once for a never-placed instance")
	assert_freed(recorder.calls[0][1])


func test_unmount_attachment_frees_placed_ui() -> void:
	var attachment := FakeAttachment.new(SLOT, EmptyControlScene)
	_attachments.register_attachment(attachment)
	var host := _make_host()
	var recorder := _recorder(host)
	_game_ui.mount_attachments(host, recorder.add_to_slot)
	var ui: Control = recorder.calls[0][1]

	_game_ui.unmount_attachment(attachment)
	await wait_process_frames(2)

	assert_freed(ui)


func test_unmount_attachment_is_noop_for_attachment_never_placed() -> void:
	var attachment := FakeAttachment.new(SLOT, EmptyControlScene)

	_game_ui.unmount_attachment(attachment)

	assert_null(attachment.get_instance())


func test_unmount_attachment_is_noop_after_placed_ui_was_freed_externally() -> void:
	var attachment := FakeAttachment.new(SLOT, EmptyControlScene)
	_attachments.register_attachment(attachment)
	var host := _make_host()
	var recorder := _recorder(host)
	_game_ui.mount_attachments(host, recorder.add_to_slot)
	recorder.calls[0][1].queue_free()
	await wait_process_frames(2)

	_game_ui.unmount_attachment(attachment)

	assert_eq(attachment.exited_count, 1)
