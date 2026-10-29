# Modular UI Architecture — Documentation

Modular UI Architecture is a set of runtime systems for building modular, reusable, and extensible
UI in Godot 4.7. Features contribute Views, HUD buttons, keybindings, Popups, and Tooltips on their
own, without editing the scenes they attach to. It is built on
[Godular](https://github.com/RafaelVidaurre/godular) (dependency injection and modules) and
[GdbPromise](https://github.com/RafaelVidaurre/gd-better-promises) (promises).

New here? Read the pages in order. Each one builds on the previous one.

## Reading order

1. [Introduction](getting-started/01-introduction.md): what the addon is for, and whether it fits your project.
2. [Installation](getting-started/02-installation.md): dependencies, plugins, and project setup.
3. [Quick start](getting-started/03-quick-start.md): a working View, Binding, and HUD button in about 100 lines.
4. [Demo tour](getting-started/04-demo-tour.md): the bundled demo, module by module, with experiments to try.

## Concepts

- [Architecture overview](concepts/01-architecture-overview.md): how the pieces fit together.
- [Modules and capabilities](concepts/02-modules-and-capabilities.md): the Godular model, as the addon uses it.
- [Component model](concepts/03-component-model.md): Elements, Widgets, and Views.

## Guides

Each guide covers one system: what it does, when to use it, and the gotchas.

| I want to…                                               | Read                                                  |
|----------------------------------------------------------|-------------------------------------------------------|
| Show a full-screen or exclusive panel (HUD, menu, inventory) | [Views](guides/views.md)                          |
| Add a button or label into another UI                     | [Attachments and Attachment Slots](guides/attachments-and-slots.md) |
| Share state between a View and its Attachments            | [Context](guides/context.md)                          |
| Understand where UI mounts and in what order it draws     | [UI Layers](guides/ui-layers.md)                      |
| Bind a key or button to an action                         | [Input Bindings](guides/input-bindings.md)            |
| Show dismissable overlays, dialogs, or queued notifications | [Popups](guides/popups.md)                          |
| Show hover information                                    | [Tooltips](guides/tooltips.md)                        |
| Attach UI to a moving game object (nameplates, labels)    | [World UI](guides/world-ui.md)                        |
| Temporarily block a category of interaction               | [Policy Store](guides/policy-store.md)                |

## Reference

- [Capabilities API](reference/capabilities-api.md): every public `Cap*` contract, method by method.
- [Types and enums](reference/types-and-enums.md): `UiLayer`, `PolicyStoreTypes.Category`, `CloseReason`, and the value classes.
- [Helper components](reference/helper-components.md): `ViewRequester`, `AttachmentSlotsController`, `WorldUiPortal`, and their exported properties.
- [Project conventions](reference/conventions.md): file suffixes, folder layout, and naming.

## Other

- [Cookbook](cookbook.md): short end-to-end recipes for common features.
- [FAQ and troubleshooting](faq-and-troubleshooting.md): common errors and what they mean.

## Contributing

To contribute to the addon itself, read [CONTRIBUTING.md](../CONTRIBUTING.md). Its architecture notes
live under [`.agents/`](../.agents/).
