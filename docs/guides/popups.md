# Popups

A **Popup** is a dismissable overlay: a confirmation dialog, a notification, or a menu that sits over
other UI. `CapPopups` manages popups, including click-outside and Escape dismissal, nesting, blocking,
and queueing.

Popups are a separate system from Views. A View is a whole screen identified by a token. A Popup is a
transient overlay. See [Architecture overview](../concepts/01-architecture-overview.md#three-mounting-systems-on-purpose).

## When to use a Popup

Use a Popup for UI that:

- should close when the player clicks outside it, or presses Escape;
- can stack on top of another popup, such as a confirmation over a menu;
- should wait its turn, such as a row of "item obtained" notifications.

For a full screen or a persistent panel, use a [View](views.md).

## Opening a popup

```gdscript
const PopupsModule = preload("res://addons/modular_ui_architecture/modules/popups/popups.md.gd")

const CONFIRM_PATH := "res://my_feature/ui/confirm_dialog.tscn"

static var IMPORTS := [
	PopupsModule,
]


class MyFeatureModule extends GdlrModule:
	var svc_popups: CapPopups


	func _open_confirm() -> void:
		var dialog: Control = svc_popups.open_popup(CONFIRM_PATH)
		dialog.confirmed.connect(_on_confirmed)
```

Import `PopupsModule`, which brings in its own dependencies. The popup scene is yours. It must be a
`Control`. The confirmation dialog in `demo/shared/ui/` is demo code, so it's an example, not part of the addon.

## The API

Both methods are on `CapPopups`. The full list is in the [Capabilities API](../reference/capabilities-api.md#cappopups).

| Method | Use it for |
|--------|------------|
| `open_popup(popup_path, parent, position, is_blocking, color, dismiss_on_click_outside)` | A popup that opens immediately. It may be nested under `parent`. Returns the popup, or `null` on failure. |
| `open_popup_queued(popup_path, color, setup, dismiss_on_click_outside)` | A popup that waits behind other queued popups. Returns nothing. |
| `close_popup(popup)` | Closes a popup. Returns `true` if it was closed. |

### Configuring a popup

`open_popup()` returns the popup before its `_ready()` has run, because the popup is added to the tree
deferred. Configure it right away: set exported properties and connect signals on the returned node.
Don't assume `@onready` variables are set yet.

For a queued popup, you can't read the return value, because the popup may open later. Pass a `setup`
Callable instead. It runs after the popup is instantiated:

```gdscript
svc_popups.open_popup_queued(REWARD_PATH, Color(0, 0, 0, 0), _configure_reward.bind(reward))


static func _configure_reward(popup: RewardDialog, reward: Reward) -> void:
	popup.configure(reward)
```

Use a `static` function with `bind()`, not a lambda that captures `self`. If the object that queued the
popup is freed before its turn comes, a lambda would reference a freed instance. The demo's
`chest.gd` uses this pattern.

## Dismissal

A popup closes in one of these ways. Each one reports a `CloseReason`:

| Reason | Happens when |
|--------|--------------|
| `SERVICE` | Your code calls `close_popup()`. |
| `BACKGROUND_CLICK` | The player clicks outside the popup, and `dismiss_on_click_outside` is `true`. |
| `UI_CANCEL` | The player presses the `ui_cancel` action. |
| `POPUP` | The popup itself asks to close, by emitting `close_requested`. |

Click-outside dismissal is on by default for `open_popup()`, and off for `open_popup_queued()`.
Pass `dismiss_on_click_outside` explicitly when it matters.

### Escape closes the topmost popup

`PopupsModule` registers a binding on `ui_cancel` for the POPUP layer. Escape closes only the topmost
popup, not the ones beneath it.

A popup can refuse to close. If its script has a `can_close_popup()` method that returns `false`, the
addon won't close it for any reason. Use this for an unsaved-changes prompt.

> **Known limitation:** a popup that has no close action of its own can let a View below it react to
> the same Escape press. The demo avoids this by gating the popups it opens. See
> [ADR-001](../../.agents/adrs/001-ui-layer-input-broadcast-ordering.md).

### Close transitions

A popup can animate out before it's freed. Its script must implement both:

- `begin_close_transition(reason: PopupTypes.CloseReason)`, which starts the animation;
- a `close_transition_finished` signal, which the popup emits when the animation ends.

If only one of the two is present, the addon warns and skips the transition. If the signal never fires,
the addon force-closes the popup after 5 seconds.

## Nesting and blocking

Pass a `parent` to nest a popup under another. Closing the parent also closes its children.

A **blocking** popup (`is_blocking = true`) stops its ancestors from closing while it is open. Use this for
a confirmation that must be answered before the menu beneath it can be dismissed.

```gdscript
var dialog := svc_popups.open_popup(CONFIRM_PATH, menu_popup, Vector2.ZERO, true)
```

Popups opened with `open_popup_queued()` are always blocking.

## Queueing

`open_popup_queued()` puts popups in a first-in, first-out queue. Each one opens after the previous one
has left the tree. Use the queue for notifications that must not overlap, such as several "item
obtained" messages from one chest.

## Gotchas

- **Use a different action for a popup's own toggle.** Escape is taken by the popup layer. A binding on
  the same key runs only if the popup layer doesn't handle it first.
- **A queued popup doesn't open immediately.** It waits for the popups ahead of it.
- **`color` is the backdrop behind the popup.** If your popup already draws a dimmed background, pass a
  transparent colour to avoid a double dim.

## Next

- [Policy Store](policy-store.md): stop a category of popups from opening while another system blocks it.
- [Input Bindings](input-bindings.md): a binding that opens a popup.

