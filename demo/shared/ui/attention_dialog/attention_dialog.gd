@tool
extends ToggleableDisplay


const PopupTypes = preload("res://addons/modular_ui_architecture/modules/popups/types.gd")
const InputManager = preload("res://demo/shared/classes/input_manager.gd")

signal close_transition_finished

const OPEN_ANIMATION := &"open"
const CLOSE_ANIMATION := &"close"

@export var animation_player: AnimationPlayer:
	set(value):
		animation_player = value
		update_configuration_warnings()
@export var close_button: BaseButton:
	set(value):
		close_button = value
		update_configuration_warnings()
@export var headline_label: Label:
	set(value):
		headline_label = value
		update_configuration_warnings()
@export var main_text_label: Label:
	set(value):
		main_text_label = value
		update_configuration_warnings()
@export var amount_label: Label:
	set(value):
		amount_label = value
		update_configuration_warnings()
@export var display_texture: TextureRect:
	set(value):
		display_texture = value
		update_configuration_warnings()

var _config := Config.new()


func _exit_tree() -> void:
	super()
	
	if Engine.is_editor_hint():
		return
	
	release_focus()


func _ready() -> void:
	super()
	
	if Engine.is_editor_hint():
		return
	
	assert(animation_player, "animation_player not set")
	assert(close_button, "close_button not set")
	assert(headline_label, "headline_label not set")
	assert(main_text_label, "main_text_label not set")
	assert(amount_label, "amount_label not set")
	assert(display_texture, "display_texture not set")
	
	animation_player.animation_finished.connect(_on_animation_player_animation_finished)
	close_button.pressed.connect(_on_close_button_pressed)
	_apply_config()
	
	if animation_player.has_animation(OPEN_ANIMATION):
		animation_player.play(OPEN_ANIMATION)
		animation_player.seek(0.0, true)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not animation_player:
		warnings.append("Animaton Player must be set")
	if not close_button:
		warnings.append("Close Button must be set")
	if not headline_label:
		warnings.append("Headline Label must be set")
	if not main_text_label:
		warnings.append("Main Text Label must be set")
	if not amount_label:
		warnings.append("Amount Label must be set")
	if not display_texture:
		warnings.append("Display Wrapper must be set")
	
	return warnings


func _get_initial_focus_target() -> Control:
	return close_button


func _on_block_inputs() -> void:
	InputManager.block()


func _on_unblock_inputs() -> void:
	InputManager.unblock()


## Applies display data to the dialog.[br]
## This method only updates presentation state and does [b]not[/b] control popup lifecycle,
## queueing, or visibility.
func configure(config: Config) -> void:
	_config = config
	if Engine.is_editor_hint():
		return
	if not is_node_ready():
		return
	
	_apply_config()


func begin_close_transition(_reason: PopupTypes.CloseReason) -> void:
	if not animation_player.has_animation(CLOSE_ANIMATION):
		close_transition_finished.emit()
		return
	
	animation_player.play(CLOSE_ANIMATION)


func _apply_config() -> void:
	headline_label.text = _config.headline
	main_text_label.text = _config.main_text
	
	display_texture.texture = _config.texture
	
	var should_show_amount := _config.amount > 1 and not _config.suppress_amount_label
	amount_label.text = ""
	if should_show_amount:
		amount_label.text = "x%s" % [_config.amount]
	amount_label.visible = should_show_amount


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		CLOSE_ANIMATION:
			close_transition_finished.emit()


func _on_close_button_pressed() -> void:
	_request_close()


class Config extends RefCounted:
	## Headline shown above the main content.
	var headline := "You obtained"
	## Main text describing what the player obtained or unlocked.
	var main_text := ""
	## Optional amount associated with the content.
	## Only values greater than [code]1[/code] are shown.
	var amount := 1
	## When [code]true[/code], the amount label is hidden regardless of [member amount].
	var suppress_amount_label := false
	## Image representing the dialog content, displayed via a [TextureRect].
	var texture: Texture2D = null
