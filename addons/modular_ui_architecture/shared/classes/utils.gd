@tool
extends RefCounted


## Cache of enum reverse mappings for [method enum_to_str].
static var _cached_enums: Dictionary[Dictionary, Dictionary] = {}


## Returns the string key of an enum value.
static func enum_to_str(e: Dictionary, value: int) -> String:
	if not _cached_enums.has(e):
		_cached_enums[e] = {}
		for key in e.keys():
			_cached_enums[e][e[key]] = key
	
	var reverse_mapping := _cached_enums[e]
	if reverse_mapping.has(value):
		return reverse_mapping[value]
	
	push_error("Couldn't find enum value %s in %s" % [value, e])
	return "UNKNOWN"


## Returns the script for [param Scene] for the node at index [param node_idx],
## [code]null[/code] otherwise.
static func get_scene_node_script(Scene: PackedScene, node_idx := 0) -> GDScript:
	if Scene == null:
		return null
	
	var state := Scene.get_state()
	for i in state.get_node_property_count(node_idx):
		if state.get_node_property_name(node_idx, i) == &"script":
			var script = state.get_node_property_value(node_idx, i)
			if script is GDScript:
				return script
	
	# The node may come from an inherited/instanced scene.
	var instance := state.get_node_instance(node_idx)
	if instance:
		return get_scene_node_script(instance, 0)
	
	return null


## Returns [code]true[/code] if the given PackedScene's root script inherits from the specified
## [b]custom[/b] script type.
static func is_scene_of_type(Scene: PackedScene, Type: GDScript) -> bool:
	var script := get_scene_node_script(Scene)
	return script != null and static_is_type(script, Type)


## Returns [code]true[/code] if the given PackedScene's root node inherits from the specified
## [b]native[/b] class.
static func is_scene_of_native_type(Scene: PackedScene, native_class: StringName) -> bool:
	var root_type := Scene.get_state().get_node_type(0)
	if root_type.is_empty():
		# Root is an inherited/instanced scene node, resolve type from parent scene
		var parent_scene := Scene.get_state().get_node_instance(0)
		if parent_scene:
			return is_scene_of_native_type(parent_scene, native_class)
		return false
	
	return ClassDB.is_parent_class(root_type, native_class)


static func static_is_type(script: GDScript, type: GDScript) -> bool:
	while script:
		if script == type:
			return true
		script = script.get_base_script()
	
	return false
