extends GameUiTypes.UiAttachment


const GameUiTypes = preload("res://addons/modular_ui_architecture/modules/game_ui/types.gd")
const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const Hud = preload("res://demo/modules/hud/content/ui/hud.gd")

const PM_BUTTON_PATH = "res://demo/modules/pause_menu/content/ui/pause_menu_button.tscn"
const INPUT_ACTION = &"toggle_pause"

var _svc_input_bindings: CapInputBindings


func _init(svc_input_bindings: CapInputBindings) -> void:
	_svc_input_bindings = svc_input_bindings
	_Scene = load(PM_BUTTON_PATH)
	_slot_tag = &"bottom_right"
	_priority = 10


func _should_mount(host_ui: Node, _context: RefCounted) -> bool:
	return host_ui is Hud


func _build(host_ui: Node, context: RefCounted) -> Control:
	var button: Button = super(host_ui, context)
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	button.pressed.connect(_on_button_pressed)
	
	return button


func _on_button_pressed() -> void:
	_svc_input_bindings.trigger_bindings(INPUT_ACTION, UiLayersTypes.UiLayer.WINDOW)
