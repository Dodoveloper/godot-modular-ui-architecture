extends GutTest
## Unit tests for [code]SceneCache[/code].


const SceneCache = preload("res://addons/modular_ui_architecture/shared/classes/scene_cache.gd")

const SCENE_PATH := "res://tests/fixtures/scenes/empty_control.tscn"
const NOT_A_SCENE_PATH := "res://tests/fixtures/scripts/base_script.gd"
const MISSING_PATH := "res://tests/fixtures/scenes/does_not_exist.tscn"


func before_each() -> void:
	SceneCache.clear_cache()


func after_all() -> void:
	SceneCache.clear_cache()


func test_load_scene_returns_packed_scene() -> void:
	var scene := SceneCache.load_scene(SCENE_PATH)

	assert_not_null(scene)
	assert_true(scene is PackedScene)


func test_load_scene_returns_same_instance_on_repeat_calls() -> void:
	var first := SceneCache.load_scene(SCENE_PATH)
	var second := SceneCache.load_scene(SCENE_PATH)

	assert_same(first, second)


## NOTE: Godot's ResourceLoader also caches loaded resources, so identity after an evict is not
## observable here. These tests therefore assert the public contract: eviction/clearing never
## breaks subsequent loads, and the scene is still returned.
func test_evict_keeps_scene_loadable() -> void:
	SceneCache.load_scene(SCENE_PATH)
	SceneCache.evict(SCENE_PATH)

	assert_not_null(SceneCache.load_scene(SCENE_PATH))


func test_clear_cache_keeps_scene_loadable() -> void:
	SceneCache.load_scene(SCENE_PATH)
	SceneCache.clear_cache()

	assert_not_null(SceneCache.load_scene(SCENE_PATH))


func test_evict_unknown_path_is_a_no_op() -> void:
	SceneCache.evict(SCENE_PATH)

	assert_not_null(SceneCache.load_scene(SCENE_PATH))


## NOTE: GUT only consumes errors recorded before the assertion runs, so assertions go after the call.
func test_load_scene_returns_null_and_pushes_error_for_missing_file() -> void:
	var scene := SceneCache.load_scene(MISSING_PATH)

	assert_null(scene)
	# Godot reports a missing file with two engine errors (the load failure and its condition).
	assert_engine_error_count(2)
	assert_push_error("SceneCache: failed to load resource")


func test_load_scene_returns_null_for_non_scene_resource() -> void:
	var scene := SceneCache.load_scene(NOT_A_SCENE_PATH)

	assert_null(scene)
	assert_push_error("is not a PackedScene")
