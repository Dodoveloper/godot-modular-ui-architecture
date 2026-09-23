@abstract
class_name CapTooltips
extends GdlrCapability


const UiLayersTypes = preload("../../ui_layers/types.gd")

@abstract func enable() -> void
@abstract func disable() -> void
## Mounts a tooltip.[br]
## [br]
## [param tooltip_path] - Path of the tooltip scene.[br]
## [param anchor] - Node requesting the tooltip.[br]
## [param contents] - Contents to be displayed by the tooltip.[br]
## [param available_rect] - Available space for the tooltip.[br]
## [br]
## Returns the mounted tooltip.
@abstract func show_tooltip(
	tooltip_path: String, anchor: Control, contents: Dictionary[StringName, Variant],
	available_rect: Rect2,
) -> Tooltip
## Removes the currently mounted tooltip.[br]
## [br]
## Returns [code]true[/code] if successful.
@abstract func hide_tooltip() -> bool
