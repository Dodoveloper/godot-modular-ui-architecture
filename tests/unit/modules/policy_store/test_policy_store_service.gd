extends GutTest
## Unit tests for [code]PolicyStoreService[/code].
## Run with: godot --headless --path . -s addons/gut/gut_cmdln.gd


const PolicyStoreTypes = preload("res://addons/modular_ui_architecture/modules/policy_store/types.gd")
const PolicyStoreService = preload("res://addons/modular_ui_architecture/modules/policy_store/services/policy_store.svc.gd")
const PolicyCategoriesRegistry = preload("res://addons/modular_ui_architecture/modules/policy_store/registries/policy_categories.reg.gd")

const CATEGORY := PolicyStoreTypes.OPEN_GAMEPLAY_POPUP_UI
const OTHER_CATEGORY := PolicyStoreTypes.OPEN_WINDOW_UI
const UNREGISTERED_CATEGORY := &"not_registered"

var _store: PolicyStoreService


func before_each() -> void:
	var registry := PolicyCategoriesRegistry.new()
	registry.register_category(CATEGORY)
	registry.register_category(OTHER_CATEGORY)
	_store = PolicyStoreService.new(registry)


func after_each() -> void:
	_store.disable()


func test_is_allowed_by_default() -> void:
	assert_true(_store.is_allowed(CATEGORY))


func test_block_disallows_category() -> void:
	var source := Object.new()
	autofree(source)

	_store.block(CATEGORY, source)

	assert_false(_store.is_allowed(CATEGORY))


func test_block_does_not_affect_other_categories() -> void:
	var source := Object.new()
	autofree(source)

	_store.block(CATEGORY, source)

	assert_true(_store.is_allowed(OTHER_CATEGORY))


func test_unblock_restores_category() -> void:
	var source := Object.new()
	autofree(source)
	_store.block(CATEGORY, source)

	_store.unblock(CATEGORY, source)

	assert_true(_store.is_allowed(CATEGORY))


func test_category_stays_blocked_until_all_sources_unblock() -> void:
	var first := Object.new()
	var second := Object.new()
	autofree(first)
	autofree(second)
	_store.block(CATEGORY, first)
	_store.block(CATEGORY, second)

	_store.unblock(CATEGORY, first)
	assert_false(_store.is_allowed(CATEGORY), "Still blocked by the second source")

	_store.unblock(CATEGORY, second)
	assert_true(_store.is_allowed(CATEGORY), "All sources removed")


func test_blocking_twice_with_same_source_needs_one_unblock() -> void:
	var source := Object.new()
	autofree(source)
	_store.block(CATEGORY, source)
	_store.block(CATEGORY, source)

	_store.unblock(CATEGORY, source)

	assert_true(_store.is_allowed(CATEGORY))


func test_unblock_unknown_source_is_a_no_op() -> void:
	var blocker := Object.new()
	var stranger := Object.new()
	autofree(blocker)
	autofree(stranger)
	_store.block(CATEGORY, blocker)

	_store.unblock(CATEGORY, stranger)

	assert_false(_store.is_allowed(CATEGORY))


func test_unblock_never_blocked_category_is_a_no_op() -> void:
	var source := Object.new()
	autofree(source)

	_store.unblock(CATEGORY, source)

	assert_true(_store.is_allowed(CATEGORY))


func test_unblock_with_null_source_is_a_no_op() -> void:
	var source := Object.new()
	autofree(source)
	_store.block(CATEGORY, source)

	_store.unblock(CATEGORY, null)

	assert_false(_store.is_allowed(CATEGORY))


func test_block_with_null_source_pushes_error_and_does_not_block() -> void:
	_store.block(CATEGORY, null)

	assert_push_error("PolicyStore.block source cannot be null")
	assert_true(_store.is_allowed(CATEGORY))


func test_blocker_freed_without_unblock_is_pruned() -> void:
	var source := Object.new()
	_store.block(CATEGORY, source)
	source.free()

	assert_true(_store.is_allowed(CATEGORY))


func test_get_blockers_returns_valid_sources() -> void:
	var first := Object.new()
	var second := Object.new()
	autofree(first)
	autofree(second)
	_store.block(CATEGORY, first)
	_store.block(CATEGORY, second)

	var blockers := _store.get_blockers(CATEGORY)

	assert_eq(blockers.size(), 2)
	assert_has(blockers, first)
	assert_has(blockers, second)


func test_get_blockers_excludes_freed_sources() -> void:
	var alive := Object.new()
	autofree(alive)
	var dead := Object.new()
	_store.block(CATEGORY, alive)
	_store.block(CATEGORY, dead)
	dead.free()

	var blockers := _store.get_blockers(CATEGORY)

	assert_eq(blockers.size(), 1)
	assert_has(blockers, alive)


func test_get_blockers_is_empty_for_allowed_category() -> void:
	assert_true(_store.get_blockers(CATEGORY).is_empty())


func test_disable_clears_all_blocks() -> void:
	var source := Object.new()
	autofree(source)
	_store.block(CATEGORY, source)

	_store.disable()

	assert_true(_store.is_allowed(CATEGORY))


func test_block_with_unregistered_category_pushes_error_and_does_not_block() -> void:
	var source := Object.new()
	autofree(source)

	_store.block(UNREGISTERED_CATEGORY, source)
	var blockers := _store.get_blockers(UNREGISTERED_CATEGORY)

	# block() and get_blockers() each report the unregistered category.
	assert_push_error("Policy category 'not_registered' is not registered")
	assert_push_error("Policy category 'not_registered' is not registered")
	assert_true(blockers.is_empty())


func test_is_allowed_with_unregistered_category_pushes_error_and_allows() -> void:
	assert_true(_store.is_allowed(UNREGISTERED_CATEGORY))

	assert_push_error("Policy category 'not_registered' is not registered")


func test_unblock_with_unregistered_category_is_a_no_op() -> void:
	var source := Object.new()
	autofree(source)

	_store.unblock(UNREGISTERED_CATEGORY, source)

	assert_push_error("Policy category 'not_registered' is not registered")
	assert_true(_store.is_allowed(CATEGORY))


func test_unregistered_category_drops_its_blockers() -> void:
	var source := Object.new()
	autofree(source)
	var registry := PolicyCategoriesRegistry.new()
	registry.register_category(CATEGORY)
	var store := PolicyStoreService.new(registry)
	store.block(CATEGORY, source)

	registry.unregister_category(CATEGORY)
	var blockers := store.get_blockers(CATEGORY)

	# is_registered reports the unregistered category once per call.
	assert_push_error("Policy category 'open_gameplay_popup_ui' is not registered")
	assert_true(blockers.is_empty())
	store.disable()


func test_unregister_without_a_store_call_still_drops_blockers_on_reregister() -> void:
	var source := Object.new()
	autofree(source)
	var registry := PolicyCategoriesRegistry.new()
	registry.register_category(CATEGORY)
	var store := PolicyStoreService.new(registry)
	store.block(CATEGORY, source)

	registry.unregister_category(CATEGORY)
	registry.register_category(CATEGORY)

	assert_true(store.is_allowed(CATEGORY))
	store.disable()


func test_unregister_does_not_affect_other_categories() -> void:
	var source := Object.new()
	autofree(source)
	var registry := PolicyCategoriesRegistry.new()
	registry.register_category(CATEGORY)
	registry.register_category(OTHER_CATEGORY)
	var store := PolicyStoreService.new(registry)
	store.block(OTHER_CATEGORY, source)

	registry.unregister_category(CATEGORY)

	assert_false(store.is_allowed(OTHER_CATEGORY))
	store.disable()
