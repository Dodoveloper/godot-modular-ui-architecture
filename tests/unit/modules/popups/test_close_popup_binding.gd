extends GutTest
## Unit tests for the built-in [code]ClosePopupBinding[/code] (close_popup.bind.gd).


const PopupsService = preload("res://addons/modular_ui_architecture/modules/popups/services/popups.svc.gd")
const ClosePopupBinding = preload("res://addons/modular_ui_architecture/modules/popups/bindings/close_popup.bind.gd")
const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const UiLayersService = preload("res://addons/modular_ui_architecture/modules/ui_layers/services/ui_layers.svc.gd")

const SCENE_PATH := "res://tests/fixtures/scenes/empty_control.tscn"

var _ui_layers: UiLayersService
var _popups: PopupsService
var _binding: ClosePopupBinding


func before_each() -> void:
	_ui_layers = UiLayersService.new()
	_ui_layers.enable()
	await wait_process_frames(2)
	_popups = PopupsService.new(_ui_layers)
	_binding = ClosePopupBinding.new(_popups)


func after_each() -> void:
	_popups.disable()
	_ui_layers.disable()
	await wait_process_frames(1)


func test_binding_defaults_to_default_layer() -> void:
	assert_eq(_binding.layer, UiLayersTypes.UiLayer.DEFAULT)


func test_should_execute_is_false_without_popups() -> void:
	assert_false(_binding.should_execute())


func test_should_execute_is_true_while_a_popup_is_open() -> void:
	_popups.open_popup(SCENE_PATH)

	assert_true(_binding.should_execute())


func test_execute_closes_topmost_popup() -> void:
	_popups.open_popup(SCENE_PATH)

	_binding.execute()

	assert_false(_popups.has_popups())
