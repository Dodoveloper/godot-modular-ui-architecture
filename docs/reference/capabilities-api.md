# Capabilities API

Every public contract the addon exposes, with its methods and signals. Each capability is an
abstract `Cap*` class. Inject it into your module with a typed property, or resolve it with
`GdlrModuleManager.request()`. You never instantiate it. See
[Modules and capabilities](../concepts/02-modules-and-capabilities.md).

Source files are under `addons/modular_ui_architecture/modules/<module>/capabilities/`. Parameters with
defaults are optional. Defaults are shown as written in the source.

## CapGameUi

Module: `game_ui`. Source: `game_ui/capabilities/game_ui.cap.gd`.

| Member | Signature | Summary |
|--------|-----------|---------|
| signal | `view_mounted(token: StringName)` | Emitted after a View is mounted, **before** its Attachments mount. |
| method | `mount_view(token: StringName, layer := UiLayersTypes.DEFAULT_LAYER) -> Node` | Mounts the registered View. Returns it, or `null`. |
| method | `unmount_view(token: StringName) -> bool` | Unmounts the View. Returns `false` if none is mounted under `token`. |
| method | `get_view(token: StringName) -> Node` | The mounted View, or `null`. |
| method | `is_view_mounted(token: StringName) -> bool` | Whether a View is mounted under `token`. |
| method | `mount_world_ui(ui: Control, anchor: CanvasItem = null, layer := DEFAULT, offset := Vector2.ZERO, mirror_anchor_visuals := false) -> Control` | Mounts a control into a layer and tracks `anchor` every frame. Returns `ui`, or `null`. |
| method | `unmount_world_ui(ui: Control) -> bool` | Stops tracking and frees a World UI node. |
| method | `mount_attachments(view: Node, add_to_slot: Callable) -> void` | Mounts the Attachments for `view`. `AttachmentSlotsController` calls this. You don't usually call it. |
| method | `unmount_attachment(attachment: GameUiTypes.UiAttachment) -> void` | Removes the UI built for an attachment. |

`mount_attachments`' `add_to_slot` must have the signature
`func(slot_tag: StringName, ui: Control, priority: int) -> bool`. It is valid only for that call.

## CapViewsRegistry

Module: `game_ui`. Source: `game_ui/capabilities/views_registry.cap.gd`. Stores View registrations.

| Method | Signature |
|--------|-----------|
| `register_view` | `register_view(view_registration: GameUiTypes.ViewRegistration) -> void` |
| `unregister_view` | `unregister_view(token: StringName) -> void` |
| `get_view_registration` | `get_view_registration(token: StringName) -> GameUiTypes.ViewRegistration` |

## CapUiAttachmentsRegistry

Module: `game_ui`. Source: `game_ui/capabilities/ui_attachments_registry.cap.gd`.

| Method | Signature |
|--------|-----------|
| `register_attachment` | `register_attachment(attachment: GameUiTypes.UiAttachment) -> void` |
| `unregister_attachment` | `unregister_attachment(attachment: GameUiTypes.UiAttachment) -> void` |
| `get_attachments` | `get_attachments() -> Array[GameUiTypes.UiAttachment]` |

## CapUiLayers

Module: `ui_layers`. Source: `ui_layers/capabilities/ui_layers.cap.gd`.

| Member | Signature | Summary |
|--------|-----------|---------|
| signal | `ui_layer_input_triggered(action: StringName, layer: StringName, input_type: InputActionType)` | Emitted when a registered action is pressed or released on a layer. Input Bindings listen to this. |
| method | `get_layer_node(layer: StringName) -> UiLayerNode` | The node backing `layer`. |
| method | `get_layers() -> Array[StringName]` | All mounted layers. |
| method | `get_world_ui_container(layer: StringName) -> Control` | The container World UI on `layer` mounts into. |
| method | `is_layer_input_blocked(layer: StringName) -> bool` | `true` if a higher layer that blocks input has UI mounted. |
| method | `mount_ui(scene_path: String, layer: StringName, data := {}) -> Node` | Mounts a scene into `layer`. Returns the node, or `null`. |
| method | `unmount_ui(ui: Node) -> bool` | Unmounts and frees a node mounted in any layer. |
| method | `notify_input_triggered(action, layer := DEFAULT, input_type := PRESSED) -> void` | Broadcasts an input action. Layer nodes call this. You don't usually call it. |

Layers are created when the module is enabled. Don't call these before the graph has started.

## CapInputBindings

Module: `input_bindings`. Source: `input_bindings/capabilities/input_bindings.cap.gd`.

