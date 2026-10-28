extends GutTest
## Unit tests for the teardown contract of [code]UiAttachment.discard_instance()[/code].
## The attachment's tree-exiting hook must run on every discard path, exactly once.


const FakeAttachment = preload("res://tests/fixtures/game_ui/fake_attachment.gd")
const EmptyControlScene = preload("res://tests/fixtures/scenes/empty_control.tscn")

const SLOT := &"bottom_right"


func test_discard_of_never_placed_instance_runs_exiting_hook_once() -> void:
	var attachment := FakeAttachment.new(SLOT, EmptyControlScene)
	var host := Node.new()
	autofree(host)
	attachment.build(host, null)

	attachment.discard_instance()
	await wait_process_frames(1)

	assert_eq(attachment.exited_count, 1)
	assert_null(attachment.get_instance())


func test_discard_of_placed_instance_does_not_run_exiting_hook_twice() -> void:
	var attachment := FakeAttachment.new(SLOT, EmptyControlScene)
	var host := Node.new()
	add_child_autofree(host)
	var instance := attachment.build(host, null)
	host.add_child(instance)

	attachment.discard_instance()
	await wait_process_frames(2)

	assert_eq(attachment.exited_count, 1)
	assert_null(attachment.get_instance())


func test_discard_without_instance_does_not_run_exiting_hook() -> void:
	var attachment := FakeAttachment.new(SLOT, EmptyControlScene)

	attachment.discard_instance()

	assert_eq(attachment.exited_count, 0)
