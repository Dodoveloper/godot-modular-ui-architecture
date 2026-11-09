@abstract
class_name CapPolicyStore
extends GdlrCapability


@abstract func enable() -> void
@abstract func disable() -> void
## Blocks a policy [param category] for a given [param source].[br]
## Multiple sources may block the same category simultaneously. A category is
## considered allowed again only when all of its blockers have been removed or invalidated.
## An unregistered category pushes an error and is not blocked.
## [br]
## [param category] - The policy category to block. It must be registered through
## [CapPolicyCategoriesRegistry].[br]
## [param source] - Object responsible for the block. Used to identify and later
## remove this blocker.
@abstract func block(category: StringName, source: Object) -> void
## Removes a previously-registered blocker for [param category].[br]
## [br]
## [param category] - The policy category to unblock.[br]
## [param source] - Object responsible for the original block.
@abstract func unblock(category: StringName, source: Object) -> void
## Returns whether [param category] is currently allowed.[br]
## Implementations may prune stale blockers whose source objects are no longer
## valid before computing the result. An unregistered category pushes an error and is allowed.
## [br]
## [param category] - The policy category to query.
@abstract func is_allowed(category: StringName) -> bool
## Returns the currently-valid blockers for [param category].[br]
## Invalid or freed blockers should not be included in the returned array.
## [br]
## [param category] - The policy category to query.[br]
## Returns the list of valid blocker objects.
@abstract func get_blockers(category: StringName) -> Array[Object]
