# Modular UI Architecture

An opinionated architecture and set of runtime systems for building modular, reusable, and
extensible UI in Godot 4.7, built on top of [Godular](addons/godular/README.md) (a DI/module
framework) and [GdbPromise](addons/gdb_promise/README.md) (a promise library).

## The problem

UI tends to accumulate coupling as a game grows. A HUD script ends up with direct references to
the inventory, the quest log, and the pause menu; a new feature means editing scenes owned by
other systems; and removing a feature means hunting down every place that still reaches into it.
Escape closes three overlapping windows at once, a hotkey fires while a text field has focus,
and "don't show a popup while the game is paused" gets hardcoded into every popup instead of
declared once.

This addon addresses that by making UI **modular at the architecture level**: features register
what they need (a View, a HUD button, a keybinding) without editing the scenes they attach to,
and removing a feature's module removes everything it contributed — no dangling references.

## What it gives you

- **Views** (`CapGameUi`) — top-level UI (HUD, Pause Menu, Inventory) mounted/unmounted by a
  stable token, with exactly one active instance per token.
- **Attachments & Attachment Slots** — a module can mount a Widget into another module's View
  (e.g. a HUD button, a footer button inside the Inventory) without that View knowing the
  Attachment exists, and without the attaching module importing the View's module.
- **Context** — per-View state that a View exposes and Attachments read, so a Widget stays
  decoupled from the View's internals and can be reused across multiple Views.
- **Input Bindings + UI Layers** — keyboard shortcuts and button presses funnel through the same
  binding, scoped to a UI layer, so a key and its equivalent button always behave identically,
  and typing into a focused field isn't swallowed by an unrelated hotkey.
- **Popups** (`CapPopups`) — dismissable overlays with click-outside/Escape dismissal, optional
  parent/child hierarchy with "blocking" children, and a FIFO queue for popups that shouldn't
  overlap (e.g. a string of "item obtained" notifications).
- **Tooltips** (`CapTooltips`) — single-instance, anchor-tracked hover UI.
- **World UI** (`WorldUiPortal`) — UI reparented into a UI layer but positionally tracked against
  a game-world node every frame (e.g. a nameplate).
