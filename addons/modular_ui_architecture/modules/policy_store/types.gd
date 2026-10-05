# NOTE: this can be customized based on the project's needs.
enum Category {
	## Whether opening UIs as windows is allowed.[br]
	## Not consumed by this addon's demo — kept as an example of a second, independent category.
	OPEN_WINDOW_UI,
	## Whether opening popups triggered by gameplay events (e.g. item-reward notifications) is
	## allowed. Popups opened from an already-active UI flow (e.g. a confirmation dialog) are
	## intentionally not gated by this category.
	OPEN_GAMEPLAY_POPUP_UI,
}
