# ADR-001: `UiLayerNode` Broadcasts Focus-Navigation-Colliding Actions In `_input`, Everything Else In `_unhandled_input`

## Status

Accepted.

## Context

Godot's per-event input pipeline runs, in order: `Node._input()` → the `Viewport` GUI phase
(which includes built-in keyboard/joypad focus navigation for `ui_focus_next`, `ui_focus_prev`,
`ui_up`, `ui_down`, `ui_left`, `ui_right`, and normal widget input like typing into a focused
`LineEdit`) → `Node._unhandled_input()`.

`UiLayerNode` originally broadcast every registered `InputMap` action exclusively in
`_unhandled_input`, notifying `CapInputBindings` so registered `InputBinding`s could react.

This broke in two distinct, related ways when building the demo's Inventory and Rename
modules:

1. **Toggling a `LAZY_LOADED` View with Tab did not work to close it.** `ToggleableDisplay`
   grabs keyboard focus on mount for gamepad/keyboard navigation
   (`focus_mode = Control.FOCUS_ALL; grab_focus.call_deferred()`). Once something holds focus,
   Godot's `Viewport::_gui_input_event` special-cases `ui_focus_next`/`ui_focus_prev`/etc. by
   matching the event's *physical key*, not by action name — so any action bound to Tab (e.g. a
   `toggle_inventory` binding) got consumed by focus-cycling in the GUI phase, before
   `_unhandled_input` (and therefore `UiLayerNode`'s broadcast) ever ran. Pause Menu appeared
   unaffected only because its close path never actually exercised the binding — Escape isn't
   one of the focus-cycling actions, and `ToggleableDisplay`'s own `close_action` handling
   (locally, via its own `_unhandled_input`) intercepted Escape first by virtue of running on a
   deeper-in-the-tree, more-recently-added node before `UiLayerNode` in the (LIFO) group-call
   dispatch order.
2. **The straightforward fix (move `UiLayerNode`'s entire broadcast to `_input`) broke typing.**
   Moving *all* action broadcasting unconditionally into `_input` beat the Tab issue, but also
   pre-empted the GUI phase for every other action — including a `toggle_rename` binding bound
   to the letter `R`. With the Rename popup's `LineEdit` focused, pressing `R` to type the
   letter instead re-triggered the `toggle_rename` binding and closed the popup, because the
   binding's broadcast (and `trigger_bindings`' `set_input_as_handled()`) now ran *before* the
   GUI phase could deliver the keystroke to the `LineEdit` at all.

## Decision

`UiLayerNode` broadcasts input in **both** `_input` and `_unhandled_input`, but conditionally:

- In `_input`, it only broadcasts actions that collide with Godot's built-in focus-navigation
  actions (`ui_focus_next`, `ui_focus_prev`, `ui_up`, `ui_down`, `ui_left`, `ui_right`) — see
  `_collides_with_focus_nav()` in
  `addons/modular_ui_architecture/modules/ui_layers/nodes/_base/ui_layer.gd`. This pre-empts
  focus-cycling specifically, and only for the narrow set of actions the engine special-cases.
- In `_unhandled_input`, it broadcasts unconditionally, as before — this is still the primary
  path for every other action, and runs only after the GUI phase has had its normal chance
  (e.g. delivering a keystroke to a focused `LineEdit`).

`demo/shared/classes/toggleable_display.gd` handles its own `close_action`/`toggle_action`
detection in `_input` unconditionally (not conditionally like `UiLayerNode`) — this is safe
specifically because `close_action`/`toggle_action` are UI-dismissal actions, never ones a user
would type as literal text into a focused field within the same display.

### Amendment: the `_input` broadcast must respect layer blocking

Layers with `should_block_inputs` (WINDOW, OVERLAY, POPUP) block lower layers by calling
`set_input_as_handled()` in `_unhandled_input`, relying on higher canvas layers running first.
The `_input` broadcast has no equivalent: it can't mark the event handled without starving the
GUI phase of focus navigation inside the blocking layer itself. As a result, a binding on a
focus-nav key (e.g. `toggle_inventory` on Tab) still fired while a higher blocking layer had
UI mounted (e.g. the chest's queued Popups).

Fix: `CapUiLayers.is_layer_input_blocked(layer)` returns `true` if any layer drawn above
`layer` blocks inputs and has mounted nodes. `UiLayerNode._input` returns early when its own
layer is blocked, without marking anything handled. Don't "fix" this by calling
`set_input_as_handled()` from `_input`, and don't gate individual bindings on layer state.

## Consequences

- Any new input path that broadcasts outside `_unhandled_input` must also check
  `is_layer_input_blocked`.
- Known latent risk: `ToggleableDisplay._input` does not check layer blocking. A popup without
  its own `close_action` shown over a display that has one (e.g. Escape over the Pause Menu)
  would let the underlying display close too. The demo avoids this today because the chest's
  popups are gated by `OPEN_GAMEPLAY_POPUP_UI` while the Inventory and Pause Menu are open. Not
  fixed yet. Revisit if a popup can open over a `close_action` display without that gate.

- Don't move `UiLayerNode`'s broadcast wholesale into `_input` — that reintroduces the typing
  regression (item 2 above). The conditional split is the fix, not `_input` itself.
- Don't move it back to purely `_unhandled_input` — that reintroduces the focus-nav collision
  (item 1 above) for any future binding bound to Tab or an arrow key while something holds
  focus (true for any mounted `ToggleableDisplay`).
- If a future `ToggleableDisplay`'s `close_action`/`toggle_action` is ever bound to a letter key
  that also needs to be typeable inside that same display's own text field, the same class of
  bug could resurface there. This has not happened yet — treat it as a known risk, not
  something to preemptively guard against.
- When adding a new binding, check whether its bound key collides with a focus-navigation
  action if it's meant to work while a `ToggleableDisplay` (or anything else that grabs focus)
  might be mounted.