| Method | Signature | Summary |
|--------|-----------|---------|
| `trigger_bindings` | `trigger_bindings(action: StringName, layer := DEFAULT, input_type := PRESSED) -> bool` | Runs the first binding for `action` on `layer` whose `should_execute()` is `true`. Returns `true` if one ran. |

## CapInputBindingsRegistry

Module: `input_bindings`. Source: `input_bindings/capabilities/input_bindings_registry.cap.gd`.

| Method | Signature |
|--------|-----------|
| `register_binding` | `register_binding(action: StringName, binding: InputBindingsTypes.InputBinding) -> void` |
| `unregister_binding` | `unregister_binding(action: StringName, binding: InputBindingsTypes.InputBinding) -> void` |
| `get_bindings` | `get_bindings(action: StringName) -> Array[InputBindingsTypes.InputBinding]` |
| `get_actions` | `get_actions() -> Array[StringName]` |

## CapPopups

Module: `popups`. Source: `popups/capabilities/popups.cap.gd`.

| Method | Signature | Summary |
|--------|-----------|---------|
| `open_popup` | `open_popup(popup_path: String, parent: Control = null, position := Vector2.ZERO, is_blocking := false, color := Color(0, 0, 0, 0), dismiss_on_click_outside := true) -> Control` | Opens a popup now. Returns it, or `null`. |
| `open_popup_queued` | `open_popup_queued(popup_path: String, color := Color(0, 0, 0, 0.5), setup := Callable(), dismiss_on_click_outside := false) -> void` | Opens a popup, or queues it behind open queued popups. `setup` receives the popup after instantiation. |
| `close_popup` | `close_popup(popup: Control) -> bool` | Closes a popup. Returns `true` if it was closed. |

A popup scene may emit `close_requested` to ask to close, and may implement `begin_close_transition` with
a `close_transition_finished` signal. See [Popups](../guides/popups.md#close-transitions).

## CapTooltips

Module: `tooltips`. Source: `tooltips/capabilities/tooltips.cap.gd`.

| Method | Signature | Summary |
|--------|-----------|---------|
| `show_tooltip` | `show_tooltip(tooltip_path: String, anchor: Control, contents: Dictionary[StringName, Variant], available_rect: Rect2) -> Tooltip` | Mounts a tooltip. Returns it, or `null` if refused. See [Tooltips](../guides/tooltips.md#when-a-tooltip-is-refused). |
| `hide_tooltip` | `hide_tooltip() -> bool` | Removes the current tooltip. Returns `true` if one was removed. |

## CapPolicyCategoriesRegistry

Module: `policy_store`. Source: `policy_store/capabilities/policy_categories_registry.cap.gd`. Stores the
policy categories that [CapPolicyStore](#cappolicystore) accepts. Call it from `register()`.

| Method | Signature | Summary |
|--------|-----------|---------|
| `register_category` | `register_category(category: StringName) -> void` | Registers a category. An empty or already-registered token pushes an error and is ignored. |
| `unregister_category` | `unregister_category(category: StringName) -> void` | Unregisters `category`, drops its blockers, and emits `category_unregistered`. An unknown category pushes an error and is ignored. |
| `is_category_registered` | `is_category_registered(category: StringName) -> bool` | Whether `category` has been registered. |

### Signals

| Signal | Signature | Summary |
|--------|-----------|---------|
| `category_unregistered` | `category_unregistered(category: StringName)` | Emitted after a category is unregistered. `CapPolicyStore` uses it to drop that category's blockers. |

## CapPolicyStore

Module: `policy_store`. Source: `policy_store/capabilities/policy_store.cap.gd`. Categories are
`StringName` tokens that must be registered first. See [Policy Store](../guides/policy-store.md#declaring-your-own).

| Method | Signature | Summary |
|--------|-----------|---------|
| `block` | `block(category: StringName, source: Object) -> void` | Blocks `category` on behalf of `source`. An unregistered category pushes an error and is not blocked. |
| `unblock` | `unblock(category: StringName, source: Object) -> void` | Removes that source's block. An unregistered category pushes an error. |
| `is_allowed` | `is_allowed(category: StringName) -> bool` | `true` if no source is blocking `category`. An unregistered category pushes an error and returns `true`. |
| `get_blockers` | `get_blockers(category: StringName) -> Array[Object]` | The live sources blocking `category`. An unregistered category pushes an error and returns an empty array. |

## Next

- [Types and enums](types-and-enums.md): the enums and value classes these signatures use.
- [Helper components](helper-components.md): the nodes that wrap these capabilities for you.
