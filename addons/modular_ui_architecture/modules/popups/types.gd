enum CloseReason {
	## Close requested via the Popups Service.
	SERVICE,
	## Close requested by clicking outside the Popup's rect.
	BACKGROUND_CLICK,
	## Close requested by pressing the [code]ui_cancel[/code] input.
	UI_CANCEL,
	## Close requested by the Popup itself.
	POPUP,
}
