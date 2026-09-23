@tool
extends Tooltip


@onready var _title_label: Label = %TitleLabel


func _initialize(tooltip_data: Dictionary[StringName, Variant]) -> void:
	_title_label.text = tooltip_data.get(&"title", "")
	description.text = tooltip_data.get(&"description", "")
