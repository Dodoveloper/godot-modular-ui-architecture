extends GutTest
## Unit tests for View context polling in GameUiService. Attachments are mounted through the public
## mount_attachments() path. Polling is driven by calling _on_scene_tree_physics_frame() directly,
## since physics frames are not stepped in headless unit tests.


const GameUiTypes = preload("res://addons/modular_ui_architecture/modules/game_ui/types.gd")
const GameUiService = preload("res://addons/modular_ui_architecture/modules/game_ui/services/game_ui.svc.gd")
const UiAttachmentsRegistry = preload("res://addons/modular_ui_architecture/modules/game_ui/registries/ui_attachments.reg.gd")
const ViewsRegistry = preload("res://addons/modular_ui_architecture/modules/game_ui/registries/views.reg.gd")
const UiLayersService = preload("res://addons/modular_ui_architecture/modules/ui_layers/services/ui_layers.svc.gd")
const FakeAttachment = preload("res://tests/fixtures/game_ui/fake_attachment.gd")
const ContextView = preload("res://tests/fixtures/game_ui/context_view.gd")
const EmptyControlScene = preload("res://tests/fixtures/scenes/empty_control.tscn")

const VIEW_SCENE_PATH := "res://tests/fixtures/game_ui/context_view.tscn"
const TOKEN := &"context_view"
const OTHER_TOKEN := &"other_view"
const SLOT := &"bottom_right"

var _ui_layers: UiLayersService
var _attachments: UiAttachmentsRegistry
var _views: ViewsRegistry
var _game_ui: GameUiService


func before_each() -> void:
	_ui_layers = UiLayersService.new()
	_ui_layers.enable()
	await wait_process_frames(2)
	_attachments = UiAttachmentsRegistry.new()
	_views = ViewsRegistry.new()
	_game_ui = GameUiService.new(_attachments, _views, _ui_layers)
	_views.register_view(GameUiTypes.ViewRegistration.new(TOKEN, VIEW_SCENE_PATH))
	_views.register_view(GameUiTypes.ViewRegistration.new(OTHER_TOKEN, VIEW_SCENE_PATH))


func after_each() -> void:
	_game_ui.disable()
	_ui_layers.disable()
	await wait_process_frames(1)


## Accepts every placement and keeps the UI alive in the tree, like a real slot would.
func _accept_into(host: Node) -> Callable:
	return func(_slot_tag: StringName, ui: Control, _priority: int) -> bool:
		if not ui:
			return false
		host.add_child(ui)
		return true


## Mounts [param token] with a context-holding View and mounts a registered attachment onto it.
## Returns [view, attachment].
func _mount_view_with_attachment(token: StringName) -> Array:
	var view: ContextView = _game_ui.mount_view(token)
	var attachment := FakeAttachment.new(SLOT, EmptyControlScene)
	_attachments.register_attachment(attachment)
	var host := Node.new()
	add_child_autofree(host)
	_game_ui.mount_attachments(view, _accept_into(host))
	return [view, attachment]


func test_poll_without_context_does_not_notify() -> void:
	var pair := _mount_view_with_attachment(TOKEN)
	var attachment: FakeAttachment = pair[1]

	_game_ui._on_scene_tree_physics_frame()

	assert_null(attachment.last_context)


func test_poll_with_unchanged_context_does_not_notify() -> void:
	var pair := _mount_view_with_attachment(TOKEN)
	var view: ContextView = pair[0]
	var attachment: FakeAttachment = pair[1]
	view.context = ContextView.Context.new()
	_game_ui._on_scene_tree_physics_frame()
	attachment.last_context = null

	_game_ui._on_scene_tree_physics_frame()

	assert_null(attachment.last_context, "No change, so no notification")


func test_poll_with_changed_context_notifies_that_views_attachments() -> void:
	var pair := _mount_view_with_attachment(TOKEN)
	var view: ContextView = pair[0]
	var attachment: FakeAttachment = pair[1]
	view.context = ContextView.Context.new()
	_game_ui._on_scene_tree_physics_frame()
	attachment.last_context = null

	view.context.value = 42
	_game_ui._on_scene_tree_physics_frame()

	assert_same(attachment.last_context, view.context)


func test_poll_does_not_notify_attachments_of_other_views() -> void:
	var pair := _mount_view_with_attachment(TOKEN)
	var view: ContextView = pair[0]
	var other_pair := _mount_view_with_attachment(OTHER_TOKEN)
	var other_attachment: FakeAttachment = other_pair[1]
	view.context = ContextView.Context.new()
	_game_ui._on_scene_tree_physics_frame()
	other_attachment.last_context = null

	view.context.value = 42
	_game_ui._on_scene_tree_physics_frame()

	assert_null(other_attachment.last_context)


func test_poll_caches_new_values_so_a_second_identical_poll_is_silent() -> void:
	var pair := _mount_view_with_attachment(TOKEN)
	var view: ContextView = pair[0]
	var attachment: FakeAttachment = pair[1]
	view.context = ContextView.Context.new()
	view.context.value = 1
	_game_ui._on_scene_tree_physics_frame()

	view.context.value = 2
	_game_ui._on_scene_tree_physics_frame()
	attachment.last_context = null
	_game_ui._on_scene_tree_physics_frame()

	assert_null(attachment.last_context)


func test_unmounting_view_stops_polling_it() -> void:
	var pair := _mount_view_with_attachment(TOKEN)
	var view: ContextView = pair[0]
	var attachment: FakeAttachment = pair[1]
	view.context = ContextView.Context.new()
	_game_ui._on_scene_tree_physics_frame()
	attachment.last_context = null
	# Keep a reference to the context: the View is freed on unmount, so it must not be read after.
	var context: ContextView.Context = view.context
	_game_ui.unmount_view(TOKEN)
	await wait_process_frames(1)

	context.value = 42
	_game_ui._on_scene_tree_physics_frame()

	assert_null(attachment.last_context)


func test_enable_connects_and_disable_disconnects_physics_polling() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	_game_ui.disable()
	assert_false(tree.physics_frame.is_connected(_game_ui._on_scene_tree_physics_frame))

	_game_ui.enable()
	assert_true(tree.physics_frame.is_connected(_game_ui._on_scene_tree_physics_frame))

	_game_ui.disable()
	assert_false(tree.physics_frame.is_connected(_game_ui._on_scene_tree_physics_frame))
