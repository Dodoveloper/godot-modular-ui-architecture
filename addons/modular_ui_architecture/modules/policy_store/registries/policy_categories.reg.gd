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


func is_category_registered(category: StringName) -> bool:
	return _categories.has(category)
