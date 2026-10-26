# ADR-003: World UI Is Positioned In `frame_pre_draw`, With Lazily-Sampled Anchors

## Status

Accepted.

## Context

World-anchored UI (`CapGameUi.mount_world_ui`, used by `WorldUiPortal`) is reparented into a UI
Layer, which is a `CanvasLayer` that ignores the Camera. The service therefore converts the
anchor's world position to screen space itself, using `anchor.get_canvas_transform()`.

The original implementation had three problems, each visible as nameplates lagging behind (or
jittering against) their owner:

1. **Sampling ran in `SceneTree.physics_frame`.** That signal fires before any node's
   `_physics_process`, so the sampled position was always the previous tick's final position,
   one tick (about 16.7 ms at 60 Hz) behind the anchor.
2. **Positioning ran in `SceneTree.process_frame`.** That signal fires before any node's
   `_process`, so the UI was placed using the Camera's canvas transform from the previous frame.
   A Camera following the anchor made the lag constant, and with physics interpolation off it
   caused jitter.
3. **The UI itself had engine physics interpolation on.** The service writes its position every
   rendered frame, so the engine interpolated it a second time, adding more trailing.

## Decision

- Anchors are sampled **lazily, at render time, at most once per physics tick**.
  `_sample_anchor` compares `Engine.get_physics_frames()` with the last sample and only then
  shifts the `prev`/`curr` buffers.
- World-anchored UI is positioned in **`RenderingServer.frame_pre_draw`**, which runs after all
  `_process` calls and camera updates, right before drawing.
- Position is interpolated only when the anchor reports
  `is_physics_interpolated_and_enabled()`. Otherwise the anchor's live position is used, so the
  service works whether project physics interpolation is on or off.
- World-anchored UI sets `physics_interpolation_mode = PHYSICS_INTERPOLATION_MODE_OFF`, since the
  service already positions it by hand.
- `SceneTree.physics_frame` is still used, for View context polling only.

## Rejected Alternatives

- **Sampler node with a late `process_physics_priority`.** A small node that samples every anchor
  in its own `_physics_process`, after the anchors have moved. This is exact even when several
  ticks run per rendered frame, because every tick is observed. It was rejected because it adds a
  node to the tree and a second system to keep in sync, while the lazy approach is exact at any
  fps at or above the physics tick rate. Revisit this if the known limitation below becomes a
  problem for users (see Consequences).
- **Lazy sampling in `process_frame`.** Rejected because `process_frame` runs before `_process`,
  so the UI would be placed with the previous frame's Camera transform (see Context, problem 2).
- **`Node2D.get_global_transform_interpolated()`.** Does not exist in 2D. The interpolated
  transform is only exposed for `Node3D`, so the service has to rebuild the 2D interpolation from
  the sampled positions.
- **Keeping engine interpolation on the UI and positioning in `physics_frame`.** Rejected because
  it leaves the one-tick sampling lag and the double-interpolation lag in place.

## Consequences

- **Known limitation:** when several physics ticks run within one rendered frame (fps below the
  physics tick rate, e.g. 30 fps with 60 ticks/s), the intermediate tick positions are not
  observed. The interpolated position then lags by up to about one rendered frame of motion. This
  affects the anchor (the player) as well as the UI, and is most visible when fps is capped below
  a higher monitor refresh rate. This is accepted as a trade-off against the cost of the sampler
  node above.
- Headless runs never emit `RenderingServer.frame_pre_draw` (the dummy renderer doesn't draw), so
  world UI doesn't move in `--headless` mode. Test positioning in a windowed run.
- Don't move positioning back into `process_frame`/`physics_frame` "for consistency" with the
  physics-tick sampling. That reintroduces the one-frame camera lag described above.
- Don't re-enable engine physics interpolation on world-anchored UI. It adds a second layer of
  smoothing on top of the service's own.
