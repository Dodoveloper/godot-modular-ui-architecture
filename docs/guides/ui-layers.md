# UI Layers

**UI Layers** are the ordered planes that UI mounts into. The order controls both how things are
drawn (later layers are on top) and which layer receives input first.

Most of the time you only choose a layer when you mount something. The rest of the system is
handled for you.

## The layers

The addon registers one layer, `DEFAULT`. Every other layer is registered by a module, either the
addon's own modules or yours. The addon's own layers are:

| Token | Registered by | Order | Blocks input below it? | Notes |
|-------|---------------|-------|------------------------|-------|
| `UiLayersTypes.DEFAULT_LAYER` (`&"default"`) | `ui_layers` | 0 | No | Fallback, used when nothing names a layer. |
| `&"popup"` (`PopupsTypes.POPUPS_LAYER`) | `popups` | 500 | Yes | Popups. |
| `&"tooltip"` (`TooltipsTypes.TOOLTIPS_LAYER`) | `tooltips` | 600 | No | Tooltips. Only one at a time. |

The demo registers `&"hud"` and `&"window"` in its own `layers` module. Those are shown in the
[demo](../getting-started/04-demo-tour.md) and in [Registering a layer](#registering-a-layer).

The predefined orders are listed under [Choosing an order](#choosing-an-order).

## What a layer does

Each layer is a `UiLayerNode`, a `CanvasLayer` that the addon creates when the UI systems start. You
don't create or manage these nodes yourself. The addon owns them, and you mount through `CapUiLayers`
or through the services built on it (`CapGameUi` for Views, `CapPopups` for Popups).

A layer's behaviour is defined by its node script, which extends `UiLayerNode`. The base class
handles mounting, unmounting and input. You can override `_can_mount_scene` to decide what a layer
accepts. For example, the demo's `WINDOW` layer accepts a single child. See
[Registering a layer](#registering-a-layer).

A layer:

- holds the UI mounted into it;
- routes input actions to the bindings registered for that layer (see [Input Bindings](input-bindings.md));
- blocks input to the layers below it, if it is marked as blocking and currently has UI mounted.

Blocking matters for gameplay. While a Pause Menu (`WINDOW`) or a Popup is open, the player's
controls on lower layers stop receiving input, because the higher layer has consumed it.

## Input and focus

Input reaches layers in two phases, and this is where most surprises come from.

- Actions that collide with Godot's built-in focus navigation (`ui_focus_next`, `ui_focus_prev`,
  `ui_up`, `ui_down`, `ui_left`, `ui_right`) are read early, before the GUI handles them.
- Every other action is read after the GUI has had its chance.

The practical result: if a `LineEdit` has focus and the player types `r`, the text goes into the
field. A binding for `r` does not fire, because the GUI has already consumed the keystroke. The
[demo tour](../getting-started/04-demo-tour.md) shows this.

Bindings on a layer that is covered by a blocking layer don't run. The same check protects the
focus-navigation path.

> The reasoning for this split is in
> [ADR-001](../../.agents/adrs/001-ui-layer-input-broadcast-ordering.md). Don't change the order of
> those phases without reading it.

## Mounting on a layer

`CapGameUi.mount_view(token, layer)` and `CapPopups.open_popup(...)` take a layer. Pass the token of
the layer that matches the View's role:

```gdscript
svc_game_ui.mount_view(&"inventory", Tokens.Layers.WINDOW)
svc_game_ui.mount_view(&"hud", Tokens.Layers.HUD)
```

`Tokens.Layers` is the demo's own holder. Your project chooses its own constants, as described in
[Registering a layer](#registering-a-layer).

A layer that only accepts one child (as `WINDOW` and `HUD` do in the demo) refuses a second mount,
and the mount returns `null`.

## Registering a layer

A module declares a layer by registering it in `register()`, the same way it registers Views:

```gdscript
const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const MyLayerNode = preload("./content/layers/my_layer.gd")

const MY_LAYER := &"my_layer"

class MyModule extends GdlrModule:
	var reg_ui_layers: CapUiLayersRegistry


	func register() -> void:
		reg_ui_layers.register_layer(UiLayersTypes.UiLayerRegistration.new(
MY_LAYER, MyLayerNode, UiLayersTypes.Order.WINDOW + 50, true
))
```

Each registration has four parts:

- **`token`**: a unique `StringName`. An empty or already-registered token is an error.
- **`node_script`**: a script that extends `UiLayerNode`. Anything else is an error. Don't override
  `_init()` in it, because the addon creates the node with the layers service as its only argument.
- **`order`**: an integer. Layers with a higher order are drawn on top and receive input first. Two
  layers can't share an order.
- **`should_block_inputs`**: whether the layer blocks the input of the layers below it while it has
  UI mounted. Defaults to `false`.

### Choosing an order

The addon's predefined orders are in `UiLayersTypes.Order`:

| Anchor | Value |
|--------|-------|
| `DEFAULT` | 0 |
| `HUD` | 100 |
| `HUD_OVERLAY` | 200 |
| `WINDOW` | 300 |
| `OVERLAY` | 400 |
| `POPUP` | 500 |
| `TOOLTIP` | 600 |

These are anchors, not a closed list. Pick any integer. To draw a layer between two anchors, use a
value in between, such as `UiLayersTypes.Order.WINDOW + 50`. To draw a layer above everything, use a
value higher than `TOOLTIP`.

A module doesn't need to know the other layers. Registering a layer above `POPUP` puts it on top of
popups without any reference to the popups module.

### When you can register

Layers are registered during `register()`. The addon creates the layer nodes in `enable()`, after
every module has registered. Registering later pushes an error, and the layer is not created.

### Using a layer you don't own

Mount onto a layer by its token, without registering it. A module that needs the Popups layer
uses `PopupsTypes.POPUPS_LAYER` and never registers it. Registering a token twice is an error, so
only the module that owns a layer registers it.

## Reading layer state

If you need to know whether a layer is currently blocked, use `CapUiLayers.is_layer_input_blocked(layer)`.
It returns `true` when a layer drawn above `layer` is blocking input and has UI mounted.

For the full list of methods, see [Capabilities API](../reference/capabilities-api.md#capuilayers).

## Gotchas

- **A "WINDOW" View can block your own bindings.** A binding on a lower layer, such as `HUD`, will not
  run while a Window is open. Bind to the layer where the behaviour belongs.
- **Layers are created on enable.** Don't mount anything before the module graph has started.
- **Don't parent UI to a layer node yourself.** Use the mount API. It handles SceneCache and the
  ordering rules.
- **A layer can't be registered after `enable()`.** Register it in `register()`.

## Migrating from 1.x

Version 2.0.0 replaces the `UiLayer` enum with `StringName` tokens, and it moves the layer scripts
into the modules that own them:

- `UiLayersTypes.UiLayer.DEFAULT` becomes `UiLayersTypes.DEFAULT_LAYER`. The other values have no
  addon token: `POPUP` becomes `PopupsTypes.POPUPS_LAYER`, and `TOOLTIP` becomes
  `TooltipsTypes.TOOLTIPS_LAYER`. `HUD`, `WINDOW`, `HUD_OVERLAY` and `OVERLAY` become tokens your
  project declares, as in [Registering a layer](#registering-a-layer).
- Every layer parameter and property is a `StringName` now, including `ViewRequester.layer` and
  `WorldUiPortal.target_layer`. Scenes store the layer as the token, so an exported `layer` that held
  an enum integer, for example `layer = 1`, must be set to a token such as `&"hud"`.
- The layer scripts moved out of `ui_layers/nodes/`. `popups_ui_layer.gd` moved to `popups/nodes/` and
  `tooltip_ui_layer.gd` moved to `tooltips/nodes/`. The HUD and Window scripts now live in the demo, under
  `demo/modules/layers/content/layers/`. The HUD Overlay and Overlay scripts are removed. If you edited
  any of these, move the changes into your own layer script and register it.
- `UiLayerConfig` and `_layers_config` are removed. Register layers with `CapUiLayersRegistry` instead.
- The addon no longer provides `HUD`, `HUD_OVERLAY`, `WINDOW` and `OVERLAY`. Register the ones your
  project uses, as in [Registering a layer](#registering-a-layer). The demo's `layers` module is a
  working example.

## Next

- [Input Bindings](input-bindings.md): how input reaches a layer and triggers behaviour.
- [Popups](popups.md): layered overlays that use the POPUP layer.
