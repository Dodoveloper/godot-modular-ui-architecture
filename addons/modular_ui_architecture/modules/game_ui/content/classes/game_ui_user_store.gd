extends RefCounted


const FILE_PATH := "user://game_ui_user.cfg"

var _config := ConfigFile.new()


func _init() -> void:
	_config.load(FILE_PATH)


## Returns the value for [param key] in [param user_id]'s section.
## If the key doesn't exist, returns [param default].
func get_value(user_id: StringName, key: StringName, default: Variant = null) -> Variant:
	return _config.get_value(user_id, key, default)


## Sets [param value] for [param key] in [param user_id]'s section and persists to disk.
## Reloads from disk before writing to merge with concurrent writes from other instances.
func set_value(user_id: StringName, key: StringName, value: Variant) -> void:
	_config.load(FILE_PATH)
	_config.set_value(user_id, key, value)
	_config.save(FILE_PATH)
