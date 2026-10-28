extends GutTest
## Unit tests for TooltipUiLayer: acceptance rules, a single tooltip at a time, unmounting, and
## placement through _reposition(). Also covers TooltipsService forwarding.
##
## The anchor and mouse position are controlled through the anchor's rect, so the mouse-outside
## check is deterministic. Placement is driven by calling _reposition() with fixed rects.


const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const UiLayersService = preload("res://addons/modular_ui_architecture/modules/ui_layers/services/ui_layers.svc.gd")
const TooltipsService = preload("res://addons/modular_ui_architecture/modules/tooltips/services/tooltips.svc.gd")
const TooltipScript = preload("res://addons/modular_ui_architecture/modules/tooltips/ui/tooltip.gd")
const FixtureTooltip = preload("res://tests/fixtures/tooltips/fixture_tooltip.gd")

const TOOLTIP_SCENE_PATH := "res://tests/fixtures/tooltips/fixture_tooltip.tscn"
const NON_TOOLTIP_SCENE_PATH := "res://tests/fixtures/scenes/empty_control.tscn"
const TOOLTIP_LAYER := UiLayersTypes.UiLayer.TOOLTIP

var _ui_layers: UiLayersService
var _tooltips: TooltipsService
var _layer: Node


func before_each() -> void:
	_ui_layers = UiLayersService.new()
	_ui_layers.enable()
	await wait_process_frames(2)
	_tooltips = TooltipsService.new(_ui_layers)
	_layer = _ui_layers.get_layer_node(TOOLTIP_LAYER)


func after_each() -> void:
	_tooltips.disable()
	_ui_layers.disable()
	await wait_process_frames(1)


## Returns an anchor Control covering the viewport at (0, 0), so the mouse (also at (0, 0) in
## headless runs) is inside it. A full-rect preset alone leaves a plain Control at zero size here.
func _make_anchor() -> Control:
	var anchor := Control.new()
	add_child_autofree(anchor)
	anchor.position = Vector2.ZERO
	anchor.size = Vector2(800, 600)
	return anchor


## Builds the tooltip data the way TooltipsService does, with typed dictionaries throughout.
func _data(anchor: Control) -> Dictionary[StringName, Variant]:
	var contents: Dictionary[StringName, Variant] = {&"text": "hello"}
	var data: Dictionary[StringName, Variant] = {}
	data[&"anchor"] = anchor
	data[&"contents"] = contents
	data[&"available_rect"] = Rect2(0, 0, 800, 600)
	return data


## Sets up the layer's placement inputs directly, so _reposition() can be checked without the
## async mount path. The anchor sits at [param anchor_rect]; the bubble is [param bubble_size].
func _place(axis: int, anchor_rect: Rect2, bubble_size: Vector2) -> FixtureTooltip:
	var anchor := Control.new()
	add_child_autofree(anchor)
	anchor.position = anchor_rect.position
	anchor.size = anchor_rect.size
	# Instantiate the fixture scene, so its exported bubble/content/description are set and _ready() passes.
	var tooltip := (load(TOOLTIP_SCENE_PATH) as PackedScene).instantiate() as FixtureTooltip
	add_child_autofree(tooltip)
	tooltip.placement_axis = axis as Tooltip.PlacementAxis
	tooltip.bubble.custom_minimum_size = bubble_size
	tooltip.bubble.size = bubble_size
	_layer._anchor = anchor
	_layer._tooltip = tooltip
	_layer._available_rect = Rect2(0, 0, 800, 600)
	return tooltip


func test_scene_that_is_not_a_tooltip_is_rejected() -> void:
	var anchor := _make_anchor()

	var node := _ui_layers.mount_ui(NON_TOOLTIP_SCENE_PATH, TOOLTIP_LAYER, _data(anchor))

	assert_null(node)


func test_invalid_anchor_is_rejected_with_error() -> void:
	# A null anchor is the invalid case the layer can receive without a typed-argument failure.
	var node := _ui_layers.mount_ui(TOOLTIP_SCENE_PATH, TOOLTIP_LAYER, _data(null))

	assert_null(node)
	assert_push_error("Invalid anchor node")


func test_tooltip_is_not_mounted_when_mouse_is_outside_the_anchor() -> void:
	var anchor := Control.new()
	add_child_autofree(anchor)
	anchor.set_anchors_preset(Control.PRESET_TOP_LEFT)
	anchor.size = Vector2(10, 10)
	anchor.position = Vector2(-5000, -5000)

	var node := _ui_layers.mount_ui(TOOLTIP_SCENE_PATH, TOOLTIP_LAYER, _data(anchor))

	assert_null(node)
	assert_true(_layer.get_mounted_nodes().is_empty())


