@tool
class_name ToggleableDisplay
extends Control
## Base class for dismissable UI displays managed by external systems or local scene logic.
##
## It provides shared request signals, input hooks, input-blocking and focus-handling behavior while
## remaining agnostic to whether the display is shown/hidden, instantiated/freed, or otherwise
## controlled.[br]
## This class is intended to be subclassed and customized.


enum MountMode {
	## Pre-instantiated, visibility toggled externally or via [member toggle_action].
	CACHED,
	## Mounted/unmounted every time, [member close_action] signals unmount.
	LAZY_LOADED,
}

signal open_requested
signal close_requested

## The display's mount mode.
@export var mount_mode := MountMode.CACHED:
	set(value):
		mount_mode = value
		notify_property_list_changed()
		update_configuration_warnings()
## Whether this display should block player inputs while its visible.
@export var should_block_inputs := true
## [b]Optional[/b] input action available that toggles the visibility of this display when pressed
## ([code]CACHED[/code] mode only).[br]
## [b]NOTE:[/b] It must be a valid input action registered under [InputMap].
@export var toggle_action := &"":
	set(value):
		toggle_action = value
		update_configuration_warnings()
## [b]Optional[/b] input action that unmounts this display when pressed
## ([code]LAZY_LOADED[/code] mode only).
## Leave empty to disable keyboard-based unmounting; the display can still be closed via
## [method _request_close] or other mechanisms.[br]
## [b]NOTE:[/b] It must be a valid input action registered under [InputMap].
@export var close_action := &"":
	set(value):
		close_action = value
		update_configuration_warnings()
## Whether focus should be restored to the control that had focus before this display was shown,
## once it gets hidden or removed from the tree. Focus is left alone if it was moved outside of
## this display in the meantime.
@export var restore_focus_on_close := false
## Whether keyboard/gamepad focus should be kept inside this display while it's visible.[br]
## Works by disabling focus for the topmost [Control] ancestor of this display, so only controls
## under that same root are affected. Controls outside that root (e.g. on another [CanvasLayer])
## remain focusable.
@export var trap_focus := false

## Whether [member _input] has already blocked inputs for the current visible session.
var _is_blocking_inputs := false
## Whether focus has been activated for the current visible session.
var _is_focus_active := false
## Control that had focus when this display was shown, restored on hide if
## [member restore_focus_on_close] is enabled.
var _previous_focus_owner: Control
## Topmost [Control] ancestor whose [member Control.focus_behavior_recursive] is overridden while
## focus is trapped. Null when not trapping.
var _trap_root: Control
## Original [member Control.focus_behavior_recursive] of [member _trap_root], restored on release.
var _trap_root_behavior: Control.FocusBehaviorRecursive
## Original [member Control.focus_behavior_recursive] of this display, restored on release.
var _own_behavior: Control.FocusBehaviorRecursive


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	
	_deactivate_focus()
	_unblock_inputs()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	
	var viewport := get_viewport()
	if _handle_input(event):
		viewport.set_input_as_handled()


func _validate_property(property: Dictionary) -> void:
	match property.name:
		"toggle_action":
			if mount_mode != MountMode.CACHED:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"close_action":
			if mount_mode != MountMode.LAZY_LOADED:
				property.usage = PROPERTY_USAGE_NO_EDITOR


#region Custom Virtual Methods
## Virtual method. Override to choose the [Control] that receives focus when this display is
## shown. It must be this display or one of its descendants. It is focused, deferred, every time
## this display becomes visible. Defaults to this display itself; return [code]null[/code] to skip
## focusing.
func _get_initial_focus_target() -> Control:
	return self


@warning_ignore("unused_parameter")
## Virtual. Override to add custom input handling (e.g. a busy check).
## The base implementation handles the mode's close/toggle action automatically.[br]
## Should return [code]true[/code] if the event is marked for consumption
## (prevents further propagation), [code]false[/code] otherwise.
func _handle_input(event: InputEvent) -> bool:
	match mount_mode:
		MountMode.LAZY_LOADED:
			if close_action and event.is_action_pressed(close_action):
				_request_close()
				return true
		MountMode.CACHED:
			if toggle_action and event.is_action_pressed(toggle_action):
				if visible:
					_request_close()
				else:
					_request_open()
				return true
	
	return false


## Virtual method. Override to handle opening logic.
func _open() -> void:
	pass


