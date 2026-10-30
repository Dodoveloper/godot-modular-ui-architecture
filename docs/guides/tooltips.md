# Tooltips

A **Tooltip** is hover information about something under the cursor. `CapTooltips` shows one tooltip
at a time, anchored to the node that requested it and positioned to stay on screen.

Tooltips are a separate system from Popups. They don't dismiss on click, and they don't stack.
See [Architecture overview](../concepts/01-architecture-overview.md#three-mounting-systems-on-purpose).

## The Tooltip scene

A tooltip is a scene whose root script extends `Tooltip` (`class_name Tooltip`, in
`addons/modular_ui_architecture/modules/tooltips/ui/tooltip.gd`). The base class has three exported
node paths that the scene must set:

| Export | Node |
|--------|------|
| `bubble` | The node whose size is the tooltip's total size. Its background goes here. |
| `content` | The node holding the contents, without margins or styling. |
| `description` | A `RichTextLabel` for the body text. |

Also set `bubble_width` (in pixels, up to 512) to control the width.

Subclass `Tooltip` and override `_initialize(tooltip_data)` to read the data the requester sends.

```gdscript
# my_feature/ui/item_tooltip.gd
extends Tooltip


var _title: Label


func _initialize(tooltip_data: Dictionary[StringName, Variant]) -> void:
	_title.text = tooltip_data.get(&"title", "")
	description.text = tooltip_data.get(&"description", "")
```

Resolve the nodes in your scene's `_ready()`, and let the base class handle the position.

## Showing and hiding a tooltip

A node that wants a tooltip resolves `CapTooltips` once it enters the tree, then calls `show_tooltip()` on
mouse enter and `hide_tooltip()` on mouse exit:

```gdscript
const ItemTooltip = preload("res://my_feature/ui/item_tooltip.tscn")

var _svc_tooltips: CapTooltips


func _enter_tree() -> void:
	await Utils.await_module_graph_started()
	_svc_tooltips = GdlrModuleManager.request(CapTooltips, self)


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_mouse_entered() -> void:
	_svc_tooltips.show_tooltip(
		ItemTooltip.resource_path, self, {&"title": "Sword", &"description": "A sharp blade."},
		get_viewport().get_visible_rect()
	)


func _on_mouse_exited() -> void:
	_svc_tooltips.hide_tooltip()
```

Here `Utils` is the addon's own helper (`shared/classes/utils.gd`). It waits for the module graph before
you request the capability. The [Modules and capabilities](../concepts/02-modules-and-capabilities.md)
page describes the same wait.

The demo's `inventory_slot.gd` is a full working example.

### Arguments to show_tooltip

| Argument | Meaning |
|----------|---------|
| `tooltip_path` | The tooltip scene's path. Use `ItemTooltip.resource_path` for a preloaded scene, or a literal path. |
| `anchor` | The `Control` the tooltip is positioned against. Usually `self`. |
| `contents` | The data passed to `_initialize()`. Keys are `StringName`s. |
| `available_rect` | The area the tooltip must stay inside. `get_viewport().get_visible_rect()` is the usual choice. |

`show_tooltip()` returns the mounted tooltip, or `null` if it was refused.

## Placement

The tooltip chooses a side of its anchor that fits on screen. It tries the corner placement first and
falls back to another side when there's no room. A tooltip can override `_get_placement_axis()` to
prefer horizontal or vertical placement. The addon reports the chosen side through `location`.

## When a tooltip is refused

`show_tooltip()` returns `null` in these cases:

- **Another tooltip is already showing.** Only one tooltip can be mounted at a time. Call
  `hide_tooltip()` first if you want to replace it.
- **The mouse is not inside the anchor's rectangle** when the tooltip is requested.

Refused requests don't replace the current tooltip. This is a common surprise when two nodes overlap:
hide the first before showing the second.

## Gotchas

- **Set `mouse_exited` as well as `mouse_entered`.** Without `hide_tooltip()` on exit, the tooltip stays
  on screen after the cursor leaves.
- **Use a fresh `contents` dictionary each time.** The addon reads it when the tooltip mounts.
- **Only one tooltip shows at a time.** If you need several at once, use a Popup or a View.
- **Tooltips don't handle dismissal.** `CapTooltips` only mounts and hides them. Nothing on the tooltip
  layer closes one on Escape or on click.

## Next

- [Popups](popups.md): when a tooltip isn't enough.
- [World UI](world-ui.md): pieces of UI which follow a game object.
