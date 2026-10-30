# Project conventions

The file layout and naming used by the addon and the demo. Following these keeps your modules
consistent with the rest of the codebase, and makes the addon's own patterns easy to recognise.
Nothing here is enforced by a tool, so these are conventions, not lint rules.

## File suffixes

Every module folder uses fixed suffixes:

| Suffix | Meaning | Example |
|--------|---------|---------|
| `.md.gd` | The module: `IMPORTS`, `PROVIDERS`, `EXPORTS`, `TREE_EXPORTS`, and `register()`/`enable()`. | `pause_menu.md.gd` |
| `.cap.gd` | A capability contract, `@abstract class_name CapXxx`. | `game_ui.cap.gd` |
| `.svc.gd` | A service that implements a capability. | `game_ui.svc.gd` |
| `.reg.gd` | A registry, which stores registered data. | `input_bindings.reg.gd` |
| `.bind.gd` | An `InputBinding` subclass. | `toggle_pause_menu.bind.gd` |
| `.attach.gd` | A `UiAttachment` subclass. | `pause_menu_button.attach.gd` |

`types.gd` (no suffix) holds a module's enums, value classes, and base-class extensions.

## Folder shape

Feature modules in your project can follow the same shape as the demo's. Keep each feature in its own
folder, with its own module script:

```
res://my_feature/
├── my_feature.md.gd
├── bindings/
│   └── toggle_hello.bind.gd
├── attachments/
│   └── hello_button.attach.gd
└── content/
    ├── hello_view.tscn
    └── hello_view.gd
```

The demo uses `content/ui/` for Views and Popups, and `content/entities/` for gameplay nodes. Use
whichever split fits your project, and keep the subfolder names consistent across modules.

The addon's own folders follow the same shape: `modules/<name>/` holds the module, its capabilities,
services, and registries, and `shared/` holds helper components and resources.

## Imports and class names

Prefer `const Name = preload("...")` over `class_name`:

```gdscript
const PauseMenuButtonAttachment = preload("./attachments/pause_menu_button.attach.gd")
```

Use `class_name` only for types that need to be visible everywhere, such as capability contracts,
`Tooltip`, and resources you want to create in the editor. A script used by a handful of files
doesn't need one.

Never give a `preload` constant the same name as a global `class_name`.

## Names

- Capability names start with `Cap`, such as `CapGameUi`.
- Capability and provider files use the suffixes above.
- View tokens and action names are `StringName` literals, written with `&"..."`, such as `&"inventory"`
  and `&"toggle_inventory"`.
- Use `String` for display text.
- Put shared tokens in one place. The demo's `Tokens` class is an example, but it is demo code, not
  part of the addon.

## Context naming

In this addon, "Context" means only the `context` property on a View. Don't use the word for other
state. See [Context](../guides/context.md).

## Scenes

- Create `.tscn` files in the editor, not by hand. The editor writes the UIDs, and hand-edited scenes
  can lose them.
- Add `AttachmentSlotsController`, `ViewRequester`, and `WorldUiPortal` as instanced scenes, not as
  scripts attached to a plain node.

## Next

- [Helper components](helper-components.md): the scenes you instance.
- [Modules and capabilities](../concepts/02-modules-and-capabilities.md): the modules these files define.