## Virtual method. Override to handle closing logic.
func _close() -> void:
	pass


## Virtual method. Override to handle open requests. It should emit [signal open_requested].
func _request_open() -> void:
	open_requested.emit()


## Virtual method. Override to handle close requests. It should emit [signal close_requested].
func _request_close() -> void:
	close_requested.emit()


## Virtual method. Override to implement the actual input-blocking logic.
func _on_block_inputs() -> void:
	pass


## Virtual method. Override to implement the actual input-unblocking logic.
func _on_unblock_inputs() -> void:
	pass
#endregion


#region Public API
## Invokes this display’s local open hook.[br]
## This method does not impose any specific lifecycle model; subclasses may use it to
## show themselves, start animations, populate state, or do nothing.
func open() -> void:
	_open()


## Invokes this display’s local close hook.[br]
## This method does not impose any specific lifecycle model; subclasses may use it to
## hide themselves, start close animations, emit signals, or do nothing.
func close() -> void:
	_close()
#endregion


## Blocks inputs through [method _on_block_inputs], if [member should_block_inputs] is enabled.
func _block_inputs() -> void:
	if not should_block_inputs:
		return
	if _is_blocking_inputs:
		return
	
	_is_blocking_inputs = true
	_on_block_inputs()


## Unblocks inputs through [method _on_unblock_inputs], if inputs are currently blocked.
func _unblock_inputs() -> void:
	if not _is_blocking_inputs:
		return
	
	_is_blocking_inputs = false
	_on_unblock_inputs()


## Returns whether [param node] is this display or one of its descendants.
func _is_inside_display(node: Node) -> bool:
	return node != null and (node == self or is_ancestor_of(node))


## Starts a visible session: remembers the current focus owner (unless it's inside this display),
## optionally traps focus, and grabs focus for [method _get_initial_focus_target].
func _activate_focus() -> void:
	if _is_focus_active or not is_inside_tree():
		return
	
	_is_focus_active = true
	var focus_owner := get_viewport().gui_get_focus_owner()
	_previous_focus_owner = null if _is_inside_display(focus_owner) else focus_owner
	
	if trap_focus:
		_trap_focus()
	_grab_initial_focus()


## Ends the visible session: releases any focus trap, then restores the previous focus owner if
## [member restore_focus_on_close] is enabled and focus hasn't been moved outside this display.
func _deactivate_focus() -> void:
	if not _is_focus_active:
		return
	
	_is_focus_active = false
	_release_trapped_focus()
	
	var previous := _previous_focus_owner
	_previous_focus_owner = null
	if not restore_focus_on_close or not is_instance_valid(previous):
		return
	if not previous.is_inside_tree() or not previous.is_visible_in_tree():
		return
	
	# Only restore if nothing outside this display has taken focus in the meantime.
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner == null or _is_inside_display(focus_owner):
		previous.grab_focus()


## Focuses [method _get_initial_focus_target], deferred. Makes this display focusable when it is
## its own focus target.
func _grab_initial_focus() -> void:
	var focus_target := _get_initial_focus_target()
	if not focus_target:
		return
	
	if focus_target == self:
		focus_mode = Control.FOCUS_ALL
	focus_target.grab_focus.call_deferred()


## Disables focus for the topmost [Control] ancestor, and explicitly enables it for this display,
## so that focus navigation can't reach controls outside of this display.
func _trap_focus() -> void:
	_trap_root = self
	while _trap_root.get_parent() is Control:
		_trap_root = _trap_root.get_parent()
	if _trap_root == self:
		_trap_root = null
		return
	
	_trap_root_behavior = _trap_root.focus_behavior_recursive
	_own_behavior = focus_behavior_recursive
	_trap_root.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	focus_behavior_recursive = Control.FOCUS_BEHAVIOR_ENABLED


## Restores the [member Control.focus_behavior_recursive] values changed by [method _trap_focus].
func _release_trapped_focus() -> void:
	if not is_instance_valid(_trap_root):
		return
	
	_trap_root.focus_behavior_recursive = _trap_root_behavior
	focus_behavior_recursive = _own_behavior
	_trap_root = null


## Uses [method Node.is_visible_in_tree] rather than [member CanvasItem.visible], so that a
## display hidden through an ancestor (e.g. a parent [ColorRect]) is treated as hidden too.
func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		_block_inputs()
		_activate_focus()
	else:
		_unblock_inputs()
		_deactivate_focus()
