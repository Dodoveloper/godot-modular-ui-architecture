# Glossary

One-line definitions, each pointing at its canonical source. For the narrative on how these
fit together, see [`core.md`](core.md).

Some entries below cite the project's design docs (`Modular UI Component Types`,
`Modular UI System Implementation`) for vocabulary and intent. Per
[`PRINCIPLES.md`](../PRINCIPLES.md#historical-material-is-discovery-context-not-authority),
those docs are discovery context, not authority — where they diverge from current code, the
entry says so explicitly and current code's actual behavior is what's documented as fact.

### Godular primitives (from `addons/godular`)

- **Module (`GdlrModule`)** — a unit of composition that declares `IMPORTS`
  (modules it depends on), `PROVIDERS` (tokens it can build), `EXPORTS` (tokens importers may
  consume), `TREE_EXPORTS` (tokens resolvable via `GdlrModuleManager.request()`), and optional
  `register()`/`enable()` lifecycle hooks.
  Source: [`addons/godular/classes/module.gd`](../../addons/godular/classes/module.gd).
- **Capability (`GdlrCapability`)** — an `@abstract` class naming a contract (e.g. `CapGameUi`).
  Modules provide a capability via a concrete service; consumers depend on the capability, never
  the concrete class. Source:
  [`addons/godular/classes/capability.gd`](../../addons/godular/classes/capability.gd).
- **Provider / Service** — the concrete class (`*.svc.gd`) a module registers under a capability
  token in `PROVIDERS`. "Service" is this project's naming convention for providers that
  implement a `Cap*` capability.
- **Registry** — a provider (`*.reg.gd`) that only stores/retrieves data for a service to
  consume (e.g. `CapViewsRegistry`, `CapInputBindingsRegistry`, `CapUiAttachmentsRegistry`).
- **`GdlrModuleManager`** — the autoload singleton that mounts/starts the module graph and
  resolves tree exports (`GdlrModuleManager.request(CapXxx)`).

### UI component categories (design vocabulary — see caveat above)

The design docs define a three-tier hierarchy of UI component types. The codebase currently
enforces the **View** tier explicitly (via `CapGameUi`); **Element** and **Widget** are naming
conventions for the *content* mounted into Views/Attachments, not distinct base classes yet —
apply the definitions below when naming/organizing new UI, even without dedicated
`Element`/`Widget` scripts to extend.

- **Element** — the smallest, "dumb" UI building block: no project-specific knowledge or DI, no
  slots, cannot be registered by a module, reusable unmodified across contexts (e.g. a plain
  `Button`, an icon, a `Tooltip`'s visual shell). If a piece of UI needs Context, mounting, or
  module registration, it's not an Element — it's a Widget.
- **Widget** — a reusable UI component that participates in the modular architecture via
  Attachments: it may receive Context from its host View, hold project-specific concepts, be
  mounted more than once simultaneously (each via its own Attachment), and be portable across
  multiple Views (e.g. the Inventory's item slots, a HUD status display). Ask: *does this need
  Context, mounting, or attachment, or does it represent behavior tied to game systems?* If yes
  to any, it's a Widget, not an Element.
- **View** — a top-level, globally-identifiable UI component holding complex/domain-specific
  state, registered under a unique token with exactly one active instance per token at a time
  (e.g. HUD, Pause Menu, Inventory). See "View" under Addon Subsystems below for the concrete
  mechanics (`CapGameUi.mount_view`, `ViewRegistration`).

### This addon's subsystems (`addons/modular_ui_architecture/modules/`)

- **View** — mounted/unmounted by token via `CapGameUi.mount_view`/`unmount_view`, registered
  with a `GameUiTypes.ViewRegistration` (token → scene path, one-to-one). A View should not know
  which Widgets/Attachments it hosts — it only defines Slots and (optionally) a `context`
  property; module-registered Attachments decide what goes into which Slot. Multiple modules
  could register different scenes for the same token (e.g. swapping a desktop/mobile
  implementation) by registering competing/replacing entries — the Views Registry only
  guarantees the one-to-one token↔scene mapping, not which module wins.
- **Attachment (`GameUiTypes.UiAttachment`)** — a module-registered "glue" object that declares:
  which Widget/UI it builds (`_build`/`_Scene`), which Attachment Slot it targets (`_slot_tag`),
  its mounting priority, its mounting condition (`_should_mount`), and how it reacts to the host
  View's Context changing (`_on_context_changed`). A single Widget can be contributed to
  multiple Views/Slots through separate Attachments, and can thus appear mounted more than once
  simultaneously. Source:
  [`addons/modular_ui_architecture/modules/game_ui/types.gd`](../../addons/modular_ui_architecture/modules/game_ui/types.gd).
- **Attachment Slot** — a named `Control` container (tagged via `AttachmentSlotConfig`) that a
  View exposes for Attachments to mount into (e.g. HUD's `bottom_left`/`bottom_center`/
  `bottom_right`). Tree order within a slot follows Attachment priority, then registration
  order; a Slot shouldn't contain View-specific logic beyond arranging its children. Managed per
  View by an `AttachmentSlotsController` node — if that node is absent from a View's scene,
  Attachments for that View are simply never mounted (no error).
- **World UI / World UI Portal** — UI reparented into a UI Layer but positionally tracked against
  a game-world node every physics frame (e.g. a nameplate). Mounted via
  `CapGameUi.mount_world_ui`, usually through the `WorldUiPortal` helper component.
- **Context (View-scoped)** — per-View state, owned and updated by the View, that Attachments
  read to configure the Widgets they build — the mechanism that lets a Widget stay decoupled
  from a View's internal details/platform differences and be reused across multiple Views (each
  Attachment maps that View's own Context shape onto the Widget's fields). **In the current
  code**, this is implemented as a single `context: RefCounted` property that `CapGameUi` polls
  every physics frame (`view.get(&"context")`), diffing its exposed properties and calling
  `UiAttachment._on_context_changed` on that View's own Attachments when something changes — not
  the `get_context() -> Dictionary` method shape described in the older design doc. See
  `inventory.gd`'s `context`/inner `Context` class for the demo's concrete example: the
  Inventory tracks which slot is selected, and the `equipment` module's Attachment (which the
  Inventory neither imports nor knows about) reads `context.selected_item_name` to enable/label
  its "Equip" button. **This is
  the only sanctioned meaning of "Context" in this codebase** — do not reuse the name for
  unrelated state containers (e.g. player data). See ADR-002 for the related decision to keep
  Popups/Tooltips outside this View/Context/Attachment system entirely.
- **Popup (`CapPopups`)** — a dismissable overlay with its own lifecycle: click-outside-to-close,
  `ui_cancel`-to-close, optional hierarchy (parent/child popups), optional "blocking" popups, and
  an optional FIFO queue (`open_popup_queued`) for popups that shouldn't overlap. Distinct from a
  View — see [`core.md`](core.md) for why they're separate subsystems.
- **Tooltip (`CapTooltips`)** — a single-slot, anchor-tracked hover UI shown via
  `show_tooltip(tooltip_path, anchor, contents, available_rect)`. Concrete tooltips extend the
  `Tooltip` base scene/script (`addons/modular_ui_architecture/modules/tooltips/ui/tooltip.gd`)
  and implement `_initialize(tooltip_data)`.
- **UI Layer (`UiLayersTypes.UiLayer`)** — one of a fixed, statically-defined, strictly-ordered
  set of planes UI mounts under (`DEFAULT`, `HUD`, `HUD_OVERLAY`, `WINDOW`, `OVERLAY`, `POPUP`,
  `TOOLTIP`), each backed by a `CanvasLayer`-based `UiLayerNode` (or subclass). Order between
  layers is fixed and controls both draw order and input priority; a layer's node can also
  enforce its own mounting rules (e.g. `WindowUiLayerNode` only allows one mounted child at a
  time). Every View/Popup/Tooltip mount targets a specific layer.
- **`UiLayerNode`** — the node backing a UI Layer, owned/created by `CapUiLayers`. Mounts/unmounts
  nodes, optionally blocks gameplay input while it has mounted children, and listens for
  registered input actions to notify `CapInputBindings` (via `CapUiLayers.notify_input_triggered`)
  when one is pressed/released — decoupling raw input from binding logic. See ADR-001 for its
  `_input` vs. `_unhandled_input` split.
- **Input Binding (`InputBindingsTypes.InputBinding`)** — a small, focused object tied to one
  Input Action (defined in Project Settings) and one target `UiLayer`, implementing
  `_should_execute()` (decide whether to react) and `_execute()` (perform its action, typically
  by calling a service like `CapGameUi` with a View token and layer). Registered via
  `CapInputBindingsRegistry.register_binding(action, binding)`; evaluated by the owning
  `UiLayerNode`, so bindings are scoped to that layer's part of the UI stack. Multiple bindings
  can share an action name, disambiguated by layer and `priority` (higher priority wins;
  first-match-wins semantics — later, lower-priority bindings on the same action+layer only run
  if no higher one executed).
- **Policy Store (`CapPolicyStore`)** — a runtime interaction-governance system that blocks
  semantic *categories* of interaction (e.g. `OPEN_WINDOW_UI`) rather than specific UI instances
  or input actions — it does not handle raw input and does not mount UI itself. Any object can
  `block(category, source)`/`unblock(category, source)`; a category is allowed again only once
  every blocker has been removed or become invalid. Consumers (typically an `InputBinding`'s
  `_should_execute()`) call `is_allowed(category)` to decide whether their normal behavior should
  run at all — this avoids hardcoding flow-specific checks directly into bindings, and lets one
  module's gameplay/UI state veto another module's action (e.g. blocking Pause while a Popup
  owns exclusivity).

### Demo-specific conventions (`demo/`)

- **`ToggleableDisplay`** — base class (`demo/shared/classes/toggleable_display.gd`) for
  dismissable UI used as either a View or a Popup content scene. Two `mount_mode`s: `CACHED`
  (pre-instantiated, `toggle_action` shows/hides it) or `LAZY_LOADED` (mounted/unmounted fresh
  each time, `close_action` requests unmount). Handles its own input in `_input`, not
  `_unhandled_input` — see ADR-001. Focuses the Control returned by the virtual
  `_get_initial_focus_target()` on `_ready` (defaults to itself; return `null` to skip).
- **`Tokens`** (`demo/shared/classes/tokens.gd`) — a `class_name` holding `StringName` constants
  (currently View tokens) shared across demo modules, to avoid stringly-typed duplication.
- **`InputManager`** (`demo/shared/classes/input_manager.gd`) — a static reference-counted
  gameplay input blocker, incremented/decremented by `ToggleableDisplay._on_block_inputs`/
  `_on_unblock_inputs` overrides.

## When To Add Or Update A Term

See [`PRINCIPLES.md`](../PRINCIPLES.md) for the general evidence/confirmation rules that apply
to every doc in this tree. Specific to this file, add or update an entry when:

- a human uses a term that could guide implementation (e.g. naming a new concept during a
  discussion, or correcting how an existing one is described)
- different people (human or agent) use synonyms for the same concept — pick one and record it
  here so future agents don't reintroduce the ambiguity
- a term appears repeatedly in code/docs/comments and isn't self-explanatory from its name alone
- an agent asked for clarification about a term and the answer should be remembered instead of
  re-asked next session
