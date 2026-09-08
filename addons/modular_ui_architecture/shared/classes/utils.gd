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
