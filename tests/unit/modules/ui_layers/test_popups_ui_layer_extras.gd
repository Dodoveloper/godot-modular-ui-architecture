extends GutTest
## Extra coverage for PopupsUiLayer: partial close-transition contract, can_close_popup veto,
## close_requested, close_topmost_popup forwarding, the close-transition timeout, and the queue.
##
## Popups with extra behaviour (a veto, a close_requested signal, a half-implemented transition) are
## built from inline GDScript, so no extra fixture files are needed. They are mounted through
## _mount_node(), the layer's own mount override, because mount_ui() needs a scene on disk.


const PopupTypes = preload("res://addons/modular_ui_architecture/modules/popups/types.gd")
const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const UiLayersService = preload("res://addons/modular_ui_architecture/modules/ui_layers/services/ui_layers.svc.gd")
const PopupsService = preload("res://addons/modular_ui_architecture/modules/popups/services/popups.svc.gd")

const SCENE_PATH := "res://tests/fixtures/scenes/empty_control.tscn"
const TRANSITION_SCENE_PATH := "res://tests/fixtures/scenes/transition_popup.tscn"
const MISSING_SCENE_PATH := "res://tests/fixtures/scenes/does_not_exist.tscn"
const POPUP_LAYER := UiLayersTypes.UiLayer.POPUP

var _ui_layers: UiLayersService
var _popups: PopupsService
var _layer: Node


func before_each() -> void:
	_ui_layers = UiLayersService.new()
	_ui_layers.enable()
	await wait_process_frames(2)
	_popups = PopupsService.new(_ui_layers)
	_layer = _ui_layers.get_layer_node(POPUP_LAYER)


func after_each() -> void:
	_popups.disable()
	_ui_layers.disable()
	await wait_process_frames(1)


## Builds a Control with the given inline script source.
func _make_popup(source: String) -> Control:
	var script := GDScript.new()
	script.source_code = source
	script.reload()
	var popup := Control.new()
	popup.set_script(script)
	return popup


## Callable that tags the popup it receives, so tests can tell queued popups apart.
func _tagger(label: String) -> Callable:
	return func(popup: Control) -> void:
		popup.set_meta(&"tag", label)


func _queued_tags() -> Array:
	return _layer.get_mounted_nodes().map(func(p: Node): return p.get_meta(&"tag", ""))


func test_half_implemented_close_transition_warns_and_still_mounts() -> void:
	var popup := _make_popup("extends Control\nfunc begin_close_transition(_reason: int) -> void:\n\tpass\n")

	var mounted: Node = _layer._mount_node(popup)

	assert_not_null(mounted)
	assert_push_warning("partially implements the close transition API")
	assert_true(_layer.get_mounted_nodes().has(popup))


func test_can_close_popup_veto_keeps_popup_mounted() -> void:
	var popup := _make_popup("extends Control\nfunc can_close_popup() -> bool:\n\treturn false\n")
	_layer._mount_node(popup)

	var is_closed: bool = _layer.unmount_node(popup)

	assert_false(is_closed)
	assert_true(_layer.get_mounted_nodes().has(popup))


func test_close_requested_from_popup_closes_it() -> void:
	var popup := _make_popup("extends Control\nsignal close_requested\n")
	_layer._mount_node(popup)

	popup.close_requested.emit()
	await wait_process_frames(2)

	assert_false(_layer.has_popups())


func test_close_topmost_passes_reason_to_transition_popup() -> void:
	var popup: Control = _ui_layers.mount_ui(TRANSITION_SCENE_PATH, POPUP_LAYER)

	_popups.close_topmost_popup(PopupTypes.CloseReason.UI_CANCEL)

	assert_eq(popup.begin_close_count, 1)
	assert_eq(popup.last_close_reason, PopupTypes.CloseReason.UI_CANCEL)


func test_close_topmost_with_nothing_open_pushes_error() -> void:
	_popups.close_topmost_popup()

	assert_push_error("There are no popups to be closed")


func test_timeout_on_open_popup_warns_and_force_closes() -> void:
	var popup: Control = _ui_layers.mount_ui(SCENE_PATH, POPUP_LAYER)

	_layer._on_close_transition_timeout(popup)

	assert_push_warning("close transition timed out")
	assert_false(_layer.has_popups())


func test_timeout_on_popup_that_is_not_tracked_is_a_silent_no_op() -> void:
	var stranger := Control.new()
	autofree(stranger)

	_layer._on_close_transition_timeout(stranger)

	assert_push_warning_count(0)
	assert_false(_layer.has_popups())


func test_queue_opens_popups_one_at_a_time_in_fifo_order() -> void:
	_popups.open_popup_queued(SCENE_PATH, Color.BLACK, _tagger("A"))
	_popups.open_popup_queued(SCENE_PATH, Color.BLACK, _tagger("B"))
	_popups.open_popup_queued(SCENE_PATH, Color.BLACK, _tagger("C"))
	assert_eq(_queued_tags(), ["A"], "Only the first request is open")

	_layer.unmount_node(_layer.get_mounted_nodes()[0])
	await wait_process_frames(2)
	assert_eq(_queued_tags(), ["B"])

	_layer.unmount_node(_layer.get_mounted_nodes()[0])
	await wait_process_frames(2)
	assert_eq(_queued_tags(), ["C"])


func test_queued_popup_is_mounted_as_blocking() -> void:
	_popups.open_popup_queued(SCENE_PATH)
	var active: Control = _layer.get_mounted_nodes()[0]

	assert_true(_layer._popups[active].is_blocking)


func test_queue_skips_request_whose_scene_cannot_be_loaded() -> void:
	_popups.open_popup_queued(SCENE_PATH, Color.BLACK, _tagger("A"))
	_popups.open_popup_queued(MISSING_SCENE_PATH, Color.BLACK, _tagger("bad"))
	_popups.open_popup_queued(SCENE_PATH, Color.BLACK, _tagger("C"))

	_layer.unmount_node(_layer.get_mounted_nodes()[0])
	await wait_process_frames(2)

	assert_engine_error_count(2)
	assert_push_error("failed to load resource")
	assert_eq(_queued_tags(), ["C"], "The failed request does not stall the queue")


func test_closing_parent_also_closes_non_blocking_child() -> void:
	var parent := Control.new()
	_layer._mount_node(parent)
	var child := Control.new()
	_layer._mount_node(child, {&"parent": parent, &"is_blocking": false} as Dictionary[StringName, Variant])

	var is_closed: bool = _layer.unmount_node(parent)
	await wait_process_frames(2)

	assert_true(is_closed)
	assert_false(_layer.has_popups())
	assert_false(is_instance_valid(child))


## NOTE: reads the private _popups map, because PopupInfo.children has no public accessor.
func test_closing_child_detaches_it_from_its_parent() -> void:
	var parent := Control.new()
	_layer._mount_node(parent)
	var child := Control.new()
	_layer._mount_node(child, {&"parent": parent, &"is_blocking": false} as Dictionary[StringName, Variant])

	_layer.unmount_node(child)
	await wait_process_frames(2)

	assert_true(_layer.get_mounted_nodes().has(parent))
	# The child is freed by now, so a typed Array[Control].has() on it is rejected. Count the
	# remaining valid children instead.
	var live_children: Array = _layer._popups[parent].children.filter(func(c: Control): return is_instance_valid(c))
	assert_eq(live_children.size(), 0)
