# Modules and capabilities

Everything in this addon is provided through **modules** and **capabilities**, from the
[Godular](https://github.com/RafaelVidaurre/godular) dependency framework. This page covers what you
need to use the addon. For the full framework (including middleware, commands, and jobs), read the
[Godular documentation](https://rafaelvidaurre.github.io/godular/).

## Capabilities are contracts

A capability is an abstract class. It names what a service does, without saying how. Consumers
depend on the capability, so the implementation can change without touching them.

By convention, capability classes are named `Cap*`, such as `CapGameUi`. The addon declares its
capabilities in `*.cap.gd` files. You never instantiate them. You receive a working implementation
through injection.

## Modules declare what they provide and need

A module is a class extending `GdlrModule`, in a `*.md.gd` file. Its static members describe the
module graph:

| Member | Meaning |
|--------|---------|
| `IMPORTS` | Other modules this one depends on. Godular starts them first. |
| `PROVIDERS` | Which implementation to build for each capability this module owns. |
| `EXPORTS` | Capabilities that modules importing this one may use. |
| `TREE_EXPORTS` | Capabilities any node can request at runtime, with `GdlrModuleManager.request()`. |

Your feature module imports the addon's modules it needs, then uses their capabilities:

```gdscript
# my_feature/my_feature.md.gd
const GameUiModule = preload("res://addons/modular_ui_architecture/modules/game_ui/game_ui.md.gd")

static var IMPORTS := [
	GameUiModule,
]
```

## Injection by type

Declare a typed property on your module class, and Godular fills it in before your lifecycle methods
run:

```gdscript
class MyFeatureModule extends GdlrModule:
	var svc_game_ui: CapGameUi
	var reg_views: CapViewsRegistry
```

Only capabilities the module can see are injected. That means capabilities provided by the module
itself, or exported by a module it imports. Declaring a type you can't see leaves the property `null`.
The [FAQ](../faq-and-troubleshooting.md) covers this.

## The lifecycle you need to know

1. **Mount.** Godular builds the module graph, imports first.
2. **Inject.** Typed properties receive their capabilities.
3. **`register()`** runs on every module, synchronously. Register Views, bindings, Attachments, and
   anything else here.
4. **`enable()`** runs in dependency order. It may `await`. A module's `enable()` runs only after its
   imports have finished theirs.

Use `register()` for registration, and `enable()` for work that needs the whole graph to be ready.
The addon's own `enable()` methods start its systems (for example, creating UI layer nodes), so
don't resolve a capability's runtime state before the graph has started.

## Starting the graph

Mount the root module once, and start it, before resolving capabilities:

```gdscript
# main.gd
extends Node

const MyFeatureModule = preload("res://my_feature/my_feature.md.gd")


func _ready() -> void:
	await GdlrModuleManager.mount(MyFeatureModule)
	await GdlrModuleManager.start()
```

Nodes that aren't modules, such as a Popup opener, a hover-reactive tooltip source, or a world entity,
can resolve a capability with `GdlrModuleManager.request()`, passing themselves as the consumer:

```gdscript
var _svc_popups: CapPopups


func _ready() -> void:
	_svc_popups = GdlrModuleManager.request(CapPopups, self)
```

Only call `request()` after `GdlrModuleManager.start()` has returned. A node that enters the tree
earlier must wait for the graph to start first. The addon's own helper components do this by awaiting
the graph before resolving, and you can do the same by awaiting `GdlrModuleManager.graph_started`
(a signal with one argument, the graph) if the graph isn't started yet. The
[FAQ](../faq-and-troubleshooting.md) covers the symptom.

## What the addon provides

Each addon module and its capability:

| Module | Capability | Purpose |
|--------|------------|---------|
| `ui_layers` | `CapUiLayers` | The ordered UI layers and their input routing. |
| `input_bindings` | `CapInputBindings`, `CapInputBindingsRegistry` | Keybindings and their registry. |
| `game_ui` | `CapGameUi`, `CapViewsRegistry`, `CapUiAttachmentsRegistry` | Views, Attachments, and World UI. |
| `popups` | `CapPopups` | Dismissable overlays. |
| `tooltips` | `CapTooltips` | Hover tooltips. |
| `policy_store` | `CapPolicyStore` | Blocking categories of interaction. |

Importing a module makes its exported capabilities available to you. Each guide names the module
it needs.

## Next

Continue to [Component model](03-component-model.md).
