const RegPolicyCategories = preload("./registries/policy_categories.reg.gd")
const PolicyStoreSvc = preload("./services/policy_store.svc.gd")


static var PROVIDERS := {
	CapPolicyCategoriesRegistry: {
		"use": RegPolicyCategories,
	},
	CapPolicyStore: {
		"inject": [CapPolicyCategoriesRegistry],
		"use": PolicyStoreSvc,
	}
}

static var EXPORTS := [
	CapPolicyCategoriesRegistry,
	CapPolicyStore,
]

static var TREE_EXPORTS := [
	CapPolicyStore,
]


class PolicyStoreModule extends GdlrModule:
	var _svc_policy_store: CapPolicyStore
	
	
	func enable() -> void:
		_svc_policy_store.enable()
	
	
	func disable() -> void:
		_svc_policy_store.disable()
