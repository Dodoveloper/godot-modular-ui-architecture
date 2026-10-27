extends GutTest
## Unit tests for [code]GameUiService[/code], backed by real registries and a real
## [code]UiLayersService[/code]. Attachment behaviour is covered elsewhere (see the predelete
## defect noted in test_ui_attachment.gd).


const GameUiTypes = preload("res://addons/modular_ui_architecture/modules/game_ui/types.gd")
const GameUiService = preload("res://addons/modular_ui_architecture/modules/game_ui/services/game_ui.svc.gd")
const ViewsRegistry = preload("res://addons/modular_ui_architecture/modules/game_ui/registries/views.reg.gd")
const UiAttachmentsRegistry = preload("res://addons/modular_ui_architecture/modules/game_ui/registries/ui_attachments.reg.gd")
const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const UiLayersService = preload("res://addons/modular_ui_architecture/modules/ui_layers/services/ui_layers.svc.gd")

const VIEW_SCENE_PATH := "res://tests/fixtures/scenes/empty_control.tscn"
const TOKEN := &"inventory"

var _ui_layers: UiLayersService
var _views: ViewsRegistry
var _game_ui: GameUiService


func before_each() -> void:
	_ui_layers = UiLayersService.new()
	_ui_layers.enable()
	await wait_process_frames(2)
	_views = ViewsRegistry.new()
	_game_ui = GameUiService.new(UiAttachmentsRegistry.new(), _views, _ui_layers)


func after_each() -> void:
	_game_ui.disable()
	_ui_layers.disable()
	await wait_process_frames(1)


func _register_view(token := TOKEN) -> void:
	_views.register_view(GameUiTypes.ViewRegistration.new(token, VIEW_SCENE_PATH))


func test_mount_view_with_unregistered_token_pushes_error_and_returns_null() -> void:
	var view := _game_ui.mount_view(&"does_not_exist")

	assert_null(view)
	assert_push_error("No registered View found for token 'does_not_exist'")


func test_mount_view_mounts_registered_scene() -> void:
	_register_view()

	var view := _game_ui.mount_view(TOKEN)

	assert_not_null(view)
	assert_true(_game_ui.is_view_mounted(TOKEN))
	assert_same(_game_ui.get_view(TOKEN), view)


func test_mount_view_emits_view_mounted_with_token() -> void:
	_register_view()
	watch_signals(_game_ui)

	_game_ui.mount_view(TOKEN)

	assert_signal_emitted_with_parameters(_game_ui, "view_mounted", [TOKEN])


func test_mount_view_places_view_on_requested_layer() -> void:
	_register_view()

	var view := _game_ui.mount_view(TOKEN, UiLayersTypes.UiLayer.WINDOW)

	assert_eq(view.get_parent(), _ui_layers.get_layer_node(UiLayersTypes.UiLayer.WINDOW))


func test_mount_view_twice_pushes_error_and_returns_null() -> void:
	_register_view()
	_game_ui.mount_view(TOKEN)

	var second := _game_ui.mount_view(TOKEN)

	assert_null(second)
	assert_push_error("There is already a mounted View for token 'inventory'")


func test_unmount_view_removes_view_and_tracking() -> void:
	_register_view()
	_game_ui.mount_view(TOKEN)

	var is_success := _game_ui.unmount_view(TOKEN)

	assert_true(is_success)
	assert_false(_game_ui.is_view_mounted(TOKEN))
	assert_null(_game_ui.get_view(TOKEN))


func test_unmount_view_with_unmounted_token_pushes_error_and_returns_false() -> void:
	var is_success := _game_ui.unmount_view(TOKEN)

	assert_false(is_success)
	assert_push_error("No mounted View found for token 'inventory'")


func test_view_can_be_mounted_again_after_unmount() -> void:
	_register_view()
	_game_ui.mount_view(TOKEN)
	_game_ui.unmount_view(TOKEN)

	var view := _game_ui.mount_view(TOKEN)

	assert_not_null(view)
	assert_true(_game_ui.is_view_mounted(TOKEN))


func test_view_freed_outside_of_game_ui_is_untracked() -> void:
	_register_view()
	var view := _game_ui.mount_view(TOKEN)

	view.queue_free()
	await wait_process_frames(2)

	assert_false(_game_ui.is_view_mounted(TOKEN))


func test_mount_world_ui_reparents_control_into_world_container() -> void:
	var anchor := Node2D.new()
	add_child_autofree(anchor)
	var ui := Control.new()

	var mounted := _game_ui.mount_world_ui(ui, anchor, UiLayersTypes.UiLayer.DEFAULT)

	assert_same(mounted, ui)
	assert_eq(ui.get_parent(), _ui_layers.get_world_ui_container(UiLayersTypes.UiLayer.DEFAULT))
	_game_ui.unmount_world_ui(ui)


func test_unmount_world_ui_untracked_node_pushes_error_and_returns_false() -> void:
	var ui := Control.new()
	autofree(ui)

	var is_success := _game_ui.unmount_world_ui(ui)

	assert_false(is_success)
	assert_push_error("is not tracked as world-anchored")


func test_unmount_world_ui_frees_tracked_node() -> void:
	var anchor := Node2D.new()
	add_child_autofree(anchor)
	var ui := Control.new()
	_game_ui.mount_world_ui(ui, anchor, UiLayersTypes.UiLayer.DEFAULT)

	var is_success := _game_ui.unmount_world_ui(ui)
	await wait_process_frames(1)

	assert_true(is_success)
	assert_freed(ui)
