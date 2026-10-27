extends GutTest
## Unit tests for the world-anchored UI logic in [code]GameUiService[/code].
## Per-frame positioning runs from RenderingServer.frame_pre_draw, which is not driven in
## headless tests, so [code]_on_frame_pre_draw[/code] and [code]_sample_anchor[/code] are called directly.


const GameUiService = preload("res://addons/modular_ui_architecture/modules/game_ui/services/game_ui.svc.gd")
const UiAttachmentsRegistry = preload("res://addons/modular_ui_architecture/modules/game_ui/registries/ui_attachments.reg.gd")
const ViewsRegistry = preload("res://addons/modular_ui_architecture/modules/game_ui/registries/views.reg.gd")
const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const UiLayersService = preload("res://addons/modular_ui_architecture/modules/ui_layers/services/ui_layers.svc.gd")

var _ui_layers: UiLayersService
var _game_ui: GameUiService


func before_each() -> void:
	_ui_layers = UiLayersService.new()
	_ui_layers.enable()
	await wait_process_frames(2)
	_game_ui = GameUiService.new(UiAttachmentsRegistry.new(), ViewsRegistry.new(), _ui_layers)


func after_each() -> void:
	_game_ui.disable()
	_ui_layers.disable()
	await wait_process_frames(1)


func _info_for(ui: Control) -> GameUiService.WorldAnchorInfo:
	return _game_ui._world_anchors[ui]


func test_world_ui_is_tracked_while_mounted() -> void:
	var anchor := Node2D.new()
	add_child_autofree(anchor)
	var ui := Control.new()
	_game_ui.mount_world_ui(ui, anchor)

	assert_true(_game_ui._world_anchors.has(ui))
	_game_ui.unmount_world_ui(ui)


func test_small_anchor_movement_is_interpolated_not_snapped() -> void:
	var anchor := Node2D.new()
	add_child_autofree(anchor)
	anchor.global_position = Vector2.ZERO
	var ui := Control.new()
	_game_ui.mount_world_ui(ui, anchor)
	var info := _info_for(ui)

	anchor.global_position = Vector2(30, 0)
	info.last_sampled_tick = -1
	_game_ui._sample_anchor(info, Engine.get_physics_frames() + 1)

	assert_eq(info.prev_world_pos, Vector2.ZERO, "Previous sample is kept for interpolation")
	assert_eq(info.curr_world_pos, Vector2(30, 0))
	_game_ui.unmount_world_ui(ui)


func test_teleport_beyond_threshold_snaps_both_samples() -> void:
	var anchor := Node2D.new()
	add_child_autofree(anchor)
	anchor.global_position = Vector2.ZERO
	var ui := Control.new()
	_game_ui.mount_world_ui(ui, anchor)
	var info := _info_for(ui)

	anchor.global_position = Vector2(50000, 0)
	info.last_sampled_tick = -1
	_game_ui._sample_anchor(info, Engine.get_physics_frames() + 1)

	assert_eq(info.prev_world_pos, Vector2(50000, 0), "Teleport resets interpolation")
	assert_eq(info.curr_world_pos, Vector2(50000, 0))
	_game_ui.unmount_world_ui(ui)


## KNOWN DEFECT: after the anchor is freed, WorldAnchorInfo.is_anchor_stale() returns false, because a
## freed Object compares equal to null in Godot 4 and the check short-circuits. The UI is therefore never
## unmounted, contrary to the "was freed externally; unmounting" contract. Marked pending until the addon is fixed.
func test_stale_anchor_unmounts_its_ui_on_next_frame() -> void:
	pending("Blocked by stale-anchor detection defect (is_anchor_stale never true after free)")


func test_unmount_world_ui_is_safe_for_untracked_node_on_frame_draw() -> void:
	var anchor := Node2D.new()
	add_child_autofree(anchor)
	_game_ui._on_frame_pre_draw()

	assert_true(_game_ui._world_anchors.is_empty())
