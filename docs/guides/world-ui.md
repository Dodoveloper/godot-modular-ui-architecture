# World UI

**World UI** is UI that lives in a UI layer but follows a point in the game world, such as a nameplate
above a character or a health bar above an enemy. It's positioned every frame against a world node, so
it stays attached to that node as the camera moves.

Use it through the `WorldUiPortal` helper component. It takes care of mounting, anchoring, and cleanup.

## When to use World UI

Use World UI for UI that:

- must stay attached to a moving game object;
- should be drawn on a UI layer, above the game world.

For screen-space UI, such as a HUD or a menu, use a [View](views.md). World UI is for things that
belong to the world.

## The minimal setup

1. Create your UI scene. Its root is any `Control`, such as a `Label` or a `PanelContainer`.
2. Add a `WorldUiPortal` node (a `Node` script from
   `addons/modular_ui_architecture/shared/classes/world_ui_portal/world_ui_portal.gd`) as a child of the
   UI scene.
3. Set `target_ui` to the UI scene's root. Leave `anchor_mode` at its default `NONE` for screen-fixed
   UI, or set it to `WORLD_FOLLOW` to track a world node.
4. Instance the UI scene inside your game entity, such as a player or an enemy.

The demo's nameplate works this way. Its `WorldUiPortal` is set to `WORLD_FOLLOW`, so the label stays
above the player. See `demo/modules/player/content/ui/nameplate.tscn`.

## The two anchor modes

| Mode | Behaviour |
|------|-----------|
| `NONE` | The UI is moved to its layer and keeps its own on-screen layout. It doesn't follow anything. |
| `WORLD_FOLLOW` | The UI follows `world_anchor` every frame, offset by its authored position. |

In `WORLD_FOLLOW` mode, if `world_anchor` is empty, the portal uses its owner if the owner is a
`Node2D`, otherwise the owner's parent. This is why the nameplate needs no explicit anchor.

## The exported properties

| Property | Purpose |
|----------|---------|
| `target_ui` | The `Control` to mount. It's reparented out of the portal's parent scene. |
| `target_layer` | The UI layer it's mounted on. Use `DEFAULT` unless you need something else. |
| `anchor_mode` | `NONE` or `WORLD_FOLLOW`. See above. |
| `world_anchor` | The `Node2D` to follow in `WORLD_FOLLOW` mode. Leave empty for auto-resolution. |
| `mirror_anchor_visuals` | If `true`, copies the anchor's `visible`, `modulate`, and `scale` to the UI every frame. |

The full list is in [Helper components](../reference/helper-components.md#worlduiportal).

## Mirroring visuals

When `target_ui` was a child of the entity, it inherited the entity's visibility, colour, and scale.
Once reparented into the UI layer, it no longer does. If the entity's animation or visibility is
authored on the entity node, set `mirror_anchor_visuals = true` to keep those effects.

## Timing

The UI is mounted after the portal's `_ready()`, so the target's own `@onready` values are set.
`get_managed_ui()` returns the mounted control, and mounts it now if that hasn't happened yet.

Positioning happens right before each frame is drawn, so the UI matches what's on screen. The anchor's
position is sampled once per physics tick. Engine interpolation is turned off for world-anchored UI,
because the addon interpolates it itself. The reasoning is in
[ADR-003](../../.agents/adrs/003-world-ui-positioned-pre-draw-lazy-sampled.md).

## Gotchas

- **Don't reparent the UI yourself.** The portal owns it after mounting.
- **A teleport snaps, it doesn't glide.** A large move in one tick resets the interpolation, so the UI
  doesn't slide across the screen.
- **A freed anchor unmounts the UI.** If the anchor is freed without the UI being unmounted, the addon
  prints a warning and unmounts the UI.
- **Layers are created when the graph starts.** Don't mount World UI before the module graph has started.
  The portal waits for it.

## Next

- [UI Layers](ui-layers.md): the layer the World UI mounts into.
- [Helper components](../reference/helper-components.md): every exported property.
