# Patterns

Step-by-step recipes for common additions, distilled from how the existing demo modules
(`hud`, `pause_menu`, `rename_ui`, `inventory`, `player`, `chest`) are actually built. Read
[`glossary.md`](glossary.md) and [`core.md`](core.md) first if a term below is unfamiliar.

## Add a new demo module

Every self-contained demo feature lives under `demo/modules/<name>/`, mirroring the addon's own
`modules/<name>/` shape one level down:

1. Create `demo/modules/<name>/<name>.md.gd`. Minimum shape, even if the module provides
   nothing of its own (see `demo/modules/player/player.md.gd` for a real "no PROVIDERS" example):
   ```gdscript
   const SomeAddonModule = preload("res://addons/modular_ui_architecture/modules/.../....md.gd")

   static var IMPORTS := [
       SomeAddonModule,
   ]


   class MyFeatureModule extends GdlrModule:
       pass
   ```
2. Add the new module's `const`+entry to `demo/demo.md.gd`'s `IMPORTS` list — this is the only
   thing `demo.md.gd` does, it has no `PROVIDERS` of its own.
3. Give the module a `content/` subfolder for scenes/scripts (`content/ui/`, `content/entities/`
   as needed), and `bindings/`/`attachments/` subfolders if it registers either (see next
   recipes). Don't nest a demo module under another demo module's folder, even if related.

## Add a View + HUD button + toggle Binding

This is the shape of `pause_menu`, `rename_ui`, and `inventory` — a View that's opened either
by a dedicated HUD button or a keybinding, both funneling through the same `InputBinding` so
button-press and key-press behave identically.

1. **Register the input action** in `project.godot` (`[input]` section) — e.g. a new
   `toggle_<name>` action bound to a key. Check it doesn't collide with an existing action's
   physical key if it needs to work while a text field might have focus (see ADR-001).
