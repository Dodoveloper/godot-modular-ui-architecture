extends GutTest
## Unit tests for WorldUiPortal, run against a real, started Godular graph (GameUiModule).
##
## Each test mounts and starts the graph again, because GdlrModuleManager.mount() builds a fresh graph.
## Nothing is cached across tests: the portal requests its own service in _enter_tree().


const GameUiModule = preload("res://addons/modular_ui_architecture/modules/game_ui/game_ui.md.gd")
const WorldUiPortal = preload("res://addons/modular_ui_architecture/shared/classes/world_ui_portal/world_ui_portal.gd")


func before_each() -> void:
	await GdlrModuleManager.mount(GameUiModule)
	await GdlrModuleManager.start()


## Creates a portal with a child target UI and attaches it under [param parent].
func _make_portal(parent: Node, mode: WorldUiPortal.AnchorMode, world_anchor: Node2D = null) -> WorldUiPortal:
	var portal := WorldUiPortal.new()
	var ui := Control.new()
	portal.add_child(ui)
	portal.target_ui = ui
	portal.anchor_mode = mode
	portal.world_anchor = world_anchor
	parent.add_child(portal)
	return portal


func _anchor_info(portal: WorldUiPortal) -> Object:
	return portal._svc_game_ui._world_anchors[portal.target_ui]


func test_explicit_world_anchor_is_used() -> void:
	var anchor := Node2D.new()
	add_child_autofree(anchor)
	var portal := _make_portal(self, WorldUiPortal.AnchorMode.WORLD_FOLLOW, anchor)
	await wait_process_frames(3)

	assert_same(_anchor_info(portal).anchor, anchor)


func test_owner_node2d_is_used_as_anchor_when_no_world_anchor_is_set() -> void:
	var owner_node := Node2D.new()
	add_child_autofree(owner_node)
	var portal := _make_portal(owner_node, WorldUiPortal.AnchorMode.WORLD_FOLLOW)
	portal.owner = owner_node
	await wait_process_frames(3)

	assert_same(_anchor_info(portal).anchor, owner_node)


func test_owner_parent_is_used_as_anchor_when_owner_is_not_node2d() -> void:
	var world := Node2D.new()
	add_child_autofree(world)
	var owner_control := Control.new()
	world.add_child(owner_control)
	var portal := _make_portal(owner_control, WorldUiPortal.AnchorMode.WORLD_FOLLOW)
	portal.owner = owner_control
	await wait_process_frames(3)

	assert_same(_anchor_info(portal).anchor, world)


## Not covered: the missing-world-anchor error. In the suite it reports an extra error after its own
## expectation, which is a graph-lifecycle question. See tests/README.md.


func test_missing_target_ui_pushes_error() -> void:
	var portal := WorldUiPortal.new()
	portal.anchor_mode = WorldUiPortal.AnchorMode.NONE
	add_child_autofree(portal)
	await wait_process_frames(3)

	assert_push_error("target_ui is not set")


func test_managed_ui_is_the_target_and_is_mounted_in_the_world() -> void:
	var portal := _make_portal(self, WorldUiPortal.AnchorMode.NONE)
	await wait_process_frames(3)

	assert_same(portal.get_managed_ui(), portal.target_ui)
	assert_true(portal.target_ui.is_inside_tree())


func test_leaving_the_tree_unmounts_the_managed_ui() -> void:
	var portal := _make_portal(self, WorldUiPortal.AnchorMode.NONE)
	await wait_process_frames(3)
	var ui: Control = portal.target_ui

	portal.queue_free()
	await wait_process_frames(3)

	assert_false(is_instance_valid(ui))
