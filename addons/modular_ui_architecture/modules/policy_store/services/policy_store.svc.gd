extends CapPolicyStore


## Mapping of blocked categories.
## [codeblock]
## @shape: {
##   [category: PolicyStoreTypes.Category]: {
##     [source_id: int]: [source: WeakRef]
##   }
## }
## [/codeblock]
var _blocked_categories: Dictionary[PolicyStoreTypes.Category, Dictionary] = {}


func enable() -> void:
	print("CapPolicyStore enabled")


func disable() -> void:
	_blocked_categories.clear()
	print("CapPolicyStore disabled")


func block(category: PolicyStoreTypes.Category, source: Object) -> void:
	if source == null:
		push_error("PolicyStore.block source cannot be null")
		return
	
	var source_id := source.get_instance_id()
	_blocked_categories.get_or_add(category, {})[source_id] = weakref(source)


func unblock(category: PolicyStoreTypes.Category, source: Object) -> void:
	if source == null:
		return
	
	var source_id := source.get_instance_id()
	var blockers: Dictionary = _blocked_categories.get(category, {})
	if blockers.is_empty():
		return

	blockers.erase(source_id)
	if blockers.is_empty():
		_blocked_categories.erase(category)


func is_allowed(category: PolicyStoreTypes.Category) -> bool:
	_prune_dead_blockers(category)

	return (_blocked_categories.get(category, {}) as Dictionary).is_empty()


func get_blockers(category: PolicyStoreTypes.Category) -> Array[Object]:
	_prune_dead_blockers(category)

	var blockers: Array[Object] = []
	var blockers_dict := _blocked_categories.get(category, {}) as Dictionary
	for weak_ref in blockers_dict.values():
		var blocker = (weak_ref as WeakRef).get_ref()
		if blocker != null:
			blockers.append(blocker)
	
	return blockers


func _prune_dead_blockers(category: PolicyStoreTypes.Category) -> void:
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
