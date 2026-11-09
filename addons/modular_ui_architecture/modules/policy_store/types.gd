# Built-in Policy Store categories. Projects declare their own categories from a module's
# register(), through CapPolicyCategoriesRegistry.

## Whether opening UIs as windows is allowed.[br]
## Not consumed by this addon's demo — kept as an example of a second, independent category.
const OPEN_WINDOW_UI := &"open_window_ui"
## Whether opening popups triggered by gameplay events (e.g. item-reward notifications) is
## allowed. Popups opened from an already-active UI flow (e.g. a confirmation dialog) are
## intentionally not gated by this category.
const OPEN_GAMEPLAY_POPUP_UI := &"open_gameplay_popup_ui"
