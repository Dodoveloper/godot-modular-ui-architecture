extends Control


const Player = preload("res://demo/modules/player/content/entities/player.gd")

@onready var _label: Label = %Label


func _ready() -> void:
	var player: Player = get_tree().get_first_node_in_group(&"player")
	if not player:
		push_error("Nameplate could not find a node in the 'player' group")
		return

	_label.text = player.character_name
	player.name_changed.connect(_on_player_name_changed)


func _on_player_name_changed(new_name: String) -> void:
	_label.text = new_name
