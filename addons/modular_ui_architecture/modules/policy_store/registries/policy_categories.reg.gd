extends CapPolicyCategoriesRegistry


var _categories: Dictionary[StringName, bool] = {}


func register_category(category: StringName) -> void:
	if category.is_empty():
		push_error("Policy category cannot be empty")
		return
	if _categories.has(category):
		push_error("Policy category '%s' is already registered" % category)
		return
	
	_categories[category] = true


func unregister_category(category: StringName) -> void:
	if not _categories.has(category):
		push_error("No policy category registered for '%s'" % category)
		return
	
	_categories.erase(category)
	category_unregistered.emit(category)


func is_category_registered(category: StringName) -> bool:
	return _categories.has(category)
