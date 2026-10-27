# Patterns

Step-by-step recipes for common additions, distilled from how the existing demo modules
(`hud`, `pause_menu`, `rename_ui`, `inventory`, `player`, `chest`, `equipment`) are actually
built. Read [`glossary.md`](glossary.md) and [`core.md`](core.md) first if a term below is
unfamiliar.

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

## Expose Context from a View

Do this when Attachments mounted on a View need to react to state that's internal to that View
(e.g. a selection) without the View needing to know which Attachments exist or what they do with
it — see `inventory.gd`'s `context`/`Context` for the concrete example (the Inventory tracks
which slot is selected; it has no idea the `equipment` module's Attachments read that value).

1. Add `var context := Context.new()` directly on the View's script (not a different name — see
   [`glossary.md`](glossary.md#this-addons-subsystems-addonsmodular_ui_architecturemodules),
   "Context" has exactly one meaning in this codebase), and define `Context` as an inner
   `RefCounted` class on the same script with one exported-equivalent field per value Attachments
   should see. `CapGameUi` polls this property every physics frame
   (`game_ui.svc.gd`'s `_poll_view_context`/`_extract_property_values`) and diffs its script
   variables to detect changes — no signal needs to be emitted by the View itself.
2. Update the `Context` instance's fields directly from the View's own event handlers (e.g. a
   child's signal) — the View still owns and mutates its own Context, it just also happens to be
   read externally.
3. Attachments read `context` in `_build(host_ui, context)` for the value at mount time, and
   override `_on_context_changed(new_context)` to react to later changes — see the next recipe
   for a concrete Attachment built this way.

## Attach a Widget to another module's View

Use this when a module should contribute UI into a View it doesn't own, without that module
importing the View's module or the View knowing the Attachment exists — see the `equipment`
demo module's two Attachments (one mounted on the Inventory, one on the HUD) for a working
example of a single module targeting two other modules' Views this way.

1. The attaching module `preload()`s the target View's script directly (e.g.
   `const Inventory = preload(".../inventory.gd")`) to use in `_should_mount` — **don't**
   `IMPORTS` the owning module just for this type check, and don't try `svc_game_ui.get_view()`
   in `_should_mount` either: Attachments mount while the View is still being added to the tree,
   before `CapGameUi` has recorded it as mounted, so that call would always return `null` there.
2. The target View must already expose the Attachment Slot being targeted (see the HUD's
   `bottom_left`/`bottom_center`/`bottom_right` or the Inventory's `footer` for examples) — a
   View defines its own slots, it's the attaching module's job to know which tag to target, not
   the View's job to know who's using it.
3. `_should_mount(host_ui, context)` is only evaluated once, when the View mounts — an Attachment
   can't start/stop targeting a View later based on Context; it can only make its own built
   Widget react to Context changes via `_on_context_changed`. If the Attachment targets a slot
   the host doesn't actually expose, `AttachmentSlotsController.add_to_slot` only
   `push_warning`s (or `push_error`s), returns `false`, and the built UI is discarded — it won't crash the host View.
4. If the Attachment needs state shared with a sibling Attachment registered by the same module
   (e.g. one Attachment writes a value, another displays it), create one small `RefCounted`
   state object in the owning module's `register()` and inject it into both `UiAttachment`
   constructors — see `equipment.md.gd`. Don't promote this to a capability unless a second,
   unrelated module also needs the same state (see [`core.md`](core.md#0-design-principles)).
5. If an Attachment connects to a signal on something that outlives a single mount (e.g. the
   shared state object above, a module-level service), make/break that connection in `_build`/
   `_on_instance_tree_exiting` — **not** `_on_before_delete`. A registered `UiAttachment`
   instance is reused across every mount/unmount cycle of its target View, so `_build` can run
   many times over the Attachment's life, while `_on_before_delete` only fires once (if ever),
   when the Attachment object itself is garbage-collected.

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