- **Policy Store** (`CapPolicyStore`) — declares that a category of interaction (e.g. "open a
  popup") is blocked, from wherever that decision is made, without the gated code needing to
  know who's blocking it or why.

See [`.agents/architecture/core.md`](.agents/architecture/core.md) and
[`.agents/architecture/glossary.md`](.agents/architecture/glossary.md) for how these fit
together, and [ADR-002](.agents/adrs/002-separate-popups-views-tooltips-subsystems.md) for why
Views, Popups, and Tooltips are kept as separate systems instead of one unified "modal" concept.

## Is this for you?

**Likely useful for:** mid-to-large projects that will keep growing UI over time (RPGs,
management/sim games, live-service or moddable games), teams where different people own
different features, and projects comfortable with a DI/module-style architecture.

**Probably not worth it for:** game jams and small games with a handful of screens. The
module/capability/registration structure costs more upfront than a handful of scenes and a
singleton would, and that cost only pays off once several independent features need to share UI
surfaces without stepping on each other.

## Requirements & installation

- Godot 4.7. [Godular](addons/godular/README.md) itself supports 4.5+; this addon has only been
  verified against 4.7.
- Copy `addons/modular_ui_architecture`, `addons/godular`, and `addons/gdb_promise` into your
  project's `addons/` folder.
- Enable the **Godular** plugin under Project Settings → Plugins. It adds the
  `GdlrModuleManager` autoload that this addon (and your own modules) run on.
- Enable the **Modular UI Architecture** plugin under the same Plugins page.
- See the [installation guide](docs/getting-started/02-installation.md) for the full steps.

## Quick start

A minimal module that registers one View and mounts it, following the demo's own conventions:

```gdscript
# my_feature.md.gd
const GameUiModule = preload("res://addons/modular_ui_architecture/modules/game_ui/game_ui.md.gd")
const GameUiTypes = preload("res://addons/modular_ui_architecture/modules/game_ui/types.gd")

const MY_VIEW_PATH := "res://my_feature/my_view.tscn"
const MY_VIEW_TOKEN := &"my_view"

static var IMPORTS := [GameUiModule]


class MyFeatureModule extends GdlrModule:
	var reg_views: CapViewsRegistry
	var svc_game_ui: CapGameUi

	func register() -> void:
		reg_views.register_view(GameUiTypes.ViewRegistration.new(MY_VIEW_TOKEN, MY_VIEW_PATH))

	func enable() -> void:
		svc_game_ui.mount_view(MY_VIEW_TOKEN)
```

For the full set of step-by-step recipes (adding a View with a toggle binding, a Popup, a
Tooltip, an Attachment into another module's View, Context, Policy Store gating), see
[`.agents/architecture/patterns.md`](.agents/architecture/patterns.md).

## The demo

`demo/` is a small playable project exercising every system: a moving character, a HUD with
buttons that open a Pause Menu, an Inventory, and a Rename dialog (all Views), a chest that
shows queued "item obtained" Popups, a quit confirmation Popup, inventory tooltips, and a
nameplate as World UI. Run `demo/content/levels/main.tscn` to try it.

### Try it yourself

These are meant to show *why* the architecture helps, not just what it does:

- **Remove a feature as a unit.** Comment out `InventoryModule` in `demo/demo.md.gd` and run
  again — the Inventory's HUD button, its keybinding, and the View itself are all gone, with no
  errors. Nothing else in the demo references the Inventory directly.
- **Remove a cross-module Attachment.** Comment out `EquipmentModule` instead — the Inventory
  still works exactly as before, just without its "Equip" button, and the HUD no longer shows
  the equipped item. Neither the Inventory nor the HUD import the `equipment` module; look at
  `demo/modules/equipment/attachments/` to see how it reaches into both.
- **Move a HUD button without touching the HUD.** Change `_slot_tag`/`_priority` on any of the
  `attachments/*.attach.gd` files in `pause_menu`, `rename_ui`, or `inventory` — the button
  reflows without a single edit to `hud.tscn`.
- **One input path, no duplicate handling.** Open the Rename dialog and type `r` into the text
  field — the `toggle_rename` hotkey doesn't fire, even though it's also bound to `r`, because
  typed input and the hotkey both go through the same `UiLayerNode`/`InputBinding` pipeline.
- **Only the topmost UI closes.** Open the Pause Menu, then press "Quit" to bring up the
  confirmation Popup, then press Escape — only the confirmation closes, not the Pause Menu
  underneath it.
- **Policy Store gates a category, not a specific UI.** Open the Inventory and walk the
  character into the chest — no reward popups appear, because the Inventory blocks
  `OPEN_GAMEPLAY_POPUP_UI` for as long as it's open. Turn off the Inventory View's **Should
  Block Inputs** in the editor first so the character can actually move while it's open, then
  try removing the `svc_policy_store.block(...)` call in `inventory.md.gd` to see the popups
  show up regardless.

## Documentation

Full user documentation lives in [`docs/`](docs/README.md). Start with the
[introduction](docs/getting-started/01-introduction.md) and the
[quick start](docs/getting-started/03-quick-start.md).

Architecture, conventions, and the reasoning behind non-obvious decisions live under
[`.agents/`](.agents/), written for AI coding agents but equally useful for human contributors.
Start at [`AGENTS.md`](AGENTS.md). See [`CONTRIBUTING.md`](CONTRIBUTING.md) before opening a PR.

`ToggleableDisplay`, `InputManager`, and `Tokens` under `demo/shared/classes/` are demo code, not
part of the addon.

## AI disclosure

This project was developed with the assistance of AI tools. The majority of the code was
written by hand; AI was used for code review, help with architecture and design decisions, and
to assist with writing documentation.

Everything in this repository has been reviewed and is maintained by the author.

## License

[MIT](LICENSE). Built on [Godular](addons/godular/README.md) and
[GdbPromise](addons/gdb_promise/README.md) (both MIT). Demo art/fonts are from
[Kenney](https://kenney.nl/).
