# Core Architecture

The narrative behind how this addon's systems fit together. For term-by-term definitions, see
[`glossary.md`](glossary.md). Design intent below is drawn from the project's own design docs
(`Modular UI Component Types`, `Modular UI System Implementation`) plus the current
implementation — per [`PRINCIPLES.md`](../PRINCIPLES.md), where they diverge this file follows
the current implementation and notes the gap as recorded debt, not a silently-resolved choice.

## 0. Design principles

These are the recurring design rules this codebase already follows, made explicit so future
additions stay consistent instead of drifting:

- **Composition over deep inheritance.** Inheritance here is one level deep by convention: a
  `@abstract class_name CapXxx` (contract) has exactly one concrete `*.svc.gd`/`*.reg.gd`
  implementation extending it — see `CapGameUi` → `game_ui.svc.gd`. Gameplay/UI behavior is
  composed instead: `WorldUiPortal`, `AttachmentSlotsController`, and `ViewRequester` are all
  plain helper *components* added as sibling/child nodes, not base classes to inherit from. A
  second level of inheritance (e.g. a `ToggleableDisplay` subclass gaining its own further
  subclass) should earn its keep; a third should prompt a design discussion.
- **One class, one reason to change.** Capabilities (`*.cap.gd`) define contracts only —
  no logic. Services (`*.svc.gd`) orchestrate behavior/side effects. Registries (`*.reg.gd`)
  only store/retrieve registered data (compare `input_bindings.reg.gd`, pure storage, against
  `input_bindings.svc.gd`, which owns the triggering logic). Don't fold registry-shaped storage
  into a service "for convenience" — split it out, following the existing modules' shape.
- **One canonical owner per shared state value.** The clearest existing example is Context: a
  View's `context` property is the *only* place that state is read from — `CapGameUi` polls it
  and Attachments react to changes, but nothing else mirrors or caches it independently (see
  §5 below). When adding new shared state, resist copying it into a second property/cache "for
  convenience" — expose a way to query the one owner instead.
- **Pragmatism: don't abstract for a single use.** `CapPolicyStore` exists as its own module
  because *multiple* bindings across *multiple* demo modules independently need "is this class
  of interaction currently allowed", not because every cross-cutting check deserves a capability
  — a single one-off check belongs in a private method or a local check inside the one
  `InputBinding` that needs it. Extract a new capability/module when it removes real
  duplication across ≥2-3 concrete call sites or protects a contract other modules already
  depend on, not preemptively.

## 1. Godular: DI and module lifecycle

Everything is composed through [Godular](../../addons/godular/README.md), a small DI/module
framework. A module (`GdlrModule`) declares, as static members on its script:

- `IMPORTS` — other modules this one depends on; Godular registers/enables them first.
- `PROVIDERS` — a `{token: {"use": Script, "inject": [...]}}` map describing how to build each
  token this module owns.
- `EXPORTS` — tokens importing modules may consume.
- `TREE_EXPORTS` — tokens resolvable anywhere via `GdlrModuleManager.request(Token)`.

Lifecycle: Godular creates every module (imports first), injects each module's typed
`Cap*`-typed properties with resolved capabilities, calls `register()` on every module
(synchronous — register bindings/views/attachments here), resolves tree exports, then calls
`enable()` in dependency order (can `await`; a module waits for its imports' `enable()` to
finish). `demo/content/levels/main.gd` is a **plain, non-module** bootstrap script that calls
`GdlrModuleManager.mount(DemoModule)` then `.start()` before spawning anything that resolves
capabilities — this ordering matters, don't resolve a capability before `start()` returns.

A **capability** (`GdlrCapability`) is the contract consumers depend on — e.g. `CapGameUi`.
Consumers never depend on the concrete `*.svc.gd`/`*.reg.gd` class directly, only the `Cap*`
abstract class, so a module can be swapped without touching its consumers.

## 2. Three separate mounting subsystems, on purpose (see ADR-002)

The addon does **not** have one unified "modal"/"overlay" concept. It has three, each solving a
narrower problem with its own guarantees:

- **`CapGameUi`** — Views (one exclusive instance per token, e.g. HUD/Pause Menu/Inventory),
  Attachments (module-contributed Widgets glued into a View's Slots, reacting to that View's
  Context), and World UI (screen-space UI tracking a game-world node, e.g. nameplates).
- **`CapPopups`** — dismissable overlays with click-outside/`ui_cancel` dismissal, optional
  parent/child hierarchy, optional "blocking" children, and an optional FIFO queue for popups
  that shouldn't visually overlap (`open_popup_queued`).
- **`CapTooltips`** — a single-slot, anchor-tracked hover UI, mutually exclusive with itself
  (only one Tooltip can be shown at a time) and positioned automatically relative to its anchor
  and the available screen rect.

They share the same underlying **UI Layer** system (`CapUiLayers`) for where they mount and how
input reaches them, but are otherwise independent APIs, independent registries, and independent
lifecycles. See ADR-002 for why this split was kept instead of unifying them.

## 3. UI Layers: mounting + input, end to end

