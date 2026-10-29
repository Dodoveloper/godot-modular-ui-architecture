# Component model

The addon uses a three-level vocabulary for UI: **Elements**, **Widgets**, and **Views**. The code
enforces only one of these levels directly, but the vocabulary helps you decide where a piece of UI
belongs.

## The three levels

| Level | What it is | Enforced by the addon? |
|-------|------------|------------------------|
| **Element** | Small, reusable, context-free UI. Buttons, icons, a label, a tooltip's visual shell. | No. It's a naming convention. |
| **Widget** | Reusable UI that receives Context and is mounted into a View through an Attachment. | No. Mounted through `UiAttachment`. |
| **View** | Top-level UI, registered under a unique token, with at most one active instance per token. | Yes, through `CapGameUi`. |

## Choosing a level

Ask these questions about a piece of UI:

- **Does it need Context, mounting, or Attachment?** If yes, it's a **Widget**. If no, it's an
  **Element**.
- **Could a module reasonably want to inject it?** If yes, it's a **Widget**.
- **Does it represent behaviour tied to game systems?** If yes, it's a **Widget**.
- **Is it a full screen or window that holds its own state?** If yes, it's a **View**.

A plain `Button` is an Element. A "Equip" button that reads the inventory's selected item is a
Widget, because it reacts to a View's Context. An entire Inventory is a View.

## What each level may do

- **Elements** stay dumb. They have no knowledge of your game and don't resolve capabilities.
- **Widgets** receive Context from the View they're mounted into, and may call capabilities through
  their Attachment's injected services. A Widget should not reach into the View's internals. Use
  Context for that.
- **Views** own their state and expose a Context if their Attachments need it. A View should not
  know which Widgets it hosts. It only declares the slots they can use.

## Why it matters

Following these rules is what lets the same Widget appear in two Views. Each View offers a
slot and a Context, and each Attachment maps the View's Context onto the Widget's own fields. The
Widget itself stays the same.

None of the three tiers has a base class in the addon. Views are enforced by `CapGameUi` (mounting,
and one instance per token), not by inheritance. Element and Widget are conventions. The demo's
`ToggleableDisplay` is one example View implementation. It is demo code, not a required base class.
Nothing stops you from putting Context into an Element, but following the rules above keeps the
pieces easy to reuse.

## Next

Continue to the guides, starting with [Views](../guides/views.md).
