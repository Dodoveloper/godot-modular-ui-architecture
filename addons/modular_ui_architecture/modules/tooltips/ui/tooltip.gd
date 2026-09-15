@tool
class_name Tooltip
extends Control


## Position of the tooltip.
enum Location {
	TOP_LEFT,
	TOP_RIGHT,
	BOTTOM_RIGHT,
	BOTTOM_LEFT,
	LEFT, 
	RIGHT,
	TOP,
	BOTTOM,
}
## Determines how this tooltip gets positioned, relative to its anchor.
enum PlacementAxis {
	## Placed at one of the four corners of the anchor. Default.
	CORNER,
	## Placed left or right of the anchor, vertically centered.
	HORIZONTAL,
	## Placed above or below the anchor, horizontally centered.
	VERTICAL,
}

const MAX_BUBBLE_WIDTH := 512

@export var location := Location.TOP_RIGHT:
	set = _set_location

@export_tool_button("Reset Bubble Size", "UndoRedo") var reset_bubble_size := _on_content_resized
## Determines the width of the bubble by setting [member bubble]'s [param custom_minimum_size.x].
## Use this to set the tooltip's width, as manual resizing will not work.[br]
## Setting this variable and changing the text of [member description] are the
## intended ways of resizing this tooltip.
@export_range(0, MAX_BUBBLE_WIDTH, 1) var bubble_width := 96:
	set = _set_bubble_width

@export_group("Nodes")
## The node whose rect represents the [Tooltip]'s total size.
@export var bubble: Control
## The node containing the [Tooltip]'s contents, excluding styling or margins.
@export var content: Control
## The node holding the description of the [Tooltip].
@export var description: RichTextLabel


func _ready() -> void:
	assert(bubble, "Bubble node must be set")
	assert(content, "Content node must be set")
	assert(description, "Description node must be set")
	
	_set_bubble_width(bubble_width)
	
	content.resized.connect(_on_content_resized)
	_on_content_resized.call_deferred()


@warning_ignore("unused_parameter")
## Virtual method. Override to customize behavior.
func _initialize(tooltip_data: Dictionary[String, Variant]) -> void:
	pass


## Virtual method. Override to customize behavior.
func _get_placement_axis() -> PlacementAxis:
	return PlacementAxis.CORNER


## Updates the position of the bubble to match the current [member location].[br]
## Override this function to customize the bubble's position.
func _update_bubble_position() -> void:
	var bubble_position := Vector2.ZERO
	match location:
		Location.TOP_LEFT:
			bubble_position = Vector2(-bubble.size.x, -bubble.size.y)
		Location.TOP_RIGHT:
			bubble_position = Vector2(0, -bubble.size.y)
		Location.BOTTOM_RIGHT:
			bubble_position = Vector2(0, 0)
		Location.BOTTOM_LEFT:
			bubble_position = Vector2(-bubble.size.x, 0)
		Location.LEFT:
			bubble_position = Vector2(-bubble.size.x, -bubble.size.y / 2.0)
		Location.RIGHT:
			bubble_position = Vector2(0, -bubble.size.y / 2.0)
		Location.TOP:
			bubble_position = Vector2(-bubble.size.x / 2.0, -bubble.size.y)
		Location.BOTTOM:
			bubble_position = Vector2(-bubble.size.x / 2.0, 0)
	
	bubble.position = bubble_position


## Populates the tooltip with data before it becomes visible.[br]
## [br]
## Called automatically by [TooltipUiLayer] immediately after the tooltip is mounted.
## Do not call this directly — override [method _initialize] instead to define
## how [param tooltip_data] is consumed.[br]
## [br]
## [param tooltip_data] — arbitrary key/value pairs, shape is defined per tooltip subclass.
func initialize(tooltip_data: Dictionary[String, Variant] = {}) -> void:
	_initialize(tooltip_data)


## Returns the axis along which [TooltipUiLayer] should place this tooltip.[br]
## [br]
## Should return one of the following:[br]
## [code]&"corner"[/code] — placed at one of the four corners of the anchor (default).[br]
## [code]&"horizontal"[/code] — placed left or right of the anchor, vertically centered.[br]
## [code]&"vertical"[/code] — placed above or below the anchor, horizontally centered.
func get_placement_axis() -> PlacementAxis:
	return _get_placement_axis()


## Sets [member location] based on direction hints.[br]
## [br]
## [param h_dir] — [code]1[/code] right, [code]-1[/code] left, [code]0[/code] centered (vertical axis).[br]
## [param v_dir] — [code]1[/code] below, [code]-1[/code] above, [code]0[/code] centered (horizontal axis).
func set_location_from_policy(h_dir: int, v_dir: int) -> void:
	if h_dir == 0:
		location = Location.TOP if v_dir == -1 else Location.BOTTOM
	elif v_dir == 0:
		location = Location.LEFT if h_dir == -1 else Location.RIGHT
	else:
		var h_key := "RIGHT" if h_dir == 1 else "LEFT"
		var v_key := "BOTTOM" if v_dir == 1 else "TOP"
		location = Location[v_key + "_" + h_key]


## Returns the size of the bubble, accounting for scale.
## Use this method to know the tooltip's size, because fetching the size of the root node will
## return [code]Vector2.ZERO[/code] as it's just a pivot point.
func get_bubble_size() -> Vector2:
	return bubble.get_global_rect().size


## This method is meant to be called whenever the tooltip's size changes.
func _reset_bubble_size() -> void:
	bubble.reset_size()


func _on_content_resized() -> void:
	_reset_bubble_size()
	_update_bubble_position()


func _set_bubble_width(value: int) -> void:
	bubble_width = value
	if not is_node_ready():
		return
	
	bubble.custom_minimum_size.x = value
	_reset_bubble_size()


func _set_location(value: Location) -> void:
	location = value
	if not is_node_ready():
		return
	
	_update_bubble_position()
