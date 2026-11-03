# Installation

## Requirements

- **Godot 4.7.** The addon has been verified against 4.7.
- **Godular** (`addons/godular`), the dependency-injection and module framework this addon is built on.
  It requires Godot 4.5 or later. See its [repository](https://github.com/RafaelVidaurre/godular) for
  its own documentation.
- **GdbPromise** (`addons/gdb_promise`), the promise library Godular uses. Godular's release packages
  include it.

## Install the addon

### Via the Godot Asset Library (recommended)

1. In the Godot editor, open the **AssetLib** tab.
2. Search for **"Modular UI Architecture"**.
3. Click **Download**, then **Install**. Only the `addons/` folders are added to your project:
   `modular_ui_architecture`, plus the `godular` and `gdb_promise` dependencies.
4. Continue with [Enable the plugins](#enable-the-plugins).

### Manual installation

1. Download a [release](https://github.com/Dodoveloper/godot-modular-ui-architecture/releases), or
   clone this repository.
2. Copy these three folders into your project's `addons/` folder:

   ```
   res://addons/
   ├── godular/
   ├── gdb_promise/
   └── modular_ui_architecture/
   ```

   Godular's own release packages (zip files and Asset Library entry) also contain `godular` and
   `gdb_promise`, so you can take those two from there. Make sure `modular_ui_architecture` sits next
   to them.
3. Continue with [Enable the plugins](#enable-the-plugins). Unlike addons made of plain
   `class_name` scripts, this one needs its plugins enabled: Godular's plugin registers the
   `GdlrModuleManager` autoload that everything runs on.

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
