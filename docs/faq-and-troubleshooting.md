# FAQ and troubleshooting

Problems people hit when they first use the addon, with the cause and the fix. Error text is quoted
from the addon's own messages, so you can search for it.

## Setup

### A capability is `null`, or `Tree export ... not found` is reported

**Cause:** your module can't see the capability you asked for. Godular injects a typed property only
when the capability is provided by your module or exported by a module you import.

**Fix:** import the module that exports the capability in `IMPORTS`. See
[Modules and capabilities](concepts/02-modules-and-capabilities.md#what-the-addon-provides). The
registries (`CapViewsRegistry`, `CapUiAttachmentsRegistry`, `CapInputBindingsRegistry`) are exported by
their modules, so inject them as typed properties, not with `GdlrModuleManager.request()`.

### A capability fails when a node starts

**Cause:** the node resolved a capability before `GdlrModuleManager.start()` returned. Layers and
services aren't ready yet.

**Fix:** wait for the graph before resolving, as shown in
[Modules and capabilities](concepts/02-modules-and-capabilities.md#starting-the-graph).

### My key or Escape does nothing

**Cause:** the action isn't in the Input Map, or a higher layer is blocking input.

**Fix:** check **Project → Project Settings → Input Map** for the action name. Then check whether a
blocking layer (`WINDOW`, `OVERLAY`, or `POPUP`) has UI mounted. See
[UI Layers](guides/ui-layers.md#input-and-focus).

## Views

### `There is already a mounted View for token '...'`

**Cause:** you mounted a token that's already mounted. Each token has one instance at a time.

**Fix:** check `is_view_mounted()` first, or use `get_view()` to reach the existing one. The demo's
toggle bindings check first.

### `No registered View found for token '...'`

**Cause:** the token was never registered, or the module that registers it isn't in the graph.

**Fix:** call `register_view()` in the module's `register()`, and check that the module is imported. See
[Views](guides/views.md).

### My second `WINDOW` View doesn't appear

**Cause:** the `WINDOW` layer accepts one child. A second mount is refused and returns `null`.

**Fix:** unmount the first View before mounting the second, or mount the second on another layer. See
[UI Layers](guides/ui-layers.md).

### A View doesn't close on Escape

**Cause:** Views don't handle dismissal. Only Popups do.

**Fix:** bind Escape to `unmount_view()` in a binding, or in the View's own code. See
[Views](guides/views.md#gotchas).

## Attachments

### My button never appears in the View

Work through this list, in order:

1. Does the View's scene have an `AttachmentSlotsController`? Without one, no Attachment mounts, and no
   error appears.
2. Does `_slot_tag` match a key in `slot_configs` exactly? A mismatch logs `Slot '...' not found. Ignoring`.
3. Is the Attachment registered in `register()`, and is its module imported?
4. Does `_should_mount()` return `true` for this View? The demo's `host_ui is Hud` check passes only for
   the HUD.
5. Is the slot full? A full slot logs `Slot '...' does not have space left`.

### `Attachment UI for slot '...' was not placed; discarding it.`

**Cause:** the slot rejected the UI, either because it's missing or full.

**Fix:** work through the list above. The View itself is unaffected.

### `get_view()` returns `null` inside `_should_mount()`

**Cause:** `_should_mount()` runs while the View is being added to the tree, before `CapGameUi` records it.

**Fix:** check the View's type with `host_ui is MyView`, using `preload` for its script. Don't call
`get_view()` there. See
[Targeting a View from another module](guides/attachments-and-slots.md#targeting-a-view-from-another-module).

### An Attachment's signal keeps firing after its UI is gone

**Cause:** the same Attachment instance is reused across every mount. A signal connected to something
that outlives one mount keeps the old connection.

**Fix:** disconnect external signals in `_on_instance_tree_exiting()`. See
[Gotchas](guides/attachments-and-slots.md#gotchas).

### `Parent of protected slot '...' is not a BoxContainer`, or `... has N children (should have 3)`

**Cause:** `protected_center` requires the slot's parent to be a `BoxContainer` with exactly three children,
and the slot at index `1`.

**Fix:** restructure the slot's parent to match, or remove `protected_center`. See
[Protected center slots](guides/attachments-and-slots.md#protected-center-slots).

## Popups

### My popup doesn't close when I click outside it

**Cause:** `dismiss_on_click_outside` is `false`. It defaults to `true` for `open_popup()`, and to `false`
for `open_popup_queued()`.

**Fix:** pass the flag explicitly. See [Dismissal](guides/popups.md#dismissal).

### My queued popup never appears

**Cause:** an earlier queued popup is still open. A queued popup opens only after the one before it leaves
the tree.

**Fix:** make sure each queued popup can close. Check its close path, and any `can_close_popup()` method
that returns `false`.

### `Popup '...' partially implements the close transition API`

**Cause:** the popup has `begin_close_transition` but not the `close_transition_finished` signal, or the other
way round. This is a warning, and the transition is skipped.

**Fix:** implement both, or neither. See [Close transitions](guides/popups.md#close-transitions).

### `Popup '...' close transition timed out, force-closing.`

**Cause:** the popup's `close_transition_finished` signal didn't fire within 5 seconds.

**Fix:** emit the signal when your animation finishes, including in the early-exit paths.

### `open_popup()` returned `null`

`open_popup()` returns `null` only when mounting fails. Check the return value before you configure the popup:

```gdscript
var dialog: Control = svc_popups.open_popup(CONFIRM_PATH)
if not dialog:
	return

dialog.confirmed.connect(_on_confirmed)
```

## Tooltips

### My tooltip doesn't appear, or the wrong one shows

**Cause:** `show_tooltip()` is refused when another tooltip is already showing, or when the mouse is outside
the anchor's rectangle at the time of the call. A refused request leaves the current tooltip in place.

**Fix:** call `hide_tooltip()` before showing a new one, and make sure the anchor is the node under the
cursor. See [When a tooltip is refused](guides/tooltips.md#when-a-tooltip-is-refused).

### A tooltip stays on screen after the mouse leaves

**Cause:** `hide_tooltip()` isn't called on `mouse_exited`.

**Fix:** connect `mouse_exited` as well as `mouse_entered`.

## World UI

### `world_anchor not found or is not a Node2D`

**Cause:** in `WORLD_FOLLOW` mode, the portal couldn't find a `Node2D` to follow. It uses `world_anchor` if
set, otherwise its owner if that's a `Node2D`, otherwise the owner's parent.

**Fix:** set `world_anchor` explicitly, or place the portal under a `Node2D` owner. See
[World UI](guides/world-ui.md).

### My nameplate doesn't follow the character

**Cause:** `anchor_mode` is `NONE`, or the anchor is the wrong node.

**Fix:** set `anchor_mode` to `WORLD_FOLLOW`, and check `world_anchor`.

### My nameplate doesn't hide when the character hides

**Cause:** the UI was reparented out of the character, so it no longer inherits the character's visibility.

**Fix:** set `mirror_anchor_visuals = true` on the `WorldUiPortal`.

### `World anchor for '...' was freed externally; unmounting.`

**Cause:** the anchor node was freed without the World UI being unmounted. The addon unmounts the UI itself.

**Fix:** unmount the World UI when its owning entity goes away, so the warning doesn't appear.

## Policy Store

### A popup still opens while a category is blocked

**Cause:** the check isn't in the code path that opens the popup, or the blocking source unblocked early.

**Fix:** check `is_allowed()` where the popup opens, and use `get_blockers()` to see which source is blocking.
See [Policy Store](guides/policy-store.md).

### `PolicyStore.block source cannot be null`

**Cause:** `block()` was called with `null` as the source.

**Fix:** pass the object that owns the block, such as the window or the node.

## Still stuck?

Search this site for the error text, then compare your code with the demo's version of the same feature. The
[demo tour](getting-started/04-demo-tour.md) lists the file for each system.
