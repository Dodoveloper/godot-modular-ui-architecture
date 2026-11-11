# ADR-005: UI Layers Are Registered `StringName` Tokens, Not An Enum

## Status

Accepted. This is a breaking change, shipped in addon version 2.0.0, alongside
[ADR-004](004-policy-categories-as-registered-string-names.md).

## Context

UI layers were a GDScript enum, `UiLayersTypes.UiLayer`. Each member had a matching entry in
`_layers_config`, which held the layer's node script, its canvas index, and whether it blocked input.
The addon's `ui_layers/nodes/` folder contained one script per layer, and the `popups` and `tooltips`
modules imported those scripts by path.

A project could not add a layer without editing the addon. The enum has the same limitation ADR-004
describes for policy categories: its members are fixed in the script that declares them.

Adding a layer also meant the addon's own modules owned layers they didn't need to know about. The
`ui_layers` module imported the Popups and Tooltips node scripts, so the layer system depended on the
modules built on top of it.

ADR-004 solved this for policy categories by making each category a registered `StringName` token. The
same pattern fits layers, with one difference: layers are ordered, so the registration also has to
carry an order.

Alternatives considered:

- **Keep the enum and add a `CUSTOM + n` range.** This is the placeholder ADR-004 rejected. It gives no
  name and no protection against a wrong number.
- **Let each registrant pick a raw canvas index.** Two modules could pick the same index, and the
  index would be coupled to the engine's `CanvasLayer` range.
- **Relative constraints, such as `above(token)` or `below(token)`.** These need a topological sort,
  and a module would have to name the layers it sorts against. That reintroduces the "knows about other
  layers" problem.
- **A project setting or Resource listing layers.** ADR-004 rejected this for categories: removing a
  module would leave its layer behind. It also needs an editor plugin script.

## Decision

- A layer is identified by a `StringName` token. `UiLayersTypes.DEFAULT_LAYER` is the only token the
  `ui_layers` module provides. The Popups and Tooltips modules each register and export their own
  token (`PopupsTypes.POPUPS_LAYER`, `TooltipsTypes.TOOLTIPS_LAYER`). A project declares any other
  token in its own modules.
- `CapUiLayersRegistry` stores a `UiLayersTypes.UiLayerRegistration` per token. A registration holds the
  token, the node script, an integer `order`, and `should_block_inputs`. A module registers its layers
  in `register()`, the same way it registers Views and categories.
- Each registration's node script must extend `UiLayerNode`. The registry checks this with
  `Utils.static_is_type`, so a script of the wrong type is rejected at registration.
- Orders are integers, and `UiLayersTypes.Order` lists predefined anchors spaced by 100, so a module
  can register a layer between two of them. Duplicate orders are rejected.
- The registry is sealed when the layers are created in `enable()`, after every module's `register()`.
  A registration after that is rejected, so the set of layers is fixed while the game runs.
- `CapUiLayers` assigns canvas indices densely, in ascending order, when it creates the nodes. The
  engine's `CanvasLayer` range therefore doesn't limit how many layers a project can register.
- The layer scripts move into the module that owns them. The popup and tooltip layer scripts move into
  `popups/nodes/` and `tooltips/nodes/`. The addon's `ui_layers` module keeps only the default layer's
  script. The demo's `layers` module owns its HUD and Window scripts, which the demo uses as examples.

## Consequences

- **Layer order is not known at compile time.** The enum made a typo in a layer name a parse error. A
  `StringName` token is checked at runtime, so a token that no module registers fails at its first use,
  with an error from `mount_ui()` (`No UI layer registered for token`).
- **Don't revert to an enum to get compile-time checks.** That would bring back the
  "edit the addon" limitation this change removed.
- **Don't let a module import another module's layer script.** A module refers to a layer by its
  token, and the owning module registers it. The `popups` and `tooltips` modules must not import each
  other, and `ui_layers` must not import them. Keep this in step with ADR-002.
- **Keep one source of truth for each token.** Each token is declared once, in its owning module's
  `types.gd`, and everything else imports it from there. Don't repeat the string.
- **The addon doesn't know every layer.** The addon can't list all layers at compile time.
  `CapUiLayers.get_layers()` returns them at runtime, in draw order.
- **Layers are registered in `register()` and sealed at `enable()`.** Registering a layer after
  `enable()` is an error, so no layer can appear while the game runs.
- **Scenes store the token.** A `ViewRequester` or `WorldUiPortal` that saved an enum integer must be
  reset to a token. That is part of the 2.0.0 migration in
  [UI Layers](../../docs/guides/ui-layers.md#migrating-from-1x).
- **Layer order is a contract between modules.** Two layers can't share an order, so modules that
  register layers must agree on a free value. The predefined anchors reduce this to picking a gap.
