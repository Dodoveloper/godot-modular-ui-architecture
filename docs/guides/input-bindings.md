# Input Bindings

An **Input Binding** connects an action in Godot's Input Map to a behaviour, on a specific UI layer.
It is the single place where "what should happen" lives. A key press and a button press both go
through the same binding, so they always behave the same way.

## The model

- **Action.** A name defined in Project Settings → Input Map, such as `toggle_inventory`.
- **Layer.** The UI layer the binding belongs to. The binding only runs for input that reaches that layer.
- **Binding.** Your `InputBinding` subclass, with `_should_execute()` and `_execute()`.
- **Priority.** Decides which binding wins when several bind the same action on the same layer.

## The minimal binding

```gdscript
# my_feature/bindings/toggle_hello.bind.gd
extends InputBindingsTypes.InputBinding


const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const InputBindingsTypes = preload("res://addons/modular_ui_architecture/modules/input_bindings/types.gd")

var _svc_game_ui: CapGameUi
var _view_token: StringName


func _init(svc_game_ui: CapGameUi, view_token: StringName, layer_: UiLayersTypes.UiLayer) -> void:
	_svc_game_ui = svc_game_ui
	_view_token = view_token
	super(layer_)


func _execute() -> void:
	if _svc_game_ui.is_view_mounted(_view_token):
		_svc_game_ui.unmount_view(_view_token)
	else:
		_svc_game_ui.mount_view(_view_token, layer)


func _should_execute() -> bool:
	return true
```

Register it in the owning module's `register()`, against the action name:

```gdscript
reg_input_bindings.register_binding(&"toggle_hello", ToggleHelloBinding.new(svc_game_ui, &"hello", UiLayersTypes.UiLayer.WINDOW))
```

Then add `toggle_hello` to the Input Map. A binding for an action that doesn't exist in the Input Map
never runs.

## How a press is routed

1. A layer sees an action press or release.
2. It tells `CapUiLayers`, which forwards it to `CapInputBindings.trigger_bindings()`.
3. `trigger_bindings()` looks up the bindings for that action, in priority order, and keeps the ones
   on the same layer and input type.
4. It runs the **first** binding whose `_should_execute()` returns `true`, and stops there.
5. It marks the input handled, so lower layers don't receive it.

Only one binding runs per press. If you need two behaviours for one action, use one binding that does
both, or two different layers.

## _should_execute and _execute

- `_should_execute()` decides whether the binding applies right now. Put gating checks here, such as a
  [Policy Store](policy-store.md) check.
- `_execute()` does the work. Call a capability here, such as `CapGameUi` or `CapPopups`.

Keep the decision in `_should_execute()`. If it's in `_execute()`, a higher-priority binding that
returns `true` will hide the check, and the lower binding won't get the chance to run.

## Priority

Higher priority values run first. Equal priorities run in registration order.

```gdscript
var binding := ToggleHelloBinding.new(svc_game_ui, &"hello", UiLayersTypes.UiLayer.WINDOW)
binding.priority = 10
reg_input_bindings.register_binding(&"toggle_hello", binding)
```

Set `priority` when you register the binding. Don't rely on registration order unless the order is
what you intend.

## Triggering a binding from a button

A button calls the same code path as a key, so it stays consistent:

```gdscript
func _on_button_pressed() -> void:
	_svc_input_bindings.trigger_bindings(&"toggle_hello", UiLayersTypes.UiLayer.WINDOW)
```

Use `trigger_bindings()` to call a binding by action name and layer. The button doesn't call
`CapGameUi` directly. See [Attachments and Attachment Slots](attachments-and-slots.md#triggering-a-binding-from-a-button).

## Focus and text fields

A focused `LineEdit` or other text input receives keystrokes first. A binding on a key the field also
uses (such as `r`) doesn't fire while the field has focus. This is intended, so typing works.

Keys used for focus navigation (Tab and the arrow keys) are read before the GUI. A binding on those
keys can run while a Control has focus. Avoid binding them unless you mean to.

For why the phases are split this way, see [UI Layers](ui-layers.md#input-and-focus) and
[ADR-001](../../.agents/adrs/001-ui-layer-input-broadcast-ordering.md).

## Gotchas

- **The action must exist.** Add it to the Input Map, or the binding never fires.
- **`_should_execute()` is called on every matching press.** Keep it cheap.
- **Don't call `trigger_bindings` from inside `_execute()`** for the same action. You'll recurse into the
  same binding.
- **Releasing is a separate event.** `InputActionType.RELEASED` bindings are only triggered for release
  events. A `PRESSED` binding doesn't fire on release.

## Next

- [Policy Store](policy-store.md): gate a binding with `_should_execute()`.
- [Popups](popups.md): a common thing for a binding to open.
