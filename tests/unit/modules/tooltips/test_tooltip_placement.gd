extends GutTest
## Unit tests for the pure placement logic of [code]Tooltip[/code].
## The tooltip is never added to the tree, so only [method Tooltip.set_location_from_policy]
## and the default state are exercised.


const TooltipScript = preload("res://addons/modular_ui_architecture/modules/tooltips/ui/tooltip.gd")

var _tooltip: Control


func before_each() -> void:
	_tooltip = TooltipScript.new()
	autofree(_tooltip)


func test_default_location_is_top_right() -> void:
	assert_eq(_tooltip.location, TooltipScript.Location.TOP_RIGHT)


func test_default_placement_axis_is_corner() -> void:
	assert_eq(_tooltip.get_placement_axis(), TooltipScript.PlacementAxis.CORNER)


func test_policy_right_and_down_maps_to_bottom_right() -> void:
	_tooltip.set_location_from_policy(1, 1)

	assert_eq(_tooltip.location, TooltipScript.Location.BOTTOM_RIGHT)


func test_policy_right_and_up_maps_to_top_right() -> void:
	_tooltip.set_location_from_policy(1, -1)

	assert_eq(_tooltip.location, TooltipScript.Location.TOP_RIGHT)


func test_policy_left_and_down_maps_to_bottom_left() -> void:
	_tooltip.set_location_from_policy(-1, 1)

	assert_eq(_tooltip.location, TooltipScript.Location.BOTTOM_LEFT)


func test_policy_left_and_up_maps_to_top_left() -> void:
	_tooltip.set_location_from_policy(-1, -1)

	assert_eq(_tooltip.location, TooltipScript.Location.TOP_LEFT)


func test_policy_right_only_maps_to_right() -> void:
	_tooltip.set_location_from_policy(1, 0)

	assert_eq(_tooltip.location, TooltipScript.Location.RIGHT)


func test_policy_left_only_maps_to_left() -> void:
	_tooltip.set_location_from_policy(-1, 0)

	assert_eq(_tooltip.location, TooltipScript.Location.LEFT)


func test_policy_down_only_maps_to_bottom() -> void:
	_tooltip.set_location_from_policy(0, 1)

	assert_eq(_tooltip.location, TooltipScript.Location.BOTTOM)


func test_policy_up_only_maps_to_top() -> void:
	_tooltip.set_location_from_policy(0, -1)

	assert_eq(_tooltip.location, TooltipScript.Location.TOP)
