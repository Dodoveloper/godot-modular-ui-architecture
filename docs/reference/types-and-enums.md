# Types and enums

The enums and value classes the addon's signatures use. Refer to them by their script's `preload`
constant, as in the guides, for example `UiLayersTypes.UiLayer.WINDOW`.

## UiLayer

Source: `addons/modular_ui_architecture/modules/ui_layers/types.gd`.

| Value | Canvas order | Blocks input below | Notes |
|-------|--------------|--------------------|-------|
| `DEFAULT` | 1 | No | Fallback. |
| `HUD` | 2 | No | HUD Views. |
| `HUD_OVERLAY` | 3 | No | Overlays over the HUD. |
| `WINDOW` | 4 | Yes | Exclusive Views. Only one child is allowed. |
| `OVERLAY` | 5 | Yes | Overlays over windows. |
| `POPUP` | 6 | Yes | Popups. |
| `TOOLTIP` | 7 | No | Tooltips. Only one at a time. |

Canvas order sets draw order and input priority. The addon fixes these values, and your code can't
reorder them.

## UiLayerConfig

A value class that describes a layer's node script, canvas index, and whether it blocks input. The
addon builds these internally, and you won't need to create one.

## InputActionType

Source: `addons/modular_ui_architecture/modules/input_bindings/types.gd`.

| Value | Meaning |
|-------|---------|
| `PRESSED` | The action was pressed. The default. |
| `RELEASED` | The action was released. |

## InputBinding

Source: `addons/modular_ui_architecture/modules/input_bindings/types.gd`. An abstract base class.

| Member | Type | Summary |
|--------|------|---------|
| `layer` | `UiLayer` | The layer the binding is scoped to. Set through `_init()`. |
| `input_type` | `InputActionType` | `PRESSED` or `RELEASED`. Set through `_init()`. |
| `priority` | `int` | Higher runs first. Equal priorities use registration order. Default `0`. |
| `_execute()` | virtual | Performs the behaviour. |
| `_should_execute()` | virtual | Return `true` if the binding should run. |
| `execute()` / `should_execute()` | methods | Call the virtuals. Used by `CapInputBindings`. |

Subclass it, and call `super(layer_)` from your `_init()`. See [Input Bindings](../guides/input-bindings.md).

## PolicyStoreTypes.Category

Source: `addons/modular_ui_architecture/modules/policy_store/types.gd`.

| Value | Meaning |
|-------|---------|
| `OPEN_WINDOW_UI` | Whether opening Windows is allowed. Not used by the demo. |
| `OPEN_GAMEPLAY_POPUP_UI` | Whether gameplay-triggered popups may open. |

Add your own values to this enum to define categories. See [Policy Store](../guides/policy-store.md).

## CloseReason

Source: `addons/modular_ui_architecture/modules/popups/types.gd`. Passed to a popup's
`begin_close_transition()`.

| Value | Meaning |
|-------|---------|
| `SERVICE` | Closed by your code through `CapPopups`. |
| `BACKGROUND_CLICK` | The player clicked outside the popup. |
| `UI_CANCEL` | The player pressed `ui_cancel`. |
| `POPUP` | The popup asked to close, by emitting `close_requested`. |

## UiAttachment

Source: `addons/modular_ui_architecture/modules/game_ui/types.gd`. An abstract base class for Attachments.

| Member | Summary |
|--------|---------|
| `_slot_tag: StringName` | The slot to mount into. |
| `_priority: int` | Mount order within a slot. Higher first. Default `0`. |
| `_Scene: PackedScene` | The default scene for `_build()`. |
| `_should_mount(host_ui, context) -> bool` | Override to restrict where the Attachment mounts. Default `true`. |
| `_build(host_ui, context) -> Control` | Override to build the UI. Call `super()` to instantiate `_Scene`. |
| `_on_context_changed(new_context)` | Override to react to Context changes. |
| `_on_instance_built()` | Override. Called after the UI is built. |
| `_on_instance_tree_exiting()` | Override. Called when the built UI leaves the tree. |
| `get_instance() -> Control` | The currently built UI, or `null`. |

`_init(slot_tag, Scene)` sets `_slot_tag` and `_Scene`. Subclasses usually set those fields in their own `_init()`.

## ViewRegistration

Source: `addons/modular_ui_architecture/modules/game_ui/types.gd`. Pairs a token with a scene path.

| Member | Type | Summary |
|--------|------|---------|
| `token` | `StringName` | The View's token. |
| `scene` | `String` | The View's scene path. |

Construct it as `GameUiTypes.ViewRegistration.new(token, scene_path)`.

## Tooltip enums

Source: `addons/modular_ui_architecture/modules/tooltips/ui/tooltip.gd`.

- `Tooltip.Location`: `TOP_LEFT`, `TOP_RIGHT`, `BOTTOM_RIGHT`, `BOTTOM_LEFT`, `LEFT`, `RIGHT`, `TOP`,
  `BOTTOM`. The addon sets this when placing a tooltip. Read it to know the chosen side.
- `Tooltip.PlacementAxis`: `CORNER` (default), `HORIZONTAL`, `VERTICAL`. Override `_get_placement_axis()` to
  choose it.

## WorldUiPortal.AnchorMode

Source: `addons/modular_ui_architecture/shared/classes/world_ui_portal/world_ui_portal.gd`.

| Value | Meaning |
|-------|---------|
| `NONE` | The UI is moved to its layer and keeps its own layout. |
| `WORLD_FOLLOW` | The UI follows a world node every frame. |

## ViewRequester.MountMode and UnmountMode

Source: `addons/modular_ui_architecture/shared/classes/view_requester/view_requester.gd`.

| Enum | Values | Meaning |
|------|--------|---------|
| `MountMode` | `ON_READY` (default), `MANUAL` | Mount the View when the owner is ready, or only when you call `mount_view()`. |
| `UnmountMode` | `MANUAL` (default), `ON_EXIT_TREE` | Unmount only when you call `unmount_view()`, or when the owner leaves the tree. |

## Next

- [Helper components](helper-components.md): the nodes that use these enums.
- [Capabilities API](capabilities-api.md): the methods that take them.
