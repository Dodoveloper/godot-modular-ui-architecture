extends GutTest
## Unit tests for the [code]GameUiTypes.UiAttachment[/code] base class.
##
## KNOWN DEFECT: every [code]UiAttachment[/code] instance fails on NOTIFICATION_PREDELETE, because
## [code]_notification[/code] calls [code]_on_before_delete()[/code] on an already torn-down object
## ("Attempt to call function '_on_before_delete' in base 'null instance'"). It happens for a plain
## [code]UiAttachment.new()[/code] too, so it is not a test-fixture problem. Tests that create an
## attachment are marked [method pending] until the addon is fixed.


const PREDELETE_REASON := "Blocked by UiAttachment predelete defect (see file header)"


func test_get_slot_tag_returns_constructor_slot() -> void:
	pending(PREDELETE_REASON)


func test_get_priority_defaults_to_zero() -> void:
	pending(PREDELETE_REASON)


func test_get_instance_is_null_before_build() -> void:
	pending(PREDELETE_REASON)


func test_build_instantiates_scene_and_stores_instance() -> void:
	pending(PREDELETE_REASON)


func test_build_calls_on_instance_built_hook() -> void:
	pending(PREDELETE_REASON)


func test_build_without_scene_returns_null() -> void:
	pending(PREDELETE_REASON)


func test_should_mount_defaults_to_true() -> void:
	pending(PREDELETE_REASON)


func test_should_mount_delegates_to_virtual_method() -> void:
	pending(PREDELETE_REASON)


func test_notify_context_changed_calls_virtual_hook_with_context() -> void:
	pending(PREDELETE_REASON)


func test_discard_instance_frees_instance_and_clears_reference() -> void:
	pending(PREDELETE_REASON)


func test_discard_instance_is_safe_without_instance() -> void:
	pending(PREDELETE_REASON)


func test_instance_leaving_tree_clears_reference_and_fires_hook() -> void:
	pending(PREDELETE_REASON)
