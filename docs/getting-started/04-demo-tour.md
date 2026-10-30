# Demo tour

The `demo/` folder in this repository is a small, playable project that uses every system in the
addon. Run `demo/content/levels/main.tscn` to try it. This page maps the demo's folders to the
features they show, and lists experiments that make the architecture visible.

Everything under `demo/` is **demo code, not addon code**. The addon lives only under
`addons/modular_ui_architecture/`. The demo's helper classes (`ToggleableDisplay`, `InputManager`,
`Tokens`) are conventions the demo uses. You can reuse them, but they are not part of the addon and
their API may change independently.

## What the demo contains

| Demo module | Shows | Key files |
|-------------|-------|-----------|
| `player` | A moving character and a World UI nameplate. | `content/entities/player.gd`, `content/ui/nameplate.tscn` |
| `hud` | The HUD View with three bottom slots (`bottom_left`, `bottom_center`, `bottom_right`). | `hud.md.gd`, `content/ui/hud.tscn` |
| `pause_menu` | A View toggled by a key and a HUD button, a confirmation Popup, and a Policy Store block. | `pause_menu.md.gd`, `bindings/toggle_pause_menu.bind.gd`, `attachments/pause_menu_button.attach.gd` |
| `rename_ui` | A View toggled by a key, with a text field so you can see keystrokes reach the field. | `rename_ui.md.gd`, `bindings/toggle_rename.bind.gd` |
| `inventory` | A View with item slots, item Tooltips, a Context, and a footer slot for other modules. | `inventory.md.gd`, `content/ui/inventory.gd` |
| `equipment` | Two Attachments contributed into *other* modules' Views, without importing them. | `equipment.md.gd`, `attachments/equip_button.attach.gd`, `attachments/equipped_item_label.attach.gd` |
| `chest` | An entity that queues several reward Popups, gated by Policy Store. | `content/entities/chest.gd` |

The root `demo/demo.md.gd` only composes the demo modules by importing them. It declares no providers
of its own.

Two shared folders hold generic demo code:

- `demo/shared/classes/`: `ToggleableDisplay` (a base class for dismissable Views and Popups),
  `InputManager` (a global input-block counter), and `Tokens` (View token constants).
- `demo/shared/ui/`: a `confirmation_dialog` and an `attention_dialog`, reused by several modules.

## Experiments

These show *why* the architecture helps, not just what it does. Each one is safe to undo.

**Remove a feature as a unit.** Comment out `InventoryModule` in `demo/demo.md.gd` and run again. The
Inventory's HUD button, its keybinding, and the View all disappear, with no errors. Nothing else in the
demo references the Inventory directly. (`equipment` still loads, but its Equip button is gone because
its target View is gone.)

**Remove a cross-module Attachment.** Comment out `EquipmentModule` instead. The Inventory works as
before, without its Equip button, and the HUD no longer shows the equipped item. Neither the Inventory
nor the HUD imports the `equipment` module. Look at `demo/modules/equipment/attachments/` to see how it
reaches both.

**Move a HUD button without touching the HUD.** In `pause_menu`, `rename_ui`, or `inventory`, change
`_slot_tag` or `_priority` in the `*.attach.gd` file. The button reflows without any edit to `hud.tscn`.

**One input path for keys and buttons.** Open the Rename dialog and type `r` into its text field. The
`toggle_rename` hotkey is also bound to `r`, but it doesn't fire, because the focused `LineEdit`
receives the keystroke first. The explanation is in [Input Bindings](../guides/input-bindings.md) and
[UI Layers](../guides/ui-layers.md).

**Only the topmost UI closes.** Open the Pause Menu, press **Quit** to show the confirmation Popup, then
press **Escape**. Only the confirmation closes, not the Pause Menu underneath it.

**Policy Store gates a category, not a specific UI.** Open the Inventory and walk the character into the
chest. No reward Popups appear, because the Inventory blocks `OPEN_GAMEPLAY_POPUP_UI` while it is open.
To see the Popups appear regardless, comment out the `svc_policy_store.block(...)` call in
`inventory.md.gd`. The Inventory's **Should Block Inputs** is on by default, so turn it off in the
Inventory's scene first, or the character can't move while it is open. See
[Policy Store](../guides/policy-store.md).

### Challenge: modularize the inventory slots

The Inventory's six item slots are static children of `SlotsGrid` in `inventory.tscn`. This challenge
moves them out of the scene, so a module adds each slot instead. It uses an Attachment Slot, an
Attachment, and Context, which are the main parts of the addon.

Work it out yourself first. The steps below are a guide, not a solution.

1. **Make the grid a slot.** The Inventory already has an `AttachmentSlotsController` under
   `PanelContainer`, which holds the `footer` slot. Add a second entry to its **Slot Configs**, with the
   key `slots_grid`, a `node_path` that points at `SlotsGrid` relative to the controller, and
   `max_children = -1` for no limit. Use the `footer` entry as the pattern.
2. **Remove the static slots.** Delete the `InventorySlot` nodes from `SlotsGrid`. Keep the
   `SlotsGrid` node itself. The grid must still be `unique_name_in_owner`, as `inventory.gd` uses
   `%SlotsGrid`.
3. **Create an Attachment.** Add a new file under `demo/modules/inventory/attachments/`, for example
   `item_slot.attach.gd`. Extend `GameUiTypes.UiAttachment`, set `_slot_tag` to `&"slots_grid"` in
   `_init()`, and set `_Scene` to the `inventory_slot.tscn` scene. Set the slot's `item_name`,
   `item_description` and `texture` in `_build()`, which runs once per item.
4. **Register the Attachments.** In `inventory.md.gd`, register one Attachment per item, using the
   `reg_attachments` registry the module already has. Each Attachment's `_priority` decides its
   order inside the grid.
5. **Check the wiring.** `inventory.gd` connects `item_selected` only to the children that exist in
   `_ready()`. A slot mounted later never gets that connection. Find a way for the Context to receive
   the selection (`context.selected_item_name`) from a slot that the module adds. Hint: the
   `InventorySlot` already emits `item_selected` itself, so the Attachment can connect to it in
   `_build()`, and disconnect it in `_on_instance_tree_exiting()`.

Expected result: the Inventory looks the same, the Equip button still reads the selected item, and
removing `InventoryModule` still removes every slot with it.

Things to check when it doesn't work:

- A `_slot_tag` that doesn't match a key in `slot_configs` logs `Slot '...' not found. Ignoring`.
- A slot that is full logs `Slot '...' does not have space left`.
- An Attachment with no `AttachmentSlotsController` in its View mounts nothing, and no error appears.

See [Attachments and Attachment Slots](../guides/attachments-and-slots.md) for the rules behind each
step.

## Next

Continue with the concepts, starting with the [Architecture overview](../concepts/01-architecture-overview.md).
