const PolicyStoreModule = preload("res://addons/modular_ui_architecture/modules/policy_store/policy_store.md.gd")

static var IMPORTS := [
	PolicyStoreModule,
]


class PoliciesModule extends GdlrModule:
	var reg_policy_categories: CapPolicyCategoriesRegistry
	
	
	func register() -> void:
		reg_policy_categories.register_category(Tokens.Policies.Categories.OPEN_GAMEPLAY_POPUP_UI)
