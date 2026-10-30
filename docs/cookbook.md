# Cookbook

Short, end-to-end recipes for common features. Each one points to the guide that explains the parts
in depth. Start with the [Quick start](getting-started/03-quick-start.md) if you haven't built a View yet.

## Toggle a View with a key and a HUD button

A View that opens from a key and from a button, using one binding for both. The Quick start builds this
in full. The shape is:

1. A View scene with an `AttachmentSlotsController` and a `footer` slot.
2. A binding that mounts or unmounts the View by token.
3. An Attachment that puts a button in the slot and triggers the binding.
4. A module that registers all three.

See the [Quick start](getting-started/03-quick-start.md) for the files, and [Views](guides/views.md) and
[Attachments and Attachment Slots](guides/attachments-and-slots.md) for the rules behind each part.

## Gate gameplay popups while a window is open

A window blocks a category of interaction while it's open. Gameplay code checks the category before it
shows a popup. Neither side needs to know about the other.

Blocking, from the window's module, when the window opens and closes:

```gdscript
var svc_policy_store: CapPolicyStore


func _on_window_mounted(window: Node) -> void:
	svc_policy_store.block(PolicyStoreTypes.Category.OPEN_GAMEPLAY_POPUP_UI, window)
	window.tree_exiting.connect(_on_window_unmounting.bind(window))


func _on_window_unmounting(window: Node) -> void:
	svc_policy_store.unblock(PolicyStoreTypes.Category.OPEN_GAMEPLAY_POPUP_UI, window)
```

Checking, from the gameplay code that would show the popup:

```gdscript
if not _svc_policy_store.is_allowed(PolicyStoreTypes.Category.OPEN_GAMEPLAY_POPUP_UI):
	return

_svc_popups.open_popup_queued(REWARD_PATH, Color(0, 0, 0, 0), _configure_reward.bind(reward))
```

A category is allowed by default, blocked while a source holds it, and allowed again once the
source is freed. The window's blocks are released automatically if the window is destroyed without
unblocking. See [Policy Store](guides/policy-store.md).

## Show a confirmation before quitting

A confirmation Popup that a menu opens. Escape closes the confirmation first, then the menu.

```gdscript
func _on_quit_pressed() -> void:
	var dialog: Control = svc_popups.open_popup(CONFIRM_PATH, menu_popup, Vector2.ZERO, true)
	if not dialog:
		return
	
	dialog.confirmed.connect(_on_quit_confirmed)


func _on_quit_confirmed() -> void:
	get_tree().quit()
```

Passing the menu popup as `parent` nests the confirmation under it. `is_blocking = true` stops the menu
from closing while the confirmation is open. See [Popups](guides/popups.md#nesting-and-blocking).

## Queue several notifications from one event

Use the queue so they show one at a time, in order:

```gdscript
func _grant_rewards(rewards: Array[Reward]) -> void:
	for reward in rewards:
		svc_popups.open_popup_queued(REWARD_PATH, Color(0, 0, 0, 0), _configure_reward.bind(reward))


static func _configure_reward(popup: RewardDialog, reward: Reward) -> void:
	popup.configure(reward)
```

`static` plus `bind()` keeps the callable from holding `self`. If the caller is freed before its popups
open, nothing is captured by mistake. See [Popups](guides/popups.md#queueing).

## Hover tooltip on an item slot

```gdscript
func _on_mouse_entered() -> void:
	_svc_tooltips.show_tooltip(
		ITEM_TOOLTIP.resource_path, self, {&"title": item_name, &"description": item_description},
		get_viewport().get_visible_rect()
	)


func _on_mouse_exited() -> void:
	_svc_tooltips.hide_tooltip()
```

Call `hide_tooltip()` before showing another, because a second tooltip is refused while one is up.
See [Tooltips](guides/tooltips.md).

## A nameplate above a character

Put a `WorldUiPortal` inside the nameplate scene, with `target_ui` set to the nameplate root and
`anchor_mode = WORLD_FOLLOW`. The portal follows the nameplate's owner, or the owner's parent if the
owner isn't a `Node2D`. Turn on `mirror_anchor_visuals` if the character's visibility should hide the
nameplate too.

See [World UI](guides/world-ui.md) and the demo's `demo/modules/player/content/ui/nameplate.tscn`.

## Share a value between two Attachments from one module

Create one state object in the module's `register()` and pass it to both Attachments:

```gdscript
class MyFeatureModule extends GdlrModule:
	var reg_attachments: CapUiAttachmentsRegistry


	func register() -> void:
		var state := MyFeatureState.new()
		reg_attachments.register_attachment(SetButtonAttachment.new(state))
		reg_attachments.register_attachment(LabelAttachment.new(state))
```

The demo's `equipment` module does this. See
[Attachments and Attachment Slots](guides/attachments-and-slots.md#sharing-state-between-sibling-attachments).

## Next

- [FAQ and troubleshooting](faq-and-troubleshooting.md): when a recipe doesn't behave as expected.
- [Capabilities API](reference/capabilities-api.md): every method these recipes call.
