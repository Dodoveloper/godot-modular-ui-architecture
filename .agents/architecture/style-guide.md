# Style Guide

Naming, file-layout, and GDScript conventions for this repo. Verified against the current
codebase per [`PRINCIPLES.md`](../PRINCIPLES.md) — where a rule below isn't yet enforced by
tooling (no `.gdlintrc`/`.gdformatrc` exists in this repo today), it's stated as a followed
discipline, not an asserted lint rule.

## File Suffixes

Every file under `addons/modular_ui_architecture/modules/<name>/` and `demo/modules/<name>/`
follows a fixed suffix convention. Don't invent a new one without updating this table and
[`navigation.md`](../navigation.md):

| Suffix        | Meaning                                                                      | Example |
|---------------|-------------------------------------------------------------------------------|---------|
| `.md.gd`      | The module itself (`GdlrModule`): `IMPORTS`/`PROVIDERS`/`EXPORTS`/`TREE_EXPORTS`, `register()`/`enable()` | `pause_menu.md.gd` |
| `.cap.gd`     | A capability contract (`@abstract class_name CapXxx extends GdlrCapability`) | `game_ui.cap.gd` |
| `.svc.gd`     | A concrete service implementing a capability                                | `game_ui.svc.gd` |
| `.reg.gd`     | A concrete registry implementing a registry capability                      | `input_bindings.reg.gd` |
| `.bind.gd`    | An `InputBindingsTypes.InputBinding` subclass                                | `toggle_pause_menu.bind.gd` |
| `.attach.gd`  | A `GameUiTypes.UiAttachment` subclass                                        | `pause_menu_button.attach.gd` |

`types.gd` (no special suffix) holds a module's enums, value classes, and any
`InputBinding`/other base-type extensions specific to it.

## Imports And Global Classes

**Default to `const Foo = preload(...)`, PascalCase, not `class_name`.** This is how the vast
majority of this codebase references its own types — module scripts, services, bindings,
attachments, and content scripts all preload each other by path:

```gdscript
const PauseMenuButtonAttachment = preload("./attachments/pause_menu_button.attach.gd")
const Hud = preload("res://demo/modules/hud/content/ui/hud.gd")
```

Reserve `class_name` for types that genuinely need global visibility or editor integration —
in practice, that means: every `Cap*` capability contract, a `UiLayerNode`/`Tooltip`/
`ToggleableDisplay`-style base class meant to be widely subclassed, an `@export`-able
`Resource` (`AttachmentSlotConfig`), or a small shared value holder consumed everywhere without
a natural "owning" import site (`Tokens`). If you're adding a one-off script that only a
handful of files reference, it almost certainly wants `preload`, not `class_name`. Never create
a preload constant with the same name as an existing global class.

## Documentation Comments

Use `##` doc comments for capabilities, public methods on them, exported fields, and non-obvious
signals — this codebase already does this consistently (see any `*.cap.gd`). Use Godot doc tags
(`[param]`, `[method]`, `[signal]`, `[code]`, `[br]`) when referring to code symbols:

```gdscript
## Blocks a policy [param category] for a given [param source].[br]
## Multiple sources may block the same category simultaneously.
@abstract func block(category: PolicyStoreTypes.Category, source: Object) -> void
```

## Dictionary Shape Comments

Document non-uniform `Dictionary` shapes with `@shape`, matching the existing convention (see
`game_ui.svc.gd`, `policy_store.svc.gd`, `attachment_slots_controller.gd`):

```gdscript
## Cached context values per View.[br]
## [codeblock]
## @shape: {
##   [view: Node]: [context_values: {
##     [property_name: String]: [property_value: Variant]
##   }
## }
## [/codeblock]
var _cached_context_values: Dictionary[Node, Dictionary] = {}
```

Prefer dot notation for `Dictionary` access when the key is static/known; use bracket notation
for dynamic keys. Don't add defensive double reads for `String`/`StringName` key mismatches —
Godot treats them as equivalent for `Dictionary` lookup already; if a serialized/external
payload seems to need normalization, prove the mismatch first rather than guarding
speculatively.

## TODO Comments

Use single-hash `# TODO:` comments, placed before any `##` doc comment on the same
declaration (see `game_ui.svc.gd`):

```gdscript
# TODO: eventually, Views may override convention methods (e.g. on_open, on_close)
# to implement animations, staying in the tree, or reusing instances.
func mount_view(token: StringName, layer := UiLayersTypes.UiLayer.DEFAULT) -> Node:
```

## Static Typing

Use static typing throughout — this is a followed discipline in every file read so far in this
codebase, even though no `.gdlintrc` currently enforces it. Use `:=` when the right-hand side
makes the type obvious; use an explicit `: Type` when inference is ambiguous or for typed
`Array`/`Dictionary` declarations:

```gdscript
var _is_blocking_inputs := false
var _bindings_by_action: Dictionary[StringName, Array] = {}
var enemies: Array[Node2D] = []
```

Always declare function return types, including `-> void` for side-effect-only methods. Typed
`Array`/`Dictionary` literals can lose their element type through `filter()`/`map()` — assign
through an already-typed variable when that matters.

