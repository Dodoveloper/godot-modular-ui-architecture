# Policy Store

**Policy Store** lets any code block a category of interaction, without the code that checks it
knowing who is blocking it or why. Blocking and checking are separate, so a window can stop gameplay
popups without the popup code knowing the window exists.

## When to use Policy Store

Use it when two or more call sites need the same "is this kind of interaction allowed right now?"
check, and the blocker and the checker are in different modules.

Don't add a category for a single check. A one-off condition belongs in a local `if`.

## The categories

Categories are values of `PolicyStoreTypes.Category`, defined in
`addons/modular_ui_architecture/modules/policy_store/types.gd`. The addon ships two:

| Category | Meaning |
|----------|---------|
| `OPEN_WINDOW_UI` | Whether opening Windows is allowed. Not used by the demo. |
| `OPEN_GAMEPLAY_POPUP_UI` | Whether gameplay-triggered popups (for example, reward notifications) may open. |

To add a category, add an entry to that enum with a doc comment that describes what it gates. Your
project's categories then sit alongside the addon's.

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
	svc_policy_store.block(PolicyStoreTypes.Category.OPEN_GAMEPLAY_POPUP_UI, pause_menu)
	pause_menu.tree_exiting.connect(_on_pause_menu_leaving.bind(pause_menu))


func _on_pause_menu_leaving(pause_menu: Node) -> void:
	svc_policy_store.unblock(PolicyStoreTypes.Category.OPEN_GAMEPLAY_POPUP_UI, pause_menu)
```

Use the blocking object itself as `source`. That gives each blocker its own identity, and lets the
addon clean it up when the object is freed.

## Checking a category

Check the category where the interaction would happen. For a binding, that's `_should_execute()`:

```gdscript
func _should_execute() -> bool:
	return _svc_policy_store.is_allowed(PolicyStoreTypes.Category.OPEN_GAMEPLAY_POPUP_UI)
```

Don't check inside `_execute()`. The demo's chest checks in an entity's own handler instead, because it's
not a binding:

```gdscript
func _on_body_entered(body: Node) -> void:
	if not _svc_policy_store.is_allowed(PolicyStoreTypes.Category.OPEN_GAMEPLAY_POPUP_UI):
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

## Next

- [Input Bindings](input-bindings.md): the usual place to check a category.
- [Popups](popups.md): a popup that a category can gate.
