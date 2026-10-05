const PopupsModule = preload("res://addons/modular_ui_architecture/modules/popups/popups.md.gd")
const PolicyStoreModule = preload("res://addons/modular_ui_architecture/modules/policy_store/policy_store.md.gd")

## No providers of its own — [Chest] resolves [CapPopups]/[CapPolicyStore] directly via
## [code]GdlrModuleManager.request()[/code] (see [WorldUiPortal] for the same pattern).
## Importing both modules here makes that dependency explicit rather than relying on another
## module incidentally pulling them into the graph.
static var IMPORTS := [
	PopupsModule,
	PolicyStoreModule,
]


class ChestModule extends GdlrModule:
	pass
