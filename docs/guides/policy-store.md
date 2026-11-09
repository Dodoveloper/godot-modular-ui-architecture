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

The addon ships no categories. A project declares every category it uses, from one of its own modules.
The demo declares `OPEN_GAMEPLAY_POPUP_UI` in its `policies` module (`demo/modules/policies/`), and
the modules that block or check it import that module.

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
before any module can block or check it in `enable()`.

Registration rules:

- Pick a token that is unique across the project. Registering the same token twice pushes an error,
  and the second call is ignored.
- An empty token pushes an error and is ignored.
- Unregister a category with `unregister_category()` when your code removes the category. Unregistering
  drops every block on it, and a category registered again later starts unblocked. Godular does not call
  `disable()` on modules, and each `mount()` builds a new registry, so categories don't need
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
	svc_policy_store.block(Tokens.Policies.Categories.OPEN_GAMEPLAY_POPUP_UI, pause_menu)
	pause_menu.tree_exiting.connect(_on_pause_menu_leaving.bind(pause_menu))


func _on_pause_menu_leaving(pause_menu: Node) -> void:
	svc_policy_store.unblock(Tokens.Policies.Categories.OPEN_GAMEPLAY_POPUP_UI, pause_menu)
```

`Tokens` is the demo's own token holder (`demo/shared/classes/tokens.gd`). Projects keep their
category tokens wherever suits them. The addon doesn't use `Tokens`.

Use the blocking object itself as `source`. That gives each blocker its own identity, and lets the
addon clean it up when the object is freed.

## Checking a category

Check the category where the interaction would happen. For a binding, that's `_should_execute()`:

```gdscript
func _should_execute() -> bool:
	return _svc_policy_store.is_allowed(Tokens.Policies.Categories.OPEN_GAMEPLAY_POPUP_UI)
```

Don't check inside `_execute()`. The demo's chest checks in an entity's own handler instead, because it's
not a binding:

```gdscript
func _on_body_entered(body: Node) -> void:
	if not _svc_policy_store.is_allowed(Tokens.Policies.Categories.OPEN_GAMEPLAY_POPUP_UI):
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
- **Token holders are not compile-checked.** The demo's `Tokens.Policies.Categories` is a dictionary, so
  a misspelled key returns `null` at runtime instead of failing to parse. Check the error output for
  `is not registered`, as above.

## Migrating from 1.x

Version 2.0.0 replaces the `PolicyStoreTypes.Category` enum with `StringName` tokens, and the addon no
longer ships any categories:

- The file `policy_store/types.gd` is deleted. Remove any `preload` of it.
- `PolicyStoreTypes.Category.OPEN_GAMEPLAY_POPUP_UI` and `PolicyStoreTypes.Category.OPEN_WINDOW_UI` are
  gone. Declare each category your project uses, with `register_category()`, in one of your modules. The
  demo's `policies` module shows the pattern for `OPEN_GAMEPLAY_POPUP_UI`.
- Any values you added to the enum in the addon's `types.gd` move to a `register_category()` call in your
  own module. Then replace their references with the token.
- Revert your edits to the addon's `types.gd` if you made any. The file no longer exists in 2.0.0.

## Next

- [Input Bindings](input-bindings.md): the usual place to check a category.
- [Popups](popups.md): a popup that a category can gate.
