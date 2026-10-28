## Test double for a Tooltip. Records the data it is initialized with, and lets a test choose the
## placement axis that Tooltip's layer uses when positioning it.
@tool
extends "res://addons/modular_ui_architecture/modules/tooltips/ui/tooltip.gd"

var received_contents: Dictionary = {}
var placement_axis := PlacementAxis.CORNER


func _initialize(tooltip_data: Dictionary[StringName, Variant]) -> void:
	received_contents = tooltip_data


func _get_placement_axis() -> PlacementAxis:
	return placement_axis
