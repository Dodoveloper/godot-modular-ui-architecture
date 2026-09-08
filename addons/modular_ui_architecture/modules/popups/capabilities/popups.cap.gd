@abstract
class_name CapPopups
extends GdlrCapability
## Offers a way to make a [Control] node act like a popup, i.e. an interface element that appears
## over the main content to display extra information or options.
## 
## Popups can be mounted through this service and removed in one of the following ways:[br]
## - By clicking outside of their rect[br]
## - By pressing the default input mapped to escaping UI[br]
## - Via the popup itself, if it supports that, for example by pressing a close button[br]
## Popup scenes may optionally implement [code]begin_close_transition(reason: PopupTypes.CloseReason)[/code]
## and emit [signal close_transition_finished] to delay unmounting while a close
## animation plays.[br]
## This service also supports hierarchy - in the sense it can allow a popup to be mounted as a 
## child of another one - and [i]blocking[/i] popups - i.e. popups which can stop a parent from
## closing the whole stack.[br]
## Popups' lifecycles should be exclusively managed through this class.


const UiLayersTypes = preload("../../ui_layers/types.gd")
const PopupTypes = preload("../types.gd")

@abstract func enable() -> void
@abstract func disable() -> void
## Allows showing a popup by instantiating and registering it.[br]
## [br]
## [param popup_path] - Path of the node to be made popup.[br]
## [param parent] - The parent popup for the new one. If it's not registered, it gets ignored. 
## Used to enable hierarchy.[br]
## [param position] - The spawn position for the popup.[br]
## [param is_blocking] - Whether the popup should be blocking or not.
## 		Blocking popups prevent their ancestors from being closed[br]
## [param color] - Color to be applied to the popup's background.[br]
## [param dismiss_on_click_outside] - Whether clicking on the background dismisses the popup.[br]
## Returns the instantiated popup, or [code]null[/code] if an error occurred.
@abstract func open_popup(
	popup_path: String, parent: Control = null, position := Vector2.ZERO,
	is_blocking := false, color := Color(0.0, 0.0, 0.0, 0.0),
	dismiss_on_click_outside := true
) -> Control
## Opens a popup immediately and enqueues it if another popup from a previous
## [method open_popup_queued] call is still open. Queued popups open in FIFO order,
## one at a time. Intended for popups that should not overlap visually.[br]
## Queue progression happens when the currently-open queued popup leaves the
## scene tree. A popup may optionally emit [signal close_requested] to ask the
## popup layer to start the close flow.[br]
## [br]
## [param popup_path] - Path of the scene to instantiate.[br]
## [param color] - Background color behind the popup.[br]
## [param setup] - Optional [code]callable(popup: Control) -> void[/code] invoked
## 		after instantiation to configure the popup.[br]
## [param dismiss_on_click_outside] - Whether clicking on the background dismisses the popup.
@abstract func open_popup_queued(
	popup_path: String, color := Color(0.0, 0.0, 0.0, 0.5), setup := Callable(),
	dismiss_on_click_outside := false
) -> void
## Closes a popup.
## Close transitions are only honored for the popup directly requested to close.[br]
## [br]
## [param popup] - The popup to be closed.[br]
## Returns [code]true[/code] if the popup was successfully closed.
@abstract func close_popup(popup: Control) -> bool
