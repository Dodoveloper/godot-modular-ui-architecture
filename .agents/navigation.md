# Navigation

How this repository is laid out, and where to find/place things. Paths are relative to the
repo root unless stated otherwise.

## Repo root

```
/
├── AGENTS.md              # entrypoint for agents, routes into .agents/
├── CONTRIBUTING.md        # entrypoint for human contributors
├── README.md               # short, user-facing pitch
├── project.godot
├── addons/
│   ├── modular_ui_architecture/   # THE ADDON — this is what the repo ships
│   ├── godular/                    # vendored third-party DI/module framework (dependency)
│   └── gdb_promise/                 # vendored third-party promise library (dependency of godular)
├── demo/                    # playable demo project exercising the addon
├── .agents/                 # this documentation tree
├── docs/                    # (future) human-facing wiki, adapted from .agents/
└── tests/                   # (future) automated tests
```

Don't modify `addons/godular` or `addons/gdb_promise` unless the task is explicitly about
upgrading/patching a vendored dependency — they're third-party code, not part of this addon.

## `addons/modular_ui_architecture/` — the addon itself

```
addons/modular_ui_architecture/
├── modules/
│   └── <module_name>/
│       ├── <module_name>.md.gd        # the GdlrModule: IMPORTS/PROVIDERS/EXPORTS/TREE_EXPORTS
│       ├── types.gd                    # enums, value classes, InputBinding subclasses shared by this module
│       ├── capabilities/
│       │   └── <name>.cap.gd            # @abstract class_name CapXxx — the public contract
│       ├── services/
│       │   └── <name>.svc.gd            # concrete implementation of a capability
│       ├── registries/                  # (only for modules that need a registry capability)
│       │   └── <name>.reg.gd
│       └── ...module-specific dirs, e.g.:
│           ├── nodes/                    # ui_layers: UiLayerNode subclasses per UiLayer
│           ├── ui/                       # tooltips: the Tooltip base scene/script
│           └── bindings/           # popups: built-in InputBinding subclasses (e.g. close_popup)
└── shared/
    ├── classes/
    │   ├── utils.gd                       # static helpers (enum_to_str, scene-type checks, ...)
    │   ├── scene_cache.gd                 # PackedScene load cache
    │   ├── world_ui_portal/               # helper component: mounts world-anchored UI (nameplates, etc.)
    │   ├── attachment_slots_controller/   # helper component: manages Attachment Slots for a View
    │   └── view_requester/                # helper component: declaratively mounts a View on _ready
    └── resources/
        └── attachment_slot_config.gd      # Resource: configures one Attachment Slot
```

Existing modules (see [`glossary.md`](architecture/glossary.md) for what each capability does):
`game_ui`, `ui_layers`, `input_bindings`, `popups`, `tooltips`, `policy_store`.

**Rule of thumb**: a module's public contract is always in `capabilities/*.cap.gd` (the
`@abstract class_name CapXxx`). Everything else in that module is an implementation detail other
modules should not reach into directly — consume the capability, not the service/registry class.

## `demo/` — the playable demo

```
demo/
├── content/levels/         # main.tscn / main.gd — plain, non-module bootstrap scene
├── assets/                  # art, fonts, themes, tilesets
├── shared/
│   ├── classes/
│   │   ├── tokens.gd             # StringName tokens for Views etc., shared across demo modules
│   │   ├── toggleable_display.gd # base class for dismissable UI (Views/Popups), CACHED or LAZY_LOADED
│   │   └── input_manager.gd      # simple global input-block reference counter
│   └── ui/                        # generic Popup content scenes reused by multiple demo modules
│       ├── confirmation_dialog/   # yes/no confirmation Popup (e.g. confirm-quit)
│       └── attention_dialog/      # "you obtained X" queued-Popup content, animated
└── modules/
    └── <module_name>/
        ├── <module_name>.md.gd
        ├── bindings/
        │   └── <name>.bind.gd    # InputBindingsTypes.InputBinding subclasses
        ├── attachments/
        │   └── <name>.attach.gd  # GameUiTypes.UiAttachment subclasses (e.g. HUD buttons)
        └── content/
            ├── ui/                # View/Popup/Tooltip scenes + scripts
            └── entities/           # gameplay nodes (e.g. player.tscn)
```

Existing demo modules: `player`, `hud`, `pause_menu`, `rename_ui`, `inventory`, `chest`. Each is
self-contained under `demo/modules/<name>/` — see
[`patterns.md`](architecture/patterns.md) for how to add a new one following the same shape.
`chest` has no `bindings/`/`attachments/`: it's a world entity (`content/entities/chest.gd`)
that resolves `CapPopups`/`CapPolicyStore` directly, the same way `player`'s `Nameplate` resolves
`CapGameUi` via `WorldUiPortal` — not every demo module needs a binding or an attachment.

`demo/demo.md.gd` is the root module: it only composes (`IMPORTS` every demo module), no
`PROVIDERS` of its own. `demo/content/levels/main.gd` is a **plain, non-module** bootstrap
script — it `mount()`s/`start()`s `DemoModule` before anything that resolves capabilities via
`GdlrModuleManager.request()` enters the tree.

## Suffix cheat-sheet

See [`style-guide.md`](architecture/style-guide.md#file-suffixes) for the full naming
convention (`.md.gd`, `.cap.gd`, `.svc.gd`, `.reg.gd`, `.bind.gd`, `.attach.gd`).

## When To Update This Document

See [`PRINCIPLES.md`](PRINCIPLES.md) for the general rules that apply to every doc in this
tree. Specific to this file, update it when:

- a new top-level folder is added under the repo root, `addons/modular_ui_architecture/`, or
  `demo/` (e.g. a new addon module, a new `docs/`/`tests/` subfolder taking real shape)
- an existing folder's *purpose* changes (not just its contents) — e.g. a folder that used to
  be demo-only now also hosts addon code
- a new file-suffix convention is introduced (update both here and in
  [`style-guide.md`](architecture/style-guide.md))
- an agent had to `find`/`grep` broadly to locate something that should have been obvious from
  this map — that's a signal this document is missing a pointer
