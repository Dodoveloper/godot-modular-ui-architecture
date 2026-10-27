extends GutTest
## Unit tests for [code]UiAttachmentsRegistry[/code].
##
## NOTE: creating a [code]UiAttachment[/code] triggers a predelete defect in the addon (see
## test_ui_attachment.gd), so these tests are marked [method pending] until it is fixed.


const PREDELETE_REASON := "Blocked by UiAttachment predelete defect (see test_ui_attachment.gd)"


func test_get_attachments_is_empty_by_default() -> void:
	var registry := preload("res://addons/modular_ui_architecture/modules/game_ui/registries/ui_attachments.reg.gd").new()
	assert_true(registry.get_attachments().is_empty())


func test_register_attachment_is_returned_by_get_attachments() -> void:
	pending(PREDELETE_REASON)


func test_registering_same_attachment_twice_keeps_one_entry() -> void:
	pending(PREDELETE_REASON)


func test_unregister_attachment_removes_it() -> void:
	pending(PREDELETE_REASON)


func test_unregister_unknown_attachment_is_a_no_op() -> void:
	pending(PREDELETE_REASON)
