extends CapInputBindings


var _reg_input_bindings: CapInputBindingsRegistry
var _svc_ui_layers: CapUiLayers


func _init(reg_input_bindings: CapInputBindingsRegistry, svc_ui_layers: CapUiLayers) -> void:
	_reg_input_bindings = reg_input_bindings
	_svc_ui_layers = svc_ui_layers
	
	_svc_ui_layers.ui_layer_input_triggered.connect(_on_svc_ui_layers_input_triggered)


func enable() -> void:
	print("UI Input Actions Service enabled")


func disable() -> void:
	print("UI Input Actions Service disabled")


func trigger_bindings(
	action: StringName, layer := UiLayersTypes.UiLayer.DEFAULT,
	input_type := InputBindingsTypes.InputActionType.PRESSED
) -> bool:
	var bindings := _reg_input_bindings.get_bindings(action)
	if not bindings:
		return false
	
	var has_binding_executed := false
	for binding in bindings:
		if not binding.layer == layer or binding.input_type != input_type:
			continue
		if not binding.should_execute():
			continue
		
		binding.execute()
		has_binding_executed = true
		
		var tree := Engine.get_main_loop() as SceneTree
		tree.root.set_input_as_handled()
		# Prevent two bindings on the same action from both executing in one call.
		break
	
	return has_binding_executed


func _on_svc_ui_layers_input_triggered(
	action: StringName, layer: UiLayersTypes.UiLayer, input_type: InputBindingsTypes.InputActionType
) -> void:
	trigger_bindings(action, layer, input_type)
