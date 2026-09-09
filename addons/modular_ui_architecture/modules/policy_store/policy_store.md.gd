const PolicyStoreSvc = preload("./services/policy_store.svc.gd")


static var PROVIDERS := {
	CapPolicyStore: {
		"use": PolicyStoreSvc,
	}
}

static var EXPORTS := [
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