func test_valid_tooltip_is_mounted_initialized_and_starts_transparent() -> void:
	var anchor := _make_anchor()

	var node := _ui_layers.mount_ui(TOOLTIP_SCENE_PATH, TOOLTIP_LAYER, _data(anchor)) as FixtureTooltip

	assert_not_null(node)
	assert_eq(node.get_parent(), _layer)
	assert_eq(node.received_contents, {&"text": "hello"})
	assert_eq(node.modulate.a, 0.0, "Fades in only after placement")


## The layer shows one tooltip at a time: _can_mount_scene() refuses any mount while one is shown, so a
## second tooltip is refused rather than replacing the first.
func test_second_tooltip_is_refused_while_one_is_shown() -> void:
	var anchor := _make_anchor()
	var first := _ui_layers.mount_ui(TOOLTIP_SCENE_PATH, TOOLTIP_LAYER, _data(anchor))

	var second := _ui_layers.mount_ui(TOOLTIP_SCENE_PATH, TOOLTIP_LAYER, _data(anchor))

	assert_not_null(first)
	assert_null(second)
	assert_eq(_layer.get_mounted_nodes().size(), 1)
	assert_true(_layer.get_mounted_nodes().has(first))


func test_unmount_tooltip_with_nothing_mounted_returns_false() -> void:
	var is_removed: bool = _layer.unmount_tooltip()

	assert_false(is_removed)


func test_unmount_tooltip_removes_the_tracked_tooltip() -> void:
	var anchor := _make_anchor()
	_ui_layers.mount_ui(TOOLTIP_SCENE_PATH, TOOLTIP_LAYER, _data(anchor))

	var is_removed: bool = _layer.unmount_tooltip()

	assert_true(is_removed)
	assert_true(_layer.get_mounted_nodes().is_empty())
	assert_null(_layer._anchor)


func test_corner_placement_uses_bottom_right_when_there_is_room() -> void:
	var tooltip := _place(TooltipScript.PlacementAxis.CORNER, Rect2(100, 100, 50, 50), Vector2(80, 40))

	_layer._reposition()

	assert_eq(tooltip.location, TooltipScript.Location.BOTTOM_RIGHT)


func test_corner_placement_flips_to_bottom_left_at_right_edge() -> void:
	var tooltip := _place(TooltipScript.PlacementAxis.CORNER, Rect2(780, 100, 10, 50), Vector2(80, 40))

	_layer._reposition()

	assert_eq(tooltip.location, TooltipScript.Location.BOTTOM_LEFT)


func test_horizontal_placement_prefers_left_when_there_is_room() -> void:
	var tooltip := _place(TooltipScript.PlacementAxis.HORIZONTAL, Rect2(300, 200, 50, 50), Vector2(80, 40))

	_layer._reposition()

	assert_eq(tooltip.location, TooltipScript.Location.LEFT)


func test_horizontal_placement_falls_back_to_right_at_left_edge() -> void:
	var tooltip := _place(TooltipScript.PlacementAxis.HORIZONTAL, Rect2(10, 200, 50, 50), Vector2(80, 40))

	_layer._reposition()

	assert_eq(tooltip.location, TooltipScript.Location.RIGHT)


func test_vertical_placement_prefers_above_when_there_is_room() -> void:
	var tooltip := _place(TooltipScript.PlacementAxis.VERTICAL, Rect2(300, 300, 50, 50), Vector2(80, 40))

	_layer._reposition()

	assert_eq(tooltip.location, TooltipScript.Location.TOP)


func test_vertical_placement_falls_back_to_below_at_top_edge() -> void:
	var tooltip := _place(TooltipScript.PlacementAxis.VERTICAL, Rect2(300, 5, 50, 50), Vector2(80, 40))

	_layer._reposition()

	assert_eq(tooltip.location, TooltipScript.Location.BOTTOM)


func test_tooltip_service_forwards_path_anchor_contents_and_rect() -> void:
	var anchor := _make_anchor()
	var contents: Dictionary[StringName, Variant] = {&"text": "forwarded"}
	var rect := Rect2(0, 0, 320, 240)

	var node := _tooltips.show_tooltip(TOOLTIP_SCENE_PATH, anchor, contents, rect) as FixtureTooltip

	assert_not_null(node)
	assert_eq(node.received_contents, {&"text": "forwarded"})
	assert_eq(_layer._available_rect, rect)
	assert_eq(_layer._anchor, anchor)


func test_tooltip_service_hide_returns_layer_result() -> void:
	assert_false(_tooltips.hide_tooltip())

	var anchor := _make_anchor()
	_tooltips.show_tooltip(TOOLTIP_SCENE_PATH, anchor, {} as Dictionary[StringName, Variant], Rect2(0, 0, 800, 600))

	assert_true(_tooltips.hide_tooltip())
