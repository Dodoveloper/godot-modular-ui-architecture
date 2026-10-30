# UI Layers

**UI Layers** are the ordered planes that UI mounts into. The order controls both how things are
drawn (later layers are on top) and which layer receives input first.

Most of the time you only choose a layer when you mount something. The rest of the system is
handled for you.

## The layers

| Layer | Draw order | Blocks input below it? | Notes |
|-------|-----------|------------------------|-------|
| `DEFAULT` | 1 (lowest) | No | Fallback. |
| `HUD` | 2 | No | HUD Views. Only one child may be mounted at a time. |
| `HUD_OVERLAY` | 3 | No | Overlays on top of the HUD. |
| `WINDOW` | 4 | Yes | Exclusive Views. Only one child may be mounted at a time. |
| `OVERLAY` | 5 | Yes | Overlays above windows. |
| `POPUP` | 6 | Yes | Popups. |
| `TOOLTIP` | 7 (highest) | No | Tooltips. Only one at a time. |

The order and the input-blocking flags are set by the addon and can't be changed by your code.

## What a layer does

Each layer is a `UiLayerNode`, a `CanvasLayer` the addon creates when the UI systems start. You don't
create or manage these nodes yourself. The addon owns them, and you mount through `CapUiLayers` or
through the services built on it (`CapGameUi` for Views, `CapPopups` for Popups).

Every layer has its own script in `addons/modular_ui_architecture/modules/ui_layers/nodes/`, and
each script extends `UiLayerNode`. The scripts are where layer-specific rules live. For example,
`WindowUiLayerNode` and `HudUiLayerNode` override `_can_mount_scene` to accept only one child. The
`HUD` script is currently identical to the `WINDOW` script, but it is separate so you can change
the HUD's behaviour without affecting `WINDOW`. See [Customizing a layer](#customizing-a-layer).

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

`CapGameUi.mount_view(token, layer)` and `CapPopups.open_popup(...)` take a layer. For a View, pass the
layer that matches its role:

```gdscript
svc_game_ui.mount_view(&"inventory", UiLayersTypes.UiLayer.WINDOW)
svc_game_ui.mount_view(&"hud", UiLayersTypes.UiLayer.HUD)
```

The `WINDOW` and `HUD` layers accept only one child. Mounting a second View there is refused, and the
mount returns `null`.

## Customizing a layer

Each layer's script is listed in `_layers_config` in `ui_layers.svc.gd`. To change how a layer
behaves:

1. Edit that layer's script in `modules/ui_layers/nodes/`. Each one extends `UiLayerNode`. The
   `DEFAULT`, `HUD_OVERLAY` and `OVERLAY` scripts are empty, so they use the base behaviour. The
   `HUD` and `WINDOW` scripts accept one child. Override the methods you need, such as
   `_can_mount_scene` (decide what the layer accepts) or `_mount_node` and `_unmount_node` (decide
   how a node is added and removed).
2. If you want a layer to use a different script, change its entry in `_layers_config`.

The layer scripts are `default_ui_layer.gd`, `hud_ui_layer.gd`, `hud_overlay_ui_layer.gd`,
`window_ui_layer.gd`, `overlay_ui_layer.gd`, `popups_ui_layer.gd` and `tooltip_ui_layer.gd`.

> The addon is part of your project, so these edits apply to that project only. An addon upgrade
> may overwrite them, so record your changes and reapply them after upgrading.
>
> **Current limitation:** you can't add a new layer from your own module. A new `UiLayer` value needs
> a matching entry in `ui_layers/types.gd`, a node script, and an entry in `_layers_config`, all in the
> addon. Registering layers from your own modules is a planned improvement, noted in the
> [README](../../README.md#potential-improvements).

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

## Next

- [Input Bindings](input-bindings.md): how input reaches a layer and triggers behaviour.
- [Popups](popups.md): layered overlays that use the POPUP layer.
