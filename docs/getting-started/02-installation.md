# Installation

## Requirements

- **Godot 4.7.** The addon has been verified against 4.7.
- **Godular** (`addons/godular`), the dependency-injection and module framework this addon is built on.
  It requires Godot 4.5 or later. See its [repository](https://github.com/RafaelVidaurre/godular) for
  its own documentation.
- **GdbPromise** (`addons/gdb_promise`), the promise library Godular uses. Godular's release packages
  include it.

## Install the addon

Copy these three folders into your project's `addons/` folder:

```
res://addons/
├── godular/
├── gdb_promise/
└── modular_ui_architecture/
```

The Godular release packages (zip files and the Asset Library entry) already contain `godular` and
`gdb_promise`, so copying the `addons` folder from a Godular release is enough. Make sure
`modular_ui_architecture` sits next to them.

## Enable the plugins

Open **Project → Project Settings → Plugins** and enable:

1. **Godular**. This registers the `GdlrModuleManager` autoload that mounts and starts your modules.
2. **Modular UI Architecture**.

Enable Godular first. The addon's own plugin depends on it being present.

> **Note:** the addon's `plugin.cfg` does not register any scripts or autoloads of its own. Enabling
> it only marks the addon as active. Everything it provides comes through Godular modules.

## Verify the installation

Create a scene with a `Node` root, attach any script, and print something in `_ready()`. If the
editor reports no errors when you run the scene, the addons are loaded. The
[Quick start](03-quick-start.md) walks through a working setup.

## Project setup you'll need

- **Input actions.** Bindings refer to actions by name, so each action must exist under
  **Project → Project Settings → Input Map** before the binding is registered. The
  [Quick start](03-quick-start.md) adds one.
- **A bootstrap script.** Godular modules must be mounted and started before anything resolves a
  capability. This is covered in the [Quick start](03-quick-start.md) and in
  [Modules and capabilities](../concepts/02-modules-and-capabilities.md).

## Next

Continue to the [Quick start](03-quick-start.md).