The UI layer pipeline uses `Node` as its element type: `UiLayerNode.get_mounted_nodes()` returns
`Array[Node]`, and public mount/unmount signatures take `Node`. Narrowing to `Control` happens after
`_can_mount_scene()` checks the scene, and never in a public signature. Typed containers reject
`has()` for a value of the wrong type, so a `Control`-typed container must not be queried with a
plain `Node` — compare by iteration, or keep the element type `Node`.

## Naming

- Files: `snake_case.gd`, with the suffix table above.
- Functions, variables, signals, loop variables: `snake_case`.
- Private members: leading underscore (`_svc_game_ui`, `_on_button_pressed`).
- Classes and preload constants: `PascalCase`.
- Constants and enum members: `UPPER_SNAKE_CASE`.
- Signal handlers: `_on_<subject>_<signal_past_tense>` (e.g. `_on_pause_menu_close_requested`);
  drop `<subject>` only when there's no ambiguity in that scope.

## Regions

Use `#region`/`#endregion` sparingly — this codebase has exactly two real uses
(`game_ui.md.gd`, `toggleable_display.gd`), both wrapping a small, clearly-named group of
related declarations. If a region is hiding genuinely unrelated responsibilities, split the
file instead of adding another region.

## Lambdas

Keep lambdas short and local — mainly for `Array.filter()`/`.map()`, `GdbPromise` callbacks
(see `module_graph.gd`), and trivial one-line signal adapters. Prefer a named private method
over a lambda once the callback branches, awaits, or needs to be disconnected later — store the
`Callable` or use a named method in that case so `disconnect()` remains possible.

## Lifecycle And Memory

- Prefer `RefCounted` for pure data/logic classes with no scene-tree behavior (every
  capability, service, registry, and `InputBinding`/`UiAttachment` in this codebase is
  `RefCounted`-based, not `Node`-based).
- Use `queue_free()` for nodes (see every `_unmount_node` implementation). Reserve bare `free()`
  for non-node `Object` instances with a controlled, single-frame teardown.
- `@onready` fields are unavailable in `_init()`/`_enter_tree()`. This codebase's own helper
  components follow the pattern consistently: `_init()`/`_enter_tree()` for DI resolution
  (`GdlrModuleManager.request(...)`), `_ready()` for child references and signal wiring — see
  `world_ui_portal.gd` and `attachment_slots_controller.gd`.
- After an `await` (e.g. `Utils.await_module_graph_started()`), re-check node validity before
  touching the tree if the awaited signal could outlive the node.

## Dependencies And Loading

Use `preload()` with literal paths for scripts/scenes a file always needs (the overwhelming
majority of this codebase's dependencies). Use `load()` — or
`SceneCache.load_scene(path)`
(`addons/modular_ui_architecture/shared/classes/scene_cache.gd`) for **paths only known at
runtime**, or when the same scene may be mounted/unmounted repeatedly and benefits from the
cache. `UiLayerNode.mount_node()` already goes through `SceneCache.load_scene` internally —
don't preload a scene *and* pass its path through `mount_node`/`CapGameUi.mount_view` in the
same flow, that defeats the cache and double-loads.

Cyclic preloads can break project load. If two scripts need each other, route the shared piece
through a capability/`types.gd`, or fall back to a runtime `load()` at the one call site that
needs it.

## Data Values

Use `StringName` for identifiers compared repeatedly (action names, View/tooltip tokens,
Policy Store categories via enum, dictionary keys meant for fast lookup) — see `Tokens.gd` and
every `&"..."` action name in this codebase. Use `String` for display text and anything that
gets string-manipulated (e.g. `Player.character_name`).

## Godot MCP / Scene-Editing Gotchas

When Godot MCP tools (`add_node`, `create_scene`, etc.) resave a `.tscn`, they can **strip the
`uid=` attribute** from the scene's own header and from its `ext_resource` entries. This breaks
`uid://` references elsewhere in the project pointing at that scene/script. After an MCP tool
resaves a scene:

1. Check whether `uid="uid://..."` is still present on the `[gd_scene ...]` line and on any
   `[ext_resource type="Script" ...]` lines that had one before.
2. If a `uid=` got stripped, open the affected scene in the Godot editor and resave it there
   (or use `godot__update_project_uids`) to regenerate/restore the UID — don't hand-write a UID
   value into the `.tscn` text.

Prefer the MCP tools (or the editor directly) over hand-editing `.tscn` node trees — the format
is order- and index-sensitive in ways that are easy to get subtly wrong by hand. Hand-editing a
`.tscn` is acceptable for small, targeted changes to properties on nodes that already exist
(e.g. setting an exported value), but not for restructuring the node tree.

## When To Update This Document

See [`PRINCIPLES.md`](../PRINCIPLES.md) for the general rules that apply to every doc in this
tree. Specific to this file, update it when:

- a new file-suffix convention is introduced (update both here and in
  [`navigation.md`](../navigation.md))
- a convention below is contradicted by a substantial fraction of newly-written or newly-read
  code — reconcile the doc with what the codebase actually does, don't just add an exception
- a new Godot/tooling gotcha is discovered that could plausibly cost a future agent real time
  (like the UID-stripping behavior above)
- a `.gdlintrc`/`.gdformatrc` (or equivalent) is added to the repo — at that point, rules here
  that are currently "followed discipline" should be reconciled with what's actually enforced

