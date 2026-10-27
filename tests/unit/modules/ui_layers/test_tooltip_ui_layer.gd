extends GutTest
## Unit tests for [code]TooltipUiLayer[/code] acceptance rules. Positioning is not covered here
## because it needs a laid-out tooltip; see the tooltip tests in tests/unit/modules/tooltips.


const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const UiLayersService = preload("res://addons/modular_ui_architecture/modules/ui_layers/services/ui_layers.svc.gd")

const NON_TOOLTIP_SCENE_PATH := "res://tests/fixtures/scenes/empty_control.tscn"

var _service: UiLayersService


func before_each() -> void:
	_service = UiLayersService.new()
	_service.enable()
	await wait_process_frames(2)


func after_each() -> void:
	_service.disable()
	await wait_process_frames(1)


func test_scene_that_is_not_a_tooltip_is_rejected() -> void:
	var anchor := Control.new()
	add_child_autofree(anchor)
	var data: Dictionary[StringName, Variant] = {&"anchor": anchor}

	var node := _service.mount_ui(NON_TOOLTIP_SCENE_PATH, UiLayersTypes.UiLayer.TOOLTIP, data)

	assert_null(node)
