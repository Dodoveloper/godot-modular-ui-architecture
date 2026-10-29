# Quick start

This walkthrough builds a minimal feature with three parts: a View, a keybinding that toggles it, and
a HUD-style button that does the same. Every file below was built and run headless against the addon
before being written here.

The example assumes:

- You followed [Installation](02-installation.md).
- You want a **new** feature called `my_feature`. Keep the folder names as shown, or change them consistently.

## Step 1: Bootstrap the module graph

Godular needs a root module mounted and started before anything resolves a capability. Start from a
plain script on your main scene's root node. It is not a module itself.

```gdscript
# main.gd
extends Node

const MyFeatureModule = preload("res://my_feature/my_feature.md.gd")


func _ready() -> void:
await GdlrModuleManager.mount(MyFeatureModule)
await GdlrModuleManager.start()
```

Don't resolve a capability before `start()` has returned. The demo follows the same order in
[`demo/content/levels/main.gd`](../../demo/content/levels/main.gd).

## Step 2: Declare the module

The module file declares what it imports and what it registers. `register()` runs before `enable()`,
so everything registered there is ready when the module starts.

```gdscript
# my_feature/my_feature.md.gd
const GameUiModule = preload("res://addons/modular_ui_architecture/modules/game_ui/game_ui.md.gd")
const InputBindingsModule = preload("res://addons/modular_ui_architecture/modules/input_bindings/input_bindings.md.gd")
const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const GameUiTypes = preload("res://addons/modular_ui_architecture/modules/game_ui/types.gd")
const ToggleHelloBinding = preload("./bindings/toggle_hello.bind.gd")
const HelloButtonAttachment = preload("./attachments/hello_button.attach.gd")

const HELLO_VIEW_PATH := "res://my_feature/hello_view.tscn"
const HELLO_TOKEN := &"hello"
const TOGGLE_HELLO_ACTION := &"toggle_hello"

static var IMPORTS := [
	GameUiModule,
	InputBindingsModule,
]


class MyFeatureModule extends GdlrModule:
	var reg_views: CapViewsRegistry
	var reg_input_bindings: CapInputBindingsRegistry
	var reg_attachments: CapUiAttachmentsRegistry
	var svc_game_ui: CapGameUi
	var svc_input_bindings: CapInputBindings


	func register() -> void:
		reg_views.register_view(GameUiTypes.ViewRegistration.new(HELLO_TOKEN, HELLO_VIEW_PATH))
		var binding := ToggleHelloBinding.new(svc_game_ui, HELLO_TOKEN, UiLayersTypes.UiLayer.WINDOW)
		reg_input_bindings.register_binding(TOGGLE_HELLO_ACTION, binding)
		reg_attachments.register_attachment(HelloButtonAttachment.new(svc_input_bindings))
```

Godular injects each typed property (`reg_views`, `svc_game_ui`, and so on) automatically. The
property names are yours to choose, but the types must match a capability the module can see.
See [Modules and capabilities](../concepts/02-modules-and-capabilities.md).

`GameUiModule` and `InputBindingsModule` are the addon's own modules. Importing them makes
`CapGameUi`, `CapViewsRegistry`, `CapInputBindings`, and the registries available to your module.

## Step 3: Create the View

A View is an ordinary `Control` scene. To accept Attachments, it needs an `AttachmentSlotsController`
node and one slot for each place an Attachment should go. This View defines one slot, `footer`.

```gdscript
# my_feature/hello_view.gd
extends Control


func _ready() -> void:
	print("HelloView ready")
```

Build `res://my_feature/hello_view.tscn` in the editor:

1. Create a `Control` root named `HelloView`. Set its anchors to **Full Rect**, and attach
   `hello_view.gd`.
2. Add a child `Label` with the text "Hello, Modular UI!", placed in the top-left corner.
3. Add a child `HBoxContainer` named `Footer`, anchored to the bottom of the screen, about 40 pixels
   tall.
4. Instance `res://addons/modular_ui_architecture/shared/classes/attachment_slots_controller/attachment_slots_controller.tscn`
   as a child named `AttachmentSlotsController`. In its inspector, add one **Slot Configs** entry:
   - Key: `footer`
   - `node_path`: `../Footer`
   - `max_children`: `-1` (unlimited)

Attachments only mount into a View that has an `AttachmentSlotsController`. Without one, the
Attachment never appears and nothing reports an error. See the [FAQ](../faq-and-troubleshooting.md).

## Step 4: Write the keybinding

A binding connects an input action to behaviour. This one mounts the View if it isn't mounted and
unmounts it otherwise. It always goes through `CapGameUi`, never through the View directly.

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

`layer` is inherited from `InputBinding`. It's the UI layer the binding is scoped to, so it only runs
for input that reaches that layer.

## Step 5: Write the button Attachment

The Attachment builds a `Button`, places it in the `footer` slot of a View, and triggers the same
binding a key triggers. The button and the key therefore always behave the same way.

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

Create `res://my_feature/hello_button.tscn`: a `Button` root with the text "Say hi".

## Step 6: Register the input action

Bindings use Godot's Input Map, so the action must exist:

1. Open **Project → Project Settings → Input Map**.
2. Add an action named `toggle_hello` and give it a key, for example **H**.

## Step 7: Run it

Make your `main.tscn` the main scene, and run it.

- Press **H**: the View mounts.
- Click **Say hi**: the View unmounts. The button runs the same binding the key does.
- Press **H** again: the View mounts once more.

Notice that the View's mount logic lives in one place, the binding. The button only triggers that
binding, and the View's code doesn't mention the button.

## What you built

| Piece | Responsibility |
|-------|----------------|
| `main.gd` | Mounts and starts the module graph. |
| `my_feature.md.gd` | Declares dependencies and registers everything. |
| `hello_view.tscn` | The View, with a `footer` slot. |
| `toggle_hello.bind.gd` | Decides what the key does. |
| `hello_button.attach.gd` | Puts a button in the View's footer, and triggers the binding. |

## Next

Continue to the [Demo tour](04-demo-tour.md) to see these pieces in a larger project.

