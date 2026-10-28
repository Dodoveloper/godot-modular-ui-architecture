extends GutTest
## Unit tests for [code]UiAttachmentsRegistry[/code].


const GameUiTypes = preload("res://addons/modular_ui_architecture/modules/game_ui/types.gd")
const UiAttachmentsRegistry = preload("res://addons/modular_ui_architecture/modules/game_ui/registries/ui_attachments.reg.gd")

var _registry: UiAttachmentsRegistry


func before_each() -> void:
	_registry = UiAttachmentsRegistry.new()


func test_get_attachments_is_empty_by_default() -> void:
	assert_true(_registry.get_attachments().is_empty())


func test_register_attachment_is_returned_by_get_attachments() -> void:
	var attachment := GameUiTypes.UiAttachment.new(&"bottom_right")

	_registry.register_attachment(attachment)

	assert_eq(_registry.get_attachments(), [attachment])


func test_registering_same_attachment_twice_keeps_one_entry() -> void:
	var attachment := GameUiTypes.UiAttachment.new(&"bottom_right")

	_registry.register_attachment(attachment)
	_registry.register_attachment(attachment)

	assert_eq(_registry.get_attachments().size(), 1)


func test_unregister_attachment_removes_it() -> void:
	var keep := GameUiTypes.UiAttachment.new(&"bottom_right")
	var remove := GameUiTypes.UiAttachment.new(&"top_left")
	_registry.register_attachment(keep)
	_registry.register_attachment(remove)

	_registry.unregister_attachment(remove)

	assert_eq(_registry.get_attachments(), [keep])


func test_unregister_unknown_attachment_pushes_error() -> void:
	var attachment := GameUiTypes.UiAttachment.new(&"bottom_right")

	_registry.unregister_attachment(attachment)

	assert_push_error("Attachment is not registered")
	assert_true(_registry.get_attachments().is_empty())
