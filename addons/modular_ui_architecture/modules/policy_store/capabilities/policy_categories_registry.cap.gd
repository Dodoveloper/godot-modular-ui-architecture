@abstract
class_name CapPolicyCategoriesRegistry
extends GdlrCapability


## Registers a policy category.[br]
## [br]
## [param category] - A unique [StringName] token, for example [code]&"open_shop"[/code].
@abstract func register_category(category: StringName) -> void
## Returns whether a category has been registered.[br]
## [br]
## [param category] - The policy category to query.
@abstract func is_category_registered(category: StringName) -> bool
