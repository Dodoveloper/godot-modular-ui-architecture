extends CapInputBindingsRegistry


## Bindings keyed by action name. Each array is maintained in descending [member InputBinding.priority]
## order, with registration order as the stable tiebreaker within equal-priority groups.
var _bindings_by_action: Dictionary[StringName, Array] = {}


func register_binding(action: StringName, binding: InputBindingsTypes.InputBinding) -> void:
	var arr: Array[InputBindingsTypes.InputBinding] = _bindings_by_action.get_or_add(
		action, [] as Array[InputBindingsTypes.InputBinding]
	)
	# Insert after all bindings with priority >= this one (descending, stable)
	var i := 0
	while i < arr.size() and arr[i].priority >= binding.priority:
		i += 1
	arr.insert(i, binding)


func unregister_binding(action: StringName, binding: InputBindingsTypes.InputBinding) -> void:
	if not _bindings_by_action.has(action):
		push_error("No bindings registered for action '%s'" % action)
		return
	
	_bindings_by_action[action].erase(binding)


func get_bindings(action: StringName) -> Array[InputBindingsTypes.InputBinding]:
	return _bindings_by_action.get(action, [] as Array[InputBindingsTypes.InputBinding])


func get_actions() -> Array[StringName]:
	return _bindings_by_action.keys()
