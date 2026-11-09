const PopupsModule = preload("res://addons/modular_ui_architecture/modules/popups/popups.md.gd")
const PolicyStoreModule = preload("res://addons/modular_ui_architecture/modules/policy_store/policy_store.md.gd")
const PoliciesModule = preload("res://demo/modules/policies/policies.md.gd")

## No providers of its own — [Chest] resolves [CapPopups]/[CapPolicyStore] directly via
## [code]GdlrModuleManager.request()[/code] (see [WorldUiPortal] for the same pattern).
## Importing the modules here makes those dependencies explicit rather than relying on another
## module incidentally pulling them into the graph.
static var IMPORTS := [
	PopupsModule,
	PolicyStoreModule,
	PoliciesModule,
]


class ChestModule extends GdlrModule:
	pass
