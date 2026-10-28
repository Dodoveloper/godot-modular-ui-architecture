extends GutTest
## Unit tests for ViewRequester: mount/unmount through a real GameUiService.
##
## The node is never added to the tree, so _enter_tree() (which awaits the Godular module graph)
## does not run. _svc_game_ui is assigned directly, as the graph would do.


const GameUiTypes = preload("res://addons/modular_ui_architecture/modules/game_ui/types.gd")
const GameUiService = preload("res://addons/modular_ui_architecture/modules/game_ui/services/game_ui.svc.gd")
const UiAttachmentsRegistry = preload("res://addons/modular_ui_architecture/modules/game_ui/registries/ui_attachments.reg.gd")
const ViewsRegistry = preload("res://addons/modular_ui_architecture/modules/game_ui/registries/views.reg.gd")
const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const UiLayersService = preload("res://addons/modular_ui_architecture/modules/ui_layers/services/ui_layers.svc.gd")
const ViewRequester = preload("res://addons/modular_ui_architecture/shared/classes/view_requester/view_requester.gd")

const VIEW_SCENE_PATH := "res://tests/fixtures/scenes/empty_control.tscn"
const TOKEN := &"inventory"

var _ui_layers: UiLayersService
var _views: ViewsRegistry
var _game_ui: GameUiService
var _requester: ViewRequester


func before_each() -> void:
	_ui_layers = UiLayersService.new()
	_ui_layers.enable()
	await wait_process_frames(2)
	_views = ViewsRegistry.new()
	_game_ui = GameUiService.new(UiAttachmentsRegistry.new(), _views, _ui_layers)
	_views.register_view(GameUiTypes.ViewRegistration.new(TOKEN, VIEW_SCENE_PATH))
	_requester = ViewRequester.new()
	autofree(_requester)
	_requester.token = TOKEN
	_requester.layer = UiLayersTypes.UiLayer.DEFAULT
	# Stands in for the service the module graph would inject in _enter_tree().
	_requester._svc_game_ui = _game_ui


func after_each() -> void:
	_game_ui.disable()
	_ui_layers.disable()
	await wait_process_frames(1)


func test_mount_view_mounts_registered_view_and_emits_signal() -> void:
	watch_signals(_requester)

	var view := _requester.mount_view()

	assert_not_null(view)
	assert_same(_requester.view_instance, view)
	assert_true(_game_ui.is_view_mounted(TOKEN))
	assert_signal_emitted(_requester, "view_mounted")


func test_mount_view_reuses_existing_view_without_emitting_again() -> void:
	var first := _requester.mount_view()
	watch_signals(_requester)

	var second := _requester.mount_view()

	assert_same(second, first)
	assert_signal_not_emitted(_requester, "view_mounted")


func test_mount_view_with_unregistered_token_warns_and_returns_null() -> void:
	_requester.token = &"does_not_exist"

	var view := _requester.mount_view()

	assert_null(view)
	assert_null(_requester.view_instance)
	assert_push_error("No registered View found for token 'does_not_exist'")
	assert_push_warning("could not mount on layer")


func test_unmount_view_unmounts_and_clears_instance() -> void:
	_requester.mount_view()

	_requester.unmount_view()

	assert_false(_game_ui.is_view_mounted(TOKEN))
	assert_null(_requester.view_instance)


func test_unmount_view_without_mounted_view_is_a_silent_no_op() -> void:
	_requester.unmount_view()

	assert_null(_requester.view_instance)
	assert_push_error_count(0)
