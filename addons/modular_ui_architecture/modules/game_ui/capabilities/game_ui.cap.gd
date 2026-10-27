@abstract
class_name CapGameUi
extends GdlrCapability


const GameUiTypes = preload("../types.gd")
const UiLayersTypes = preload("../../ui_layers/types.gd")

@warning_ignore("unused_signal")
## Emitted when a View is mounted. [b]NOTE[/b]: fired before mounting a View's attachments.
signal view_mounted(token: StringName)

@abstract func enable() -> void
@abstract func disable() -> void
## Mounts a registered View by token.[br]
## [br]
## [param token] - Token of the View.[br]
## [param layer] - Layer the View will be added as a child of.[br]
## [br]
## Returns the View instance.
@abstract func mount_view(token: StringName, layer := UiLayersTypes.UiLayer.DEFAULT) -> Node
## Unounts a currently-mounted View by token.
@abstract func unmount_view(token: StringName) -> bool
## Gets a mounted View by token.
@abstract func get_view(token: StringName) -> Node
## Checks if a View is mounted by token.
@abstract func is_view_mounted(token: StringName) -> bool
## Mounts a world-anchored UI node into a layer and tracks its position per-frame.[br]
## [br]
## [param ui] - The Control to reparent into the target layer.[br]
## [param anchor] - The game-world node to track (world-space position).[br]
## [param layer] - Layer the UI will be added as a child of.[br]
## [param offset] - Screen-space offset from the anchor position.[br]
## [param mirror_anchor_visuals] - If [code]true[/code], mirrors [param anchor]'s
## [code]visible[/code], [code]modulate[/code], and [code]scale[/code] onto [param ui] every
## frame. Useful when [param ui] was reparented out from under [param anchor] but the owning
## scene still authors visibility/animation on [param anchor] expecting it to propagate.[br]
## [br]
## Returns the UI node if successful, [code]null[/code] otherwise.
@abstract func mount_world_ui(
	ui: Control, anchor: CanvasItem = null, layer := UiLayersTypes.UiLayer.DEFAULT,
	offset := Vector2.ZERO, mirror_anchor_visuals := false
) -> Control
## Unmounts a world-anchored UI node and stops position tracking.[br]
## [br]
## [param ui] - The UI node to be unmounted.
@abstract func unmount_world_ui(ui: Node) -> bool
## Mounts the Attachments that apply to [param view], placing each built UI through
## [param add_to_slot].[br]
## [br]
## [param view] - The View to mount Attachments on.[br]
## [param add_to_slot] - Callable with signature
## [code]func(slot_tag: StringName, ui: Control, priority: int) -> bool[/code]. Returns
## [code]true[/code] if the UI was placed. The Callable is only valid for the duration of this
## call and must not be stored.
@abstract func mount_attachments(view: Node, add_to_slot: Callable) -> void
## Unmounts an attachment previously mounted by [method mount_attachments].[br]
## [br]
## [param attachment] - The attachment whose UI should be removed.
@abstract func unmount_attachment(attachment: GameUiTypes.UiAttachment) -> void