Each `UiLayer` (`DEFAULT`, `HUD`, `HUD_OVERLAY`, `WINDOW`, `OVERLAY`, `POPUP`, `TOOLTIP`) is a
`CanvasLayer` backed by a `UiLayerNode` (or a subclass overriding `_can_mount_scene`/
`_mount_node` for layer-specific rules, e.g. `WindowUiLayerNode` allowing only one mounted
child). `CapUiLayers` creates one `UiLayerNode` per layer at `enable()`, in a fixed, ordered
list that also determines draw order and input priority (declared in
`ui_layers.svc.gd::_layers_config`).

Input flow, per event:

1. `UiLayerNode` listens for every registered `InputMap` action and, when one is
   pressed/released, calls `CapUiLayers.notify_input_triggered(action, layer, input_type)` —
   this only *broadcasts*, it doesn't decide behavior.
2. `CapUiLayers.ui_layer_input_triggered` is relayed by `CapInputBindings`
   (`input_bindings.svc.gd`) into `trigger_bindings(action, layer, input_type)`.
3. `trigger_bindings` looks up all `InputBinding`s registered for that action (via
   `CapInputBindingsRegistry`), sorted by descending priority (registration order breaks ties),
   filters to ones matching `layer`/`input_type`, and executes the **first** whose
   `_should_execute()` returns `true` — first-match-wins; it stops there and marks the event
   handled.
4. An `InputBinding`'s `_execute()` typically calls a capability like `CapGameUi` to
   mount/unmount a View by token. `_should_execute()` is where cross-cutting gates belong (e.g.
   querying `CapPolicyStore.is_allowed(category)`), keeping that logic out of raw input
   handling and out of the View/Widget code itself.

This deliberately keeps three concerns apart: layers only know about *detecting* input, bindings
know about *services and tokens* (not concrete Widgets/Views), and Policy Store knows about
*whether a category of behavior is currently allowed* — none of the three needs to know about
the other two's internals.

### The `_input` vs `_unhandled_input` subtlety (read before touching input code)

Godot's per-event pipeline is `Node._input()` → Viewport GUI phase (focus-cycling via
`ui_focus_next`/`ui_focus_prev`/`ui_up`/`ui_down`/`ui_left`/`ui_right`, plus normal widget input
like typing into a focused `LineEdit`) → `Node._unhandled_input()`. `UiLayerNode` broadcasts
input in **both** phases, but conditionally: only actions that collide with the engine's
built-in focus-navigation actions are broadcast in `_input` (pre-empting focus-cycling before it
swallows them); everything else broadcasts only in `_unhandled_input` (after the GUI phase has
had its normal chance, e.g. so a focused `LineEdit` still receives typed characters).
The `_input` broadcast also skips layers obstructed by a higher blocking layer
(`CapUiLayers.is_layer_input_blocked`), since it can't block via `set_input_as_handled()`. See
ADR-001 for the full incident history and why this split — not a blanket move to `_input` — is
the correct fix. `demo/shared/classes/toggleable_display.gd` has a parallel, simpler version of
this same concern for its own `close_action`/`toggle_action` (it reacts in `_input`
unconditionally, which is safe there because those actions are never meant to be typed as text).

## 4. Policy Store: cross-module interaction gating

`CapPolicyStore` blocks semantic categories (`PolicyStoreTypes.Category`, e.g.
`OPEN_WINDOW_UI`), not specific bindings or UI instances. Any object calls
`block(category, source)`/`unblock(category, source)`; the category is allowed again only once
every blocker is removed or its `source` becomes invalid (pruned automatically via `WeakRef`).
This is intentionally decoupled from `CapInputBindings` — a binding's `_should_execute()` is
just one *consumer* of Policy Store, not the only one; any system needing to know "is this class
of interaction currently allowed" can ask, without knowing which other module(s) might be
blocking it or why. The demo's `chest` entity is a non-binding example: it checks
`is_allowed(PolicyStoreTypes.Category.OPEN_GAMEPLAY_POPUP_UI)` directly before opening its
reward popups, with `pause_menu`/`inventory` blocking that category for their own lifetime.
(See §0 — this is the "pragmatism" example: it was extracted because multiple bindings across
multiple demo modules needed the same check, not preemptively.)

## 5. Naming discipline: "Context" is reserved

"Context" has exactly one meaning in this codebase: the `context: RefCounted` property
`CapGameUi` polls on a mounted View to notify that View's own Attachments of changes (see
[`glossary.md`](glossary.md#this-addons-subsystems-addonsmodular_ui_architecturemodules) — and
§0 above for why this is also the "one canonical owner" example). Don't reuse the word for
unrelated per-entity state (e.g. player data) — see the `demo/modules/player` module for the
alternative used there (a plain signal + property directly on the entity).

## When To Update This Document

See [`PRINCIPLES.md`](../PRINCIPLES.md) for the general rules that apply to every doc in this
tree. Specific to this file, update it when:

- a new cross-cutting mechanism is added that spans multiple modules (like Policy Store did) —
  explain *why* it's separate from what already exists, not just what it does
- an existing subsystem's responsibilities shift enough that the "who talks to whom" picture
  above becomes wrong
- a subtle ordering/pipeline behavior (like the `_input`/`_unhandled_input` split) is discovered
  or changed — pair it with an ADR entry if it's the kind of thing someone could plausibly
  "fix" back into a bug, and link the ADR from here
- the gap between a design doc and the implementation changes (narrows, widens, or resolves)
