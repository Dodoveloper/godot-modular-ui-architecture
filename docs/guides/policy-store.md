# Policy Store

**Policy Store** lets any code block a category of interaction, without the code that checks it
knowing who is blocking it or why. Blocking and checking are separate, so a window can stop gameplay
popups without the popup code knowing the window exists.

## When to use Policy Store

Use it when two or more call sites need the same "is this kind of interaction allowed right now?"
check, and the blocker and the checker are in different modules.

Don't add a category for a single check. A one-off condition belongs in a local `if`.

## The categories

A category is a `StringName` token, such as `&"open_shop"`. Code refers to it by that name.

The addon ships two built-in categories as constants on `PolicyStoreTypes`, defined in
`addons/modular_ui_architecture/modules/policy_store/types.gd`. The addon registers both when
`PolicyStoreModule` registers:

| Constant | Token | Meaning |
|----------|-------|---------|
| `OPEN_WINDOW_UI` | `&"open_window_ui"` | Whether opening Windows is allowed. Not used by the demo. |
| `OPEN_GAMEPLAY_POPUP_UI` | `&"open_gameplay_popup_ui"` | Whether gameplay-triggered popups (for example, reward notifications) may open. |

### Declaring your own

A module declares its categories in `register()`, through `CapPolicyCategoriesRegistry`. Importing
`PolicyStoreModule` makes the registry available:

```gdscript
const PolicyStoreModule = preload("res://addons/modular_ui_architecture/modules/policy_store/policy_store.md.gd")

const OPEN_SHOP_CATEGORY := &"open_shop"

static var IMPORTS := [PolicyStoreModule]


class ShopModule extends GdlrModule:
	var reg_policy_categories: CapPolicyCategoriesRegistry


	func register() -> void:
		reg_policy_categories.register_category(OPEN_SHOP_CATEGORY)
```

Godular runs every module's `register()` before any `enable()`. A category is therefore registered
before any module can block or check it in `enable()`. Your categories work the same way as the
built-in ones in the rest of this guide.

Registration rules:

- Pick a token that is unique across the project. Registering the same token twice pushes an error,
  and the second call is ignored.
- An empty token pushes an error and is ignored.
- Unregister a category with `unregister_category()` when your code removes the category. Unregistering
  drops every block on it, and a category registered again later starts unblocked. Godular does not call
  `disable()` on modules, and each `mount()` builds a new registry, so the built-in categories don't need
  unregistering on shutdown.

## Blocking and unblocking

`CapPolicyStore` has four methods:

- `block(category, source)`: blocks a category, on behalf of `source`.
- `unblock(category, source)`: removes that source's block.
- `is_allowed(category)`: `true` if no source is blocking the category.
- `get_blockers(category)`: the sources currently blocking it, for debugging.

A category stays blocked until every source that blocked it has unblocked or been freed. A freed
source is pruned automatically, so a node that is destroyed without unblocking doesn't leave the
category blocked forever.

The demo's Pause Menu blocks while it's open, and unblocks when it leaves the tree:

```gdscript
func _on_pause_menu_mounted(pause_menu: Node) -> void:
	svc_policy_store.block(PolicyStoreTypes.OPEN_GAMEPLAY_POPUP_UI, pause_menu)
	pause_menu.tree_exiting.connect(_on_pause_menu_leaving.bind(pause_menu))


func _on_pause_menu_leaving(pause_menu: Node) -> void:
	svc_policy_store.unblock(PolicyStoreTypes.OPEN_GAMEPLAY_POPUP_UI, pause_menu)
```

Use the blocking object itself as `source`. That gives each blocker its own identity, and lets the
addon clean it up when the object is freed.

## Checking a category

Check the category where the interaction would happen. For a binding, that's `_should_execute()`:

```gdscript
func _should_execute() -> bool:
	return _svc_policy_store.is_allowed(PolicyStoreTypes.OPEN_GAMEPLAY_POPUP_UI)
```

Don't check inside `_execute()`. The demo's chest checks in an entity's own handler instead, because it's
not a binding:

```gdscript
func _on_body_entered(body: Node) -> void:
	if not _svc_policy_store.is_allowed(PolicyStoreTypes.OPEN_GAMEPLAY_POPUP_UI):
		return
	_grant_rewards()
```

## Module wiring

- The **blocking** module imports `PolicyStoreModule` and injects `CapPolicyStore`.
- The **checking** module imports `PolicyStoreModule` too, and injects `CapPolicyStore`.

Importing the module makes the capability available to both. Neither module needs to import the other.

## Gotchas

- **A view or widget shouldn't query Policy Store.** Put the check in the binding or the entity that
  performs the action. Views report their state, and the binding decides.
- **Blocking doesn't stop input by itself.** Policy Store only answers `is_allowed()`. Something must
  check it, usually a binding's `_should_execute()`.
- **Block with a live object.** `null` is rejected with an error, and a freed source is pruned on the
  next check.
- **An unregistered category is an error.** `block()` and `unblock()` push an error and do nothing.
  `is_allowed()` and `get_blockers()` push an error too, and `is_allowed()` returns `true`. A typo in a
  category token therefore lets the gated interaction through. Check the error output when you add a
  category.

## Migrating from 1.x

Version 2.0.0 replaces the `PolicyStoreTypes.Category` enum with `StringName` tokens:

- `PolicyStoreTypes.Category.OPEN_GAMEPLAY_POPUP_UI` becomes `PolicyStoreTypes.OPEN_GAMEPLAY_POPUP_UI`.
  The same applies to `OPEN_WINDOW_UI`.
- If you added values to the enum in the addon's `types.gd`, move each one into a
  `register_category()` call in one of your modules, as shown in [Declaring your own](#declaring-your-own).
  Then replace its references with the new token.
- Revert your edits to the addon's `types.gd`. The categories are now declared by your module, so
  an addon upgrade no longer overwrites them.

## Next

- [Input Bindings](input-bindings.md): the usual place to check a category.
- [Popups](popups.md): a popup that a category can gate.
