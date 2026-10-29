# Introduction

Modular UI Architecture helps you build game UI as a set of independent features instead of one
tangle of scripts. A feature registers what it needs, such as a View, a HUD button, or a keybinding,
without editing the scenes it attaches to. Remove the feature's module and everything it
contributed goes with it.

## The problem it solves

UI tends to accumulate coupling as a game grows:

- A HUD script ends up holding references to the inventory, the quest log, and the pause menu.
- A new feature means editing scenes owned by other systems.
- Removing a feature means hunting down every place that still reaches into it.
- Pressing Escape closes three overlapping windows at once.
- A hotkey fires while a text field has focus.
- "Don't open a popup while paused" gets hardcoded into every popup, rather than declared once.

This addon addresses these problems by making UI modular at the architecture level.

## What it gives you

- **Views**: top-level UI such as a HUD, a Pause Menu, or an Inventory. Each View is mounted and
  unmounted by a token, and there is at most one active instance per token. See [Views](../guides/views.md).
- **Attachments and Attachment Slots**: a module can mount a Widget into another module's View,
  such as a HUD button or a footer button in the Inventory. The host View doesn't know the
  Attachment exists. See [Attachments and Attachment Slots](../guides/attachments-and-slots.md).
- **Context**: state a View exposes so its Attachments can react to it. See [Context](../guides/context.md).
- **Input Bindings and UI Layers**: a key and its equivalent button go through the same binding,
  scoped to a UI layer. A focused text field keeps typed characters instead of losing them to an
  unrelated hotkey. See [Input Bindings](../guides/input-bindings.md) and [UI Layers](../guides/ui-layers.md).
- **Popups**: dismissable overlays with click-outside and Escape dismissal, optional parent and
  child hierarchies with blocking children, and a FIFO queue for popups that must not overlap.
  See [Popups](../guides/popups.md).
- **Tooltips**: a single hover tooltip that tracks its anchor. See [Tooltips](../guides/tooltips.md).
- **World UI**: UI that sits in a UI layer but follows a game-world node every frame, such as a
  nameplate. See [World UI](../guides/world-ui.md).
- **Policy Store**: a category of interaction (for example, "open a popup from gameplay") that any
  code can block, without the gated code knowing who is blocking it or why.
  See [Policy Store](../guides/policy-store.md).

## Is this for you?

**Likely useful for:** mid-to-large projects that will keep growing their UI over time, such as
RPGs, management or simulation games, and games designed to be modded. It also suits teams where
different people own different features, and projects comfortable with a dependency-injection,
module-style architecture.

**Probably not worth it for:** game jams and small games with a handful of screens. The module,
capability, and registration structure costs more up front than a few scenes and a singleton. It
pays off once several independent features must share UI surfaces without stepping on each other.

## What this addon is not

- It doesn't provide widgets, themes, or layouts. Your scenes provide those.
- It doesn't provide gameplay state. Inventories, quests, and player data stay in your own code.
- It doesn't replace Godot's `Control` system or its focus model. It works with them. See
  [UI Layers](../guides/ui-layers.md) for how input reaches UI.

## Next

Continue to [Installation](02-installation.md).
