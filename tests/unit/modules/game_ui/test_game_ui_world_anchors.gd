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


func test_stale_anchor_unmounts_its_ui_on_next_frame() -> void:
	var anchor := Node2D.new()
	var ui := Control.new()
	_game_ui.mount_world_ui(ui, anchor)
	anchor.free()

	_game_ui._on_frame_pre_draw()

	assert_false(_game_ui._world_anchors.has(ui))
	assert_push_warning("was freed externally")


func test_null_anchor_is_not_treated_as_stale() -> void:
	var ui := Control.new()
	autofree(ui)
	_game_ui.mount_world_ui(ui, null)

	_game_ui._on_frame_pre_draw()

	assert_true(_game_ui._world_anchors.has(ui))
	_game_ui.unmount_world_ui(ui)


func test_unmount_world_ui_is_safe_for_untracked_node_on_frame_draw() -> void:
	var anchor := Node2D.new()
	add_child_autofree(anchor)
	_game_ui._on_frame_pre_draw()

	assert_true(_game_ui._world_anchors.is_empty())


func test_frame_draw_places_ui_at_anchor_position_plus_offset() -> void:
	var anchor := Node2D.new()
	add_child_autofree(anchor)
	anchor.global_position = Vector2(100, 50)
	var ui := Control.new()
	autofree(ui)
	_game_ui.mount_world_ui(ui, anchor, UiLayersTypes.UiLayer.DEFAULT, Vector2(8, -4))

	_game_ui._on_frame_pre_draw()

	var expected := anchor.get_canvas_transform() * anchor.global_position + Vector2(8, -4)
	assert_true(ui.global_position.is_equal_approx(expected))
	_game_ui.unmount_world_ui(ui)


func test_frame_draw_uses_live_position_when_anchor_interpolation_is_off() -> void:
	var anchor := Node2D.new()
	add_child_autofree(anchor)
	anchor.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	anchor.global_position = Vector2(0, 0)
	var ui := Control.new()
	autofree(ui)
	_game_ui.mount_world_ui(ui, anchor)
	# Move the anchor without sampling: the live branch must read its current position.
	anchor.global_position = Vector2(40, 0)

	_game_ui._on_frame_pre_draw()

	assert_true(ui.global_position.is_equal_approx(Vector2(40, 0)))
	_game_ui.unmount_world_ui(ui)


func test_sampling_once_per_tick_keeps_previous_buffer_for_same_tick() -> void:
	var anchor := Node2D.new()
	add_child_autofree(anchor)
	anchor.global_position = Vector2.ZERO
	var ui := Control.new()
	autofree(ui)
	_game_ui.mount_world_ui(ui, anchor)
	var info := _info_for(ui)
	var tick := Engine.get_physics_frames() + 1

	anchor.global_position = Vector2(10, 0)
	_game_ui._sample_anchor(info, tick)
	var curr_after_first := info.curr_world_pos
	anchor.global_position = Vector2(20, 0)
	_game_ui._sample_anchor(info, tick)

	assert_eq(info.curr_world_pos, curr_after_first, "A second sample on the same tick is ignored")
	_game_ui.unmount_world_ui(ui)


func test_mirroring_copies_anchor_visibility_modulate_and_scaled_scale() -> void:
	var anchor := Node2D.new()
	add_child_autofree(anchor)
	anchor.visible = false
	anchor.modulate = Color(0.5, 0.5, 0.5, 1.0)
	anchor.scale = Vector2(2, 2)
	var ui := Control.new()
	autofree(ui)
	ui.scale = Vector2(3, 3)
	_game_ui.mount_world_ui(ui, anchor, UiLayersTypes.UiLayer.DEFAULT, Vector2.ZERO, true)

	_game_ui._on_frame_pre_draw()

	assert_false(ui.visible)
	assert_eq(ui.modulate, Color(0.5, 0.5, 0.5, 1.0))
	assert_eq(ui.scale, Vector2(6, 6), "Anchor scale is multiplied onto the UI's own base scale")
	_game_ui.unmount_world_ui(ui)


func test_without_mirroring_ui_keeps_its_own_visibility_and_modulate() -> void:
	var anchor := Node2D.new()
	add_child_autofree(anchor)
	anchor.visible = false
	var ui := Control.new()
	autofree(ui)
	ui.modulate = Color.WHITE
	_game_ui.mount_world_ui(ui, anchor, UiLayersTypes.UiLayer.DEFAULT, Vector2.ZERO, false)

	_game_ui._on_frame_pre_draw()

	assert_true(ui.visible)
	assert_eq(ui.modulate, Color.WHITE)
	_game_ui.unmount_world_ui(ui)


func test_freeing_world_ui_removes_its_anchor_tracking() -> void:
	var anchor := Node2D.new()
	add_child_autofree(anchor)
	var ui := Control.new()
	_game_ui.mount_world_ui(ui, anchor)
	assert_true(_game_ui._world_anchors.has(ui))

	ui.queue_free()
	await wait_process_frames(2)

	# The key is now a freed object, and a typed Dictionary[Control, ...] rejects has() on it,
	# so check the remaining tracked entries instead.
	assert_true(_game_ui._world_anchors.is_empty())


func test_frame_draw_interpolates_anchor_position_when_interpolation_is_on() -> void:
	var anchor := Node2D.new()
	anchor.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	add_child_autofree(anchor)
	anchor.global_position = Vector2(0, 0)
	var ui := Control.new()
	autofree(ui)
	_game_ui.mount_world_ui(ui, anchor)
	var info := _info_for(ui)
	# Distinct previous and current samples, so the interpolated and live positions diverge.
	info.prev_world_pos = Vector2(0, 0)
	info.curr_world_pos = Vector2(100, 0)
	info.last_sampled_tick = Engine.get_physics_frames()
	anchor.global_position = Vector2(500, 0)

	_game_ui._on_frame_pre_draw()

	# The fraction is read in the same frame as the service, so the expected value matches it.
	var f := Engine.get_physics_interpolation_fraction()
	var expected := info.prev_world_pos.lerp(info.curr_world_pos, f)
	assert_true(ui.global_position.is_equal_approx(expected))
	assert_false(ui.global_position.is_equal_approx(Vector2(500, 0)), "Not the live position")
	_game_ui.unmount_world_ui(ui)
