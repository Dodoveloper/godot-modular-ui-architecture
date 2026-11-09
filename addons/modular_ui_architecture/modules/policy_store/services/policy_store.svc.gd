extends CapPolicyStore


var _reg_policy_categories: CapPolicyCategoriesRegistry

## Mapping of blocked categories.
## [codeblock]
## @shape: {
##   [category: StringName]: {
##     [source_id: int]: [source: WeakRef]
##   }
## }
## [/codeblock]
var _blocked_categories: Dictionary[StringName, Dictionary] = {}


func _init(reg_policy_categories: CapPolicyCategoriesRegistry) -> void:
	_reg_policy_categories = reg_policy_categories


func enable() -> void:
	print("CapPolicyStore enabled")


func disable() -> void:
	_blocked_categories.clear()
	print("CapPolicyStore disabled")


func block(category: StringName, source: Object) -> void:
	if not _is_registered(category):
		return
	if source == null:
		push_error("PolicyStore.block source cannot be null")
		return
	
	var source_id := source.get_instance_id()
	_blocked_categories.get_or_add(category, {})[source_id] = weakref(source)


func unblock(category: StringName, source: Object) -> void:
	if not _is_registered(category):
		return
	if source == null:
		return
	
	var source_id := source.get_instance_id()
	var blockers: Dictionary = _blocked_categories.get(category, {})
	if blockers.is_empty():
		return
	
	blockers.erase(source_id)
	if blockers.is_empty():
		_blocked_categories.erase(category)


func is_allowed(category: StringName) -> bool:
	if not _is_registered(category):
		return true
	
	_prune_dead_blockers(category)
	
	return (_blocked_categories.get(category, {}) as Dictionary).is_empty()


func get_blockers(category: StringName) -> Array[Object]:
	var blockers: Array[Object] = []
	if not _is_registered(category):
		return blockers
	
	_prune_dead_blockers(category)
	
	var blockers_dict := _blocked_categories.get(category, {}) as Dictionary
	for weak_ref in blockers_dict.values():
		var blocker = (weak_ref as WeakRef).get_ref()
		if blocker != null:
			blockers.append(blocker)
	
	return blockers


## Returns whether [param category] is registered. Pushes an error when it isn't.
func _is_registered(category: StringName) -> bool:
	if _reg_policy_categories.is_category_registered(category):
		return true
	
	push_error("Policy category '%s' is not registered" % category)
	return false


func _prune_dead_blockers(category: StringName) -> void:
	var blockers: Dictionary = _blocked_categories.get(category, {})
	if blockers.is_empty():
		return
	
	var dead_ids: Array[int] = []
	for source_id in blockers.keys():
		var weak_ref: WeakRef = blockers[source_id]
		if weak_ref.get_ref() == null:
			dead_ids.append(source_id)
	
	for dead_id in dead_ids:
		blockers.erase(dead_id)
	if blockers.is_empty():
		_blocked_categories.erase(category)
