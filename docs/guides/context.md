# Context

**Context** is the state a View exposes so its Attachments can react to it. It lets a Widget stay
decoupled: the Widget reads Context, and doesn't reach into the View's internals.

In this addon, "Context" has one meaning: the `context` property on a View. Don't reuse the word for
unrelated state, such as player data.

## When to use Context

Use Context when an Attachment needs to show or act on something the View knows, but the View
shouldn't need to know which Attachments exist. The classic case is a selection: the Inventory knows
which item is selected, and a separate module's "Equip" button needs to show that item's name.

If no Attachment needs a value, don't expose it.

## How it works

1. The View owns a `context` property. Its value is an object (a `RefCounted`) with the fields
   Attachments can read.
2. The View updates those fields in its own code.
3. `CapGameUi` checks the View's `context` every physics frame, and compares the values with the
   previous ones.
4. If anything changed, `CapGameUi` calls `_on_context_changed()` on each Attachment mounted into
   that View.

The View doesn't emit a signal for this. It only updates its fields, and the addon detects the change.

## The View side

This example is simplified from the demo's Inventory:

```gdscript
# inventory.gd (View script, simplified)
extends Control

var context := Context.new()


func _on_slot_item_selected(item_name: String) -> void:
	context.selected_item_name = item_name


class Context extends RefCounted:
	## Display name of the selected item, or an empty string if none is selected.
	var selected_item_name := ""
```

Rules for the View side:

- The property must be named exactly `context`.
- The `Context` class is an inner class on the View's own script.
- Each field must be a script variable on the Context object. The addon reads every script variable
  it finds on the object.

## The Attachment side

An Attachment reads Context in two places:

- `_build(host_ui, context)` receives the current Context when the Widget is built.
- `_on_context_changed(new_context)` is called on every later change.

```gdscript
# equip_button.attach.gd (simplified from the demo)
func _build(host_ui: Node, context: RefCounted) -> Control:
	var button: Button = super(host_ui, context)
	_refresh(button, context)
	return button


func _on_context_changed(new_context: RefCounted) -> void:
	_refresh(get_instance(), new_context)


func _refresh(button: Button, context: RefCounted) -> void:
	var selected: String = context.selected_item_name if context else ""
	button.disabled = selected.is_empty()
	button.text = "Equip" if selected.is_empty() else "Equip %s" % selected
```

Use `get_instance()` inside `_on_context_changed()` to reach the Widget the Attachment built.

## Gotchas

- **Changes are detected by polling, once per physics frame.** A change made during a frame may show
  on the next physics tick. Don't rely on Context for same-frame updates.
- **Only differing values trigger a notification.** Setting a field to the value it already has does
  nothing.
- **Keep Context fields as plain values.** The addon compares them by value. Changing a nested object
  in place may not be detected, so replace the whole value instead.
- **`context` may be `null`.** Check before you read it, as the example above does.
- **Context is per-View.** Each mounted View has its own Context, and an Attachment reads the Context
  of the View it is mounted into.

## Next

- [Attachments and Attachment Slots](attachments-and-slots.md): the Attachment side in full.
- [Views](views.md): the View side in full.