2. **Content scene**: `demo/modules/<name>/content/ui/<name>.tscn` +
   `.gd`, extending `demo/shared/classes/toggleable_display.gd`. Use `mount_mode = LAZY_LOADED`
   with `close_action = &"ui_cancel"` if it should close on Escape/click-elsewhere-equivalent
   (View, not Popup — Views don't get click-outside dismissal, only the `close_action` input).
3. **Binding**: `demo/modules/<name>/bindings/toggle_<name>.bind.gd`, extending
   `InputBindingsTypes.InputBinding`. Inject `CapGameUi`; `_execute()` mounts the View if not
   already mounted, else unmounts it (see `toggle_pause_menu.bind.gd` for the exact shape);
   `_should_execute()` returns `true` unless a `CapPolicyStore` category should gate it.
4. **Attachment**: `demo/modules/<name>/attachments/<name>_button.attach.gd`, extending
   `GameUiTypes.UiAttachment`. `_init` sets `_Scene` (a small `Button` scene),
   `_slot_tag` (e.g. `&"bottom_right"` on the HUD), and `_priority`; `_should_mount` restricts it
   to the HUD (`host_ui is Hud`); on press, call
   `_svc_input_bindings.trigger_bindings(action, layer)` — **don't** call the target
   capability directly from the button, always go through the same binding the key uses.
5. **Wire it up in `<name>.md.gd`**: `IMPORTS` `GameUiModule` + `InputBindingsModule` (+
   `PolicyStoreModule` if gating); `register()` builds the binding/attachment instances and
   calls `reg_input_bindings.register_binding(action, binding)` /
   `reg_attachments.register_attachment(attachment)`; if the View emits `close_requested`
   itself (from `ToggleableDisplay`), connect it (via `svc_game_ui.view_mounted`) to
   `svc_game_ui.unmount_view(token)` — see `pause_menu.md.gd`'s `_on_game_ui_view_mounted`.
6. **Register the View token**: add it to `demo/shared/classes/tokens.gd`'s `Views` dictionary,
   and register a `GameUiTypes.ViewRegistration(token, scene_path)` in `register()`.

## Add a Popup

Use a Popup instead of a View when the UI should support click-outside dismissal, doesn't need
to be globally exclusive by token, or should stack/queue with other popups (e.g. a
confirmation dialog, a reward notification).

1. Content scene extends `ToggleableDisplay` too, but there's no `toggle_action` needed —
   `CapPopups` already handles click-outside dismissal at the layer level. Set
   `mount_mode = LAZY_LOADED`. If the popup is shown over another `ToggleableDisplay` (e.g. a
   confirm dialog opened from a View), also set `close_action = &"ui_cancel"` so the two layers'
   `_input` broadcasts (popup layer first, since it's added later) resolve Escape to the topmost
   one — don't leave it to `close_popup.bind.gd` alone, and don't swallow all `InputEventKey`
   events to "be safe"; that also blocks focus-cycling and typing (see ADR-001). If the popup's
   content scene already draws its own dimmed backdrop, pass a transparent `color` to
   `open_popup`/`open_popup_queued` to avoid a double-dimmed look.
2. Trigger it from a binding, a module's `register()`/view-mounted handler, or a plain entity
   that resolves `CapPopups` directly (see "Add a demo module" above for the latter) — whichever
   owns the moment that should show the popup. Always go through `CapPopups`, not `CapGameUi`:
   - `open_popup(popup_path, parent, position, is_blocking, color, dismiss_on_click_outside)`
     for an immediately-mounted, possibly-nested popup. It returns the instance before that
     instance's `_ready()` has run (the popup is parented to its background deferred), so set
     any exported/configuration properties and connect signals on the returned node right away —
     don't assume `@onready` state is populated yet.
   - `open_popup_queued(popup_path, color, setup, dismiss_on_click_outside)` for one that should
     queue (FIFO) behind another already-open queued popup rather than overlapping it. Pass
     per-popup data through the `setup` callable (it runs after instantiation, same timing
     caveat as above), not by trying to read a return value. If the caller may be freed before
     a later-queued popup's `setup` actually runs (e.g. a world entity queueing several popups
     and then freeing itself), bind a `static` method to the data instead of using a closure
     over `self` — see `chest.gd`'s `_configure_popup.bind(config)` — so a freed/invalid
     instance is never implicitly captured.
3. `IMPORTS` `PopupsModule` (which already imports `InputBindingsModule`/`UiLayersModule`/
   `GameUiModule` for you) in the owning `<name>.md.gd`.
4. If the popup needs to look something up rather than receive it via DI (e.g. "who is the
   current player"), prefer a well-known Godot group (`get_tree().get_first_node_in_group(...)`)
   over inventing a new capability for a single lookup — see `rename_display.gd`.
5. If showing the popup should depend on "is this class of interaction currently allowed" (e.g.
   gating gameplay-triggered popups while a View owns exclusivity), check
   `CapPolicyStore.is_allowed(category)` at the call site that would open the popup — see the
   `chest` module (an `Area2D` entity, not a module-owned binding) for a non-binding consumer of
   Policy Store, and the Policy Store recipe below for how to add a new category.

## Add a Tooltip

1. Create a scene/script extending `Tooltip`
   (`addons/modular_ui_architecture/modules/tooltips/ui/tooltip.gd`). Wire the exported
   `bubble`/`content`/`description` node paths in the scene per the base class's contract.
   Override `_initialize(tooltip_data: Dictionary[String, Variant])` to populate your subclass's
   own fields from the dictionary `show_tooltip` will pass in.
2. From the hovering node (e.g. a `Panel`-based item slot), resolve `CapTooltips` lazily —
   `GdlrModuleManager.request(CapTooltips, self)` in `_enter_tree()` — the same pattern
   `WorldUiPortal` uses, since a plain hover-reactive node isn't itself a module.
3. On `mouse_entered`, call
   `svc_tooltips.show_tooltip(tooltip_scene_path, self, contents_dict, get_viewport().get_visible_rect())`.
   On `mouse_exited`, call `svc_tooltips.hide_tooltip()`. Only one Tooltip can be shown at a
   time — `CapTooltips` handles displacing any previous one for you.
4. `IMPORTS` `TooltipsModule` in the owning module if it also registers a View/binding for the
   thing that owns the tooltip-triggering nodes (see `demo/modules/inventory/inventory.md.gd`).

## Add an Input Binding

Use this recipe directly (without a View/Popup) when wiring a new keybinding to existing
behavior, or when a View/Popup needs a *second* binding beyond its toggle (e.g. a per-item
action inside an already-open View).

1. `extends InputBindingsTypes.InputBinding`, `_init(...)` takes whatever capabilities
   `_execute()` needs plus `layer_ := UiLayersTypes.UiLayer.DEFAULT` and calls `super(layer_)`.
2. Implement `_execute()` (perform the action) and `_should_execute()` (decide whether to —
   check `CapPolicyStore.is_allowed(category)` here if the action should be gate-able, not
   inside `_execute()`).
3. Register it: `reg_input_bindings.register_binding(action_name, binding_instance)` in the
   owning module's `register()`. If multiple bindings share an action name, disambiguate with
   `priority` (higher runs first) — don't rely on registration order alone unless that's the
   deliberately intended tiebreaker.
4. Register the `action_name` itself under `[input]` in `project.godot` if it doesn't exist yet.

## Add a Policy Store gate between two modules

Only do this once ≥2 real call sites need the same "is this class of interaction currently
allowed" check (see [`core.md`](core.md#0-design-principles) — don't add a category for a
single one-off check).

1. Add the new category to `PolicyStoreTypes.Category`
   (`addons/modular_ui_architecture/modules/policy_store/types.gd`) with a doc comment
   describing what it gates.
2. The blocking module `IMPORTS PolicyStoreModule` and calls
   `svc_policy_store.block(category, source)` when entering the restricted state, and
   `svc_policy_store.unblock(category, source)` when leaving it — pair these on the same
   object's mount/unmount (see `pause_menu.md.gd`'s `_on_game_ui_view_mounted`/
   `_on_pause_menu_tree_exiting` blocking itself as `source` for its own lifetime).
3. The gated module's binding also `IMPORTS PolicyStoreModule`, injects `CapPolicyStore`, and
   checks `svc_policy_store.is_allowed(category)` inside `_should_execute()` — never inside
   `_execute()`, and never by having the View/Widget itself query Policy Store directly.

## When To Update This Document

See [`PRINCIPLES.md`](../PRINCIPLES.md) for the general rules that apply to every doc in this
tree. Specific to this file, update it when:

- a new kind of demo module or addon subsystem is added that doesn't fit an existing recipe —
  add a new recipe once it's been built at least once, don't speculate one in advance
- an existing recipe's steps stop matching how the referenced example file actually works
  (e.g. `pause_menu.md.gd` changes shape) — re-derive the recipe from the current code
- a recipe turns out to be missing a step that caused a real bug (pair it with an ADR if the
  missing step is subtle enough to be re-broken later, like the input-binding-vs-focus-nav
  gotcha already captured in ADR-001 and referenced from the View recipe above)

