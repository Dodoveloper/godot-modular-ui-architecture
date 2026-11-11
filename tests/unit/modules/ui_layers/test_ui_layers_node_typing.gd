extends GutTest
## Regression tests for the uniform [code]Node[/code] element type of the layer pipeline.
## A typed Array[Control] used to reject has() for plain Nodes, so these must not error.


const PopupsTypes = preload("res://addons/modular_ui_architecture/modules/popups/types.gd")
const UiLayersFixture = preload("res://tests/fixtures/ui_layers/layers.gd")
const UiLayersService = preload("res://addons/modular_ui_architecture/modules/ui_layers/services/ui_layers.svc.gd")
const SCENE_PATH := "res://tests/fixtures/scenes/empty_control.tscn"

var _service: UiLayersService


func before_each() -> void:
	_service = UiLayersFixture.make_service()
	_service.enable()
	await wait_process_frames(2)


func after_each() -> void:
	_service.disable()
	await wait_process_frames(1)


func test_popup_layer_has_accepts_plain_node_without_error() -> void:
	var popups := _service.get_layer_node(PopupsTypes.POPUPS_LAYER)
	var plain := Node.new()
	autofree(plain)

	assert_false(popups.get_mounted_nodes().has(plain))


func test_unmount_ui_finds_plain_node_in_popup_layer() -> void:
	var popup := _service.mount_ui(SCENE_PATH, PopupsTypes.POPUPS_LAYER)

	assert_true(_service.unmount_ui(popup))
