# Attachments and Attachment Slots

An **Attachment** lets one module put a piece of UI (a Widget) into another module's View, without
the View knowing the Attachment exists, and without the attaching module importing the View's module.

Three parts make this work:

- **Attachment Slots** are named containers a View exposes, such as a HUD's `bottom_right`.
- **`AttachmentSlotsController`** is the helper node that registers a View's slots and mounts into them.
- **`UiAttachment`** is your class. It says what to build, which slot, in what order, and when.

## The minimal example

This Attachment places a button into a View's `footer` slot. It triggers a binding, so the key and the
button stay in sync. See the [Quick start](../getting-started/03-quick-start.md) for the full feature
around it.

```gdscript
# my_feature/attachments/hello_button.attach.gd
extends GameUiTypes.UiAttachment


const GameUiTypes = preload("res://addons/modular_ui_architecture/modules/game_ui/types.gd")
const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")

const HELLO_BUTTON_PATH := "res://my_feature/hello_button.tscn"
const TOGGLE_HELLO_ACTION := &"toggle_hello"

var _svc_input_bindings: CapInputBindings


func _init(svc_input_bindings: CapInputBindings) -> void:
	_svc_input_bindings = svc_input_bindings
	_Scene = load(HELLO_BUTTON_PATH)
	_slot_tag = &"footer"
	_priority = 0


func _build(host_ui: Node, context: RefCounted) -> Control:
	var button: Button = super(host_ui, context)
	button.pressed.connect(_on_button_pressed)
	return button


func _on_button_pressed() -> void:
	_svc_input_bindings.trigger_bindings(TOGGLE_HELLO_ACTION, UiLayersTypes.UiLayer.WINDOW)
```

Register it in the owning module:

```gdscript
var svc_input_bindings: CapInputBindings
var reg_attachments: CapUiAttachmentsRegistry

func register() -> void:
	reg_attachments.register_attachment(HelloButtonAttachment.new(svc_input_bindings))
```

Import `GameUiModule` and `InputBindingsModule` so both capabilities are injected.

## Configuring the slot on the View

The View must expose the slot. In its scene, add an `AttachmentSlotsController` node and set its
**Slot Configs** dictionary:

| Key | `node_path` | `max_children` | `protected_center` |
|-----|-------------|----------------|--------------------|
| `footer` | the container node for this slot | `-1` (unlimited) | `false` |

- `node_path` is relative to the controller node. It must point at a `Control`.
- `max_children` limits how many Attachments the slot accepts. `-1` means unlimited.
- Keys are `StringName`s. The Attachment's `_slot_tag` must match a key exactly.

If the controller is missing from the View, Attachments for that View are never mounted, and nothing
reports an error. If an Attachment targets a slot the View doesn't define, the controller logs a
warning and the Attachment's UI is discarded. The View itself is unaffected. If a slot is full, the
controller logs an error and discards that UI the same way.

## The UiAttachment API

Your Attachment is a subclass of `GameUiTypes.UiAttachment` with these members:

| Member | Set or overridden | Purpose |
|--------|-------------------|---------|
| `_slot_tag` | Set in `_init()` | The slot to mount into. |
| `_priority` | Set in `_init()` | Order within the slot. Higher values mount first. Ties use registration order. |
| `_Scene` | Set in `_init()` | The scene to instantiate by default. |
| `_should_mount(host_ui, context)` | Override | Return `true` to mount this Attachment on a given View. Default `true`. |
| `_build(host_ui, context)` | Override | Build the Control. Call `super()` to get the default instance from `_Scene`, then configure it. |
| `_on_context_changed(new_context)` | Override | Called when the View's Context changes. See [Context](context.md). |
| `_on_instance_built()` | Override | Called after the UI is built. |
| `_on_instance_tree_exiting()` | Override | Called when the built UI is leaving the tree. Disconnect signals here. |

## Targeting a View from another module

To mount into a View that another module owns, `preload()` that View's script and check it in
`_should_mount`. Don't import the owning module just for this check:

```gdscript
const Hud = preload("res://demo/modules/hud/content/ui/hud.gd")

func _should_mount(host_ui: Node, _context: RefCounted) -> bool:
	return host_ui is Hud
```

The `Hud` script in this example is the demo's own View script. Any View script works the same way.

Don't use `svc_game_ui.get_view()` inside `_should_mount()`. An Attachment is evaluated while its View
is still being added to the tree, before `CapGameUi` records the View as mounted, so `get_view()`
returns `null` at that point.

`_should_mount()` runs once, when the View mounts. An Attachment can't start or stop targeting a View
based on Context later. It can only make its own Widget react to changes with `_on_context_changed()`.

## Ordering inside a slot

Within a slot, higher `_priority` values mount earlier. Attachments with the same priority mount in
the order they were registered. The demo's `equipment` module, for example, uses priority `10` for its
HUD label, which sits ahead of the default-priority buttons.

To reorder without touching the View, change `_priority` or `_slot_tag` on the Attachment.

## Protected center slots

Some layouts need a centre area that stays truly centred even when its left and right siblings grow.
Mark the centre slot `protected_center = true`. The controller then enforces equal widths on the left
and right slots. The demo's HUD uses this for `bottom_center`.

Requirements:

- The slot's parent must be a `BoxContainer`.
- That `BoxContainer` must have exactly three children, with the protected slot at index `1`.

If a requirement isn't met, the controller logs an error and skips the centre protection for that slot.

When space runs out, side content is clipped rather than hidden. Use priority and slot order to decide
what survives.

## Triggering a binding from a button

Call a binding from the button, not the capability directly. The Attachment above does this with
`trigger_bindings()`. A key and its button then run the same code, and the Policy Store check stays
in the binding's `_should_execute()`. See [Input Bindings](input-bindings.md).

## Sharing state between sibling Attachments

If two Attachments from the same module need one value, for example one writes it and the other
displays it, create one small `RefCounted` state object in `register()` and pass it to both. The demo's
`equipment` module does this. Keep the state inside the module. Don't add a capability for it unless a
second, unrelated module needs it too.

## Gotchas

- **An Attachment is built again on every mount.** The same registered Attachment instance mounts into
  each new instance of its View. Build fresh state in `_build()`, and disconnect external signals in
  `_on_instance_tree_exiting()`.
- **`_on_instance_tree_exiting()` also runs for discarded UI.** If a slot rejects the UI, the
  Attachment discards it through `discard_instance()`, which calls your hook too. One teardown hook
  covers both cases.
- **The `add_to_slot` Callable is valid only during the mount call.** Don't store it.

## Next

- [Context](context.md): let Attachments react to the View's state.
- [Input Bindings](input-bindings.md): the binding your button triggers.

