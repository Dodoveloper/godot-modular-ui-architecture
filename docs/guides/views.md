# Views

A **View** is a top-level piece of UI, such as a HUD, a Pause Menu, or an Inventory. Views are
registered under a token, and `CapGameUi` mounts and unmounts them by that token. A token has at most
one active instance at a time.

Views are the Element/Widget/View model's top level. See [Component model](../concepts/03-component-model.md).

## When to use a View

Use a View for UI that:

- is a whole screen or window, or a persistent panel such as a HUD;
- needs to be found and controlled by token from anywhere in the game;
- hosts Attachments from other modules (see [Attachments and Attachment Slots](attachments-and-slots.md)).

For dismissable overlays and dialogs, use [Popups](popups.md) instead. Popups have click-outside
dismissal and optional queueing, and Views don't.

## The minimal setup

1. **Register the View** in your module's `register()`, with a token and the scene path.
2. **Mount it** from a binding, a button, or any code that holds `CapGameUi`.
3. **Unmount it** the same way, with `unmount_view(token)`.

```gdscript
const GameUiTypes = preload("res://addons/modular_ui_architecture/modules/game_ui/types.gd")

const INVENTORY_TOKEN := &"inventory"
const INVENTORY_PATH := "res://my_feature/inventory.tscn"

class MyFeatureModule extends GdlrModule:
	var reg_views: CapViewsRegistry
	var svc_game_ui: CapGameUi

	func register() -> void:
		reg_views.register_view(GameUiTypes.ViewRegistration.new(INVENTORY_TOKEN, INVENTORY_PATH))

	func enable() -> void:
		svc_game_ui.mount_view(INVENTORY_TOKEN)
```

Import `GameUiModule` in your module (`IMPORTS`) to get `CapGameUi` and `CapViewsRegistry`.

## The API

All of these are on `CapGameUi`. The full list is in the [Capabilities API](../reference/capabilities-api.md).

| Method | Purpose |
|--------|---------|
| `mount_view(token, layer := DEFAULT)` | Instantiates the registered scene under `layer`. Returns the View, or `null` if mounting failed. |
| `unmount_view(token)` | Removes the View. Returns `false` if no View is mounted under `token`. |
| `get_view(token)` | Returns the mounted View, or `null`. |
| `is_view_mounted(token)` | `true` if a View is mounted under `token`. |

The signal `view_mounted(token)` fires after a View is mounted and **before** its Attachments are
mounted. Connect to it to set up the View's own behaviour, as the demo does for its Pause Menu.

## Mount on a layer

`mount_view` takes an optional `layer`. Views default to `UiLayer.DEFAULT`. Most Views belong in
`WINDOW` (only one child, so an opened window replaces another) or `HUD`. See [UI Layers](ui-layers.md).

## Declarative mounting with ViewRequester

If a scene always needs a View, add a `ViewRequester` helper node instead of writing code. It asks
`CapGameUi` for the View on its owner's `ready`, or when you call `mount_view()` yourself.
Its exported properties are described in [Helper components](../reference/helper-components.md#viewrequester).

## Swapping a View implementation

You can register a different scene for the same token, for example a desktop and a mobile version.
The View Registry keeps one scene per token, so the module you register last decides. Swap the module
rather than the View's code. Views are conventions with no base class, so the module that registers the scene is what decides which one mounts.

## Gotchas

- **Two mounts for one token fail.** Mounting a token that is already mounted gets `null` and logs an
  error. Check `is_view_mounted()` first if you're not sure. The demo's toggle binding does exactly
  this.
- **A View needs a UI layer that accepts it.** The `WINDOW` layer allows only one child. A second
  mount on that layer returns `null`. See [UI Layers](ui-layers.md).
- **Views don't dismiss themselves.** Nothing closes a View on Escape or on a click outside it. Your
  binding or the View's own code calls `unmount_view()`. The demo's `ToggleableDisplay` base class
  does this for its Views, but it is demo code, so you can write your own close logic.
- **Don't keep a reference to a View after unmounting it.** `unmount_view()` frees the instance.
  Use `get_view()` again if you need it later.

## Next

- [Attachments and Attachment Slots](attachments-and-slots.md): put UI into a View from another module.
- [Input Bindings](input-bindings.md): trigger `mount_view` from a key or button.
