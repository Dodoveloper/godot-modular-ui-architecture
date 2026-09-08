@tool
extends RefCounted
## Caches loaded PackedScenes by path to avoid re-parsing from disk on repeated mount/unmount.


static var _scenes_by_path: Dictionary[String, PackedScene] = {}


## Loads the [PackedScene] under [param path], otherwise it returns [code]null[/code].
static func load_scene(path: String) -> PackedScene:
	if Engine.is_editor_hint():
		return _validate_scene(load(path), path)
	
	if _scenes_by_path.has(path):
		return _scenes_by_path[path]
	
	var scene := _validate_scene(load(path), path)
	if scene:
		_scenes_by_path[path] = scene
	return scene


static func clear_cache() -> void:
	_scenes_by_path.clear()


static func evict(path: String) -> void:
	_scenes_by_path.erase(path)


## Returns [param resource] cast to [PackedScene] if valid, [code]null[/code] otherwise.
static func _validate_scene(resource: Resource, path: String) -> PackedScene:
	if resource == null:
		push_error("SceneCache: failed to load resource at path '%s'" % path)
		return null
	if resource is not PackedScene:
		push_error(
			"SceneCache: resource at path '%s' is not a PackedScene (got %s)"
			% [path, resource.get_class()]
		)
		return null
	
	return resource
