extends GutTest
## Unit tests for the shared [code]Utils[/code] helpers.


const Utils = preload("res://addons/modular_ui_architecture/shared/classes/utils.gd")
const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const FakeBaseScript = preload("res://tests/fixtures/scripts/base_script.gd")
const FakeChildScript = preload("res://tests/fixtures/scripts/child_script.gd")
const UnrelatedScript = preload("res://tests/fixtures/scripts/unrelated_script.gd")


func test_enum_to_str_returns_key_for_value() -> void:
	assert_eq(Utils.enum_to_str(UiLayersTypes.UiLayer, UiLayersTypes.UiLayer.HUD), "HUD")


func test_enum_to_str_returns_unknown_for_missing_value() -> void:
	var result := Utils.enum_to_str(UiLayersTypes.UiLayer, 999)

	assert_eq(result, "UNKNOWN")
	assert_push_error("Couldn't find enum value 999")


func test_static_is_type_true_for_same_script() -> void:
	assert_true(Utils.static_is_type(FakeBaseScript, FakeBaseScript))


func test_static_is_type_true_for_ancestor_script() -> void:
	assert_true(Utils.static_is_type(FakeChildScript, FakeBaseScript))


func test_static_is_type_false_for_unrelated_script() -> void:
	assert_false(Utils.static_is_type(UnrelatedScript, FakeBaseScript))


func test_get_scene_node_script_returns_null_for_null_scene() -> void:
	assert_null(Utils.get_scene_node_script(null))


func test_is_scene_of_type_detects_root_script_type() -> void:
	var scene := load("res://tests/fixtures/scenes/scripted_control.tscn") as PackedScene

	assert_true(Utils.is_scene_of_type(scene, FakeBaseScript))


func test_is_scene_of_type_detects_subclass_root_script() -> void:
	var scene := load("res://tests/fixtures/scenes/scripted_child_control.tscn") as PackedScene

	assert_true(Utils.is_scene_of_type(scene, FakeBaseScript))


func test_is_scene_of_type_false_for_unrelated_root_script() -> void:
	var scene := load("res://tests/fixtures/scenes/scripted_control.tscn") as PackedScene

	assert_false(Utils.is_scene_of_type(scene, UnrelatedScript))


func test_is_scene_of_native_type_matches_root_node_class() -> void:
	var scene := load("res://tests/fixtures/scenes/empty_control.tscn") as PackedScene

	assert_true(Utils.is_scene_of_native_type(scene, &"Control"))
	assert_false(Utils.is_scene_of_native_type(scene, &"Node2D"))
