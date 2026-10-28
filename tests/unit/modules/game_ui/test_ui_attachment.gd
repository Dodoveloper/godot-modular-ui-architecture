extends GutTest
## Unit tests for the [code]GameUiTypes.UiAttachment[/code] base class.
##
## The predelete destructor is covered by test_discard_on_predelete_frees_instance; the rest use a
## local subclass so the lifecycle hooks can be observed.


const GameUiTypes = preload("res://addons/modular_ui_architecture/modules/game_ui/types.gd")
const FakeAttachment = preload("res://tests/fixtures/game_ui/fake_attachment.gd")
const EmptyControlScene = preload("res://tests/fixtures/scenes/empty_control.tscn")

const SLOT := &"bottom_right"

var _attachment: FakeAttachment


func before_each() -> void:
	_attachment = FakeAttachment.new(SLOT, EmptyControlScene)


func test_get_slot_tag_returns_constructor_slot() -> void:
	assert_eq(_attachment.get_slot_tag(), SLOT)


func test_get_priority_defaults_to_zero() -> void:
	assert_eq(_attachment.get_priority(), 0)


func test_get_instance_is_null_before_build() -> void:
	assert_null(_attachment.get_instance())


func test_build_instantiates_scene_and_stores_instance() -> void:
	var host := Node.new()
	autofree(host)

	var instance := _attachment.build(host, null)

	assert_not_null(instance)
	assert_is(instance, Control)
	assert_same(_attachment.get_instance(), instance)
	_attachment.discard_instance()


func test_build_calls_on_instance_built_hook() -> void:
	var host := Node.new()
	autofree(host)

	_attachment.build(host, null)

	assert_eq(_attachment.built_count, 1)
	_attachment.discard_instance()


func test_build_without_scene_returns_null() -> void:
	var attachment := FakeAttachment.new(SLOT, null)
	var host := Node.new()
	autofree(host)

	var instance := attachment.build(host, null)

	# _build() calls assert(false) first, which GUT records as an engine error.
	assert_null(instance)
	assert_engine_error("No scene provided")


func test_should_mount_defaults_to_true() -> void:
	var attachment := GameUiTypes.UiAttachment.new(SLOT, EmptyControlScene)
	var host := Node.new()
	autofree(host)

	assert_true(attachment.should_mount(host, null))


func test_should_mount_delegates_to_virtual_method() -> void:
	_attachment.should_mount_result = false
	var host := Node.new()
	autofree(host)

	assert_false(_attachment.should_mount(host, null))


func test_notify_context_changed_calls_virtual_hook_with_context() -> void:
	var context := RefCounted.new()

	_attachment.notify_context_changed(context)

	assert_same(_attachment.last_context, context)


func test_discard_instance_frees_instance_and_clears_reference() -> void:
	var host := Node.new()
	autofree(host)
	var instance := _attachment.build(host, null)

	_attachment.discard_instance()

	assert_null(_attachment.get_instance())
	# discard_instance() uses queue_free(), so the instance is freed at the end of the frame.
	await wait_process_frames(1)
	assert_freed(instance)


func test_discard_instance_is_safe_without_instance() -> void:
	_attachment.discard_instance()

	assert_null(_attachment.get_instance())


func test_discard_on_predelete_frees_instance() -> void:
	var host := Node.new()
	autofree(host)
	var attachment := FakeAttachment.new(SLOT, EmptyControlScene)
	var instance := attachment.build(host, null)

	attachment = null
	await wait_process_frames(1)

	assert_freed(instance)

func test_instance_leaving_tree_clears_reference_and_fires_hook() -> void:
	var host := Node.new()
	add_child_autofree(host)
	var instance := _attachment.build(host, null)
	host.add_child(instance)

	instance.queue_free()
	await wait_process_frames(2)

	assert_null(_attachment.get_instance())
	assert_eq(_attachment.exited_count, 1)
