@tool
extends ToggleableDisplay


const Player = preload("res://demo/modules/player/content/entities/player.gd")

@onready var _line_edit: LineEdit = %LineEdit
@onready var _confirm_button: Button = %ConfirmButton
@onready var _cancel_button: Button = %CancelButton

var _player: Player


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return
	
	_player = get_tree().get_first_node_in_group(&"player")
	if _player:
		_line_edit.text = _player.character_name
		_line_edit.grab_focus.call_deferred()
		_line_edit.select_all.call_deferred()
	
	_confirm_button.pressed.connect(_on_confirm_button_pressed)
	_cancel_button.pressed.connect(_on_cancel_button_pressed)
	_line_edit.text_submitted.connect(_on_line_edit_text_submitted)


func _on_confirm_button_pressed() -> void:
	_confirm_rename()


func _on_cancel_button_pressed() -> void:
	_request_close()


func _on_line_edit_text_submitted(_new_text: String) -> void:
	_confirm_rename()


func _confirm_rename() -> void:
	var new_name := _line_edit.text.strip_edges()
	if _player and not new_name.is_empty():
		_player.character_name = new_name
	
	_request_close()
