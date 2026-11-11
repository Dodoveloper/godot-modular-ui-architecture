@abstract
class_name CapPolicyCategoriesRegistry
extends GdlrCapability


## Emitted after [param category] is unregistered.
signal category_unregistered(category: StringName)


## Registers a policy category, so [CapPolicyStore] accepts it.[br]
## [br]
## [param category] - A unique [StringName] token, for example [code]&"open_shop"[/code].
@abstract func register_category(category: StringName) -> void
## Unregisters a policy category, and emits [signal category_unregistered].[br]
## [br]
## [param category] - The policy category to unregister.
@abstract func unregister_category(category: StringName) -> void
## Returns whether [param category] has been registered.[br]
## [br]
## [param category] - The policy category to query.
@abstract func is_category_registered(category: StringName) -> bool
