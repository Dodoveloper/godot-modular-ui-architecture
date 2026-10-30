# Helper components

Scene-based helpers you add to a scene in the editor. Each is a `Node` with a script under
`addons/modular_ui_architecture/shared/classes/`, and a ready-made scene next to it. Instance the scene,
or attach the script to a node you already have.

## ViewRequester

Source: `shared/classes/view_requester/view_requester.gd`. Scene: `view_requester.tscn`.

Declares that a scene needs a View, without code. It requests the View from `CapGameUi` and mounts it
on the owner's `ready` by default.

| Export | Type | Default | Purpose |
|--------|------|---------|---------|
| `token` | `StringName` | `&""` | The token of the View to request. Required. |
| `layer` | `UiLayer` | `DEFAULT` | The layer the View mounts on. |
| `mount_mode` | `MountMode` | `ON_READY` | `ON_READY` mounts on the owner's `ready`. `MANUAL` waits for `mount_view()`. |
| `unmount_mode` | `UnmountMode` | `MANUAL` | `MANUAL` unmounts only on `unmount_view()`. `ON_EXIT_TREE` unmounts when the owner leaves the tree. |

| Member | Summary |
|--------|---------|
| `view_instance: Node` | The mounted View, or `null`. |
| `mount_view() -> Node` | Mounts the View, or returns the existing one if already mounted. |
| `unmount_view()` | Unmounts the View. |
| signal `view_mounted(view: Node)` | Emitted when the View mounts. |

The View is mounted through `CapGameUi`, so the same token rules apply. See [Views](../guides/views.md).

## AttachmentSlotsController

Source: `shared/classes/attachment_slots_controller/attachment_slots_controller.gd`. Scene:
`attachment_slots_controller.tscn`.

Add one to a View to expose Attachment Slots. Without it, Attachments for that View never mount.

| Export | Type | Purpose |
|--------|------|---------|
| `slot_configs` | `Dictionary[StringName, AttachmentSlotConfig]` | One entry per slot. The key is the slot tag. Each value is an `AttachmentSlotConfig`. |

| Method | Summary |
|--------|---------|
| `add_to_slot(slot_tag, ui, priority := 0) -> bool` | Adds a Control to a slot. Returns `true` if placed. The Callable form of this is passed to `CapGameUi.mount_attachments`. |
| `has_slot(slot_tag) -> bool` | Whether the slot is defined. |
| `get_slot(slot_tag) -> AttachmentSlot` | The slot, or `null`. |

Slot configs are read on `ready`. The `slot_configs` dictionary is set in the editor.

## AttachmentSlotConfig

Source: `shared/resources/attachment_slot_config.gd`. A `Resource`, so you create it in the inspector.

| Export | Type | Default | Purpose |
|--------|------|---------|---------|
| `node_path` | `NodePath` | `""` | The `Control` that holds the slot's children, relative to the `AttachmentSlotsController`. |
| `max_children` | `int` | `-1` | How many Attachments the slot accepts. `-1` is unlimited. |
| `protected_center` | `bool` | `false` | Keeps the slot centred when its siblings grow. Requires a `BoxContainer` parent with three children, and the slot at index `1`. |

See [Attachments and Attachment Slots](../guides/attachments-and-slots.md#protected-center-slots).

## WorldUiPortal

Source: `shared/classes/world_ui_portal/world_ui_portal.gd`. Scene: `world_ui_portal.tscn`.

Mounts a UI into a layer, and optionally follows a world node. See [World UI](../guides/world-ui.md).

| Export | Type | Default | Purpose |
|--------|------|---------|---------|
| `target_ui` | `Control` | `null` | The control to mount. Required. |
| `target_layer` | `UiLayer` | `DEFAULT` | The layer to mount on. |
| `anchor_mode` | `AnchorMode` | `NONE` | `NONE` keeps the UI's layout. `WORLD_FOLLOW` follows `world_anchor`. |
| `world_anchor` | `Node2D` | `null` | The node to follow in `WORLD_FOLLOW` mode. Empty means the owner, or the owner's parent. |
| `mirror_anchor_visuals` | `bool` | `false` | Copies the anchor's `visible`, `modulate`, and `scale` onto the UI. `WORLD_FOLLOW` only. |

| Method | Summary |
|--------|---------|
| `get_managed_ui() -> Control` | Returns the mounted UI, mounting it immediately if needed. |

The UI mounts after `_ready()`, so `target_ui`'s own `@onready` values are set by then.

## Next

- [Types and enums](types-and-enums.md): the enums these exports use.
- [Project conventions](conventions.md): where these scenes live in your project.
