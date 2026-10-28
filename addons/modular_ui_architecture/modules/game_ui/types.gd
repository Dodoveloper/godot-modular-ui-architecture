## Describes a piece of UI that can be mounted on a higher-level piece of UI.
class UiAttachment extends RefCounted:
	## Tag identifying the slot where the UI should be mounted.
	var _slot_tag: StringName
	## Determines mount order within a slot. Higher values mount earlier (closer to index 0).
	## Attachments with equal priority use registration order.
	var _priority := 0
	## The scene to be mounted if no build function is provided.
	var _Scene: PackedScene
	## Instance of the scene mounted.
	var _instance: Control
	
	
	## [param slot_tag] - The slot tag where the UI should be mounted.[br]
	## [param Scene] - The scene to be mounted.[br]
	func _init(slot_tag: StringName, Scene: PackedScene = null) -> void:
		_slot_tag = slot_tag
		_Scene = Scene
	
	
	## Destructor. Runs when the attachment is about to be freed.[br]
	## Only data is touched here: at this point Godot has already detached the script instance, so
	## calling any script method fails with "base 'null instance'". Freeing [member _instance]
	## directly is safe.
	func _notification(what: int) -> void:
		match what:
			NOTIFICATION_PREDELETE:
				if is_instance_valid(_instance):
					_instance.free()
				_instance = null
	
	
	@warning_ignore("unused_parameter")
	## Virtual method. Triggered when the host UI's context has changed.
	func _on_context_changed(new_context: RefCounted) -> void:
		pass
	
	
	## Virtual method. Triggered when the UI instance is built, i.e. after [method _build]
	## has executed.
	func _on_instance_built() -> void:
		pass
	
	
	## Virtual method. Triggered when the UI instance emits its [signal Node.tree_exiting] signal.
	func _on_instance_tree_exiting() -> void:
		pass


	## Triggered when the host UI's context has changed.[br]
	## [br]
	## [param new_context] - The new, updated context.
	func notify_context_changed(new_context: RefCounted) -> void:
		_on_context_changed(new_context)
	
	
	func get_slot_tag() -> StringName:
		return _slot_tag
	
	
	func get_priority() -> int:
		return _priority
	
	
	func get_instance() -> Control:
		return _instance
	
	
	## Frees an instance that was built but never placed in the tree, and clears the reference.[br]
	## Runs [method _on_instance_tree_exiting] first, since [signal Node.tree_exiting] never fires for
	## an instance that was never in the tree. Use this instead of freeing the instance directly.
	func discard_instance() -> void:
		if is_instance_valid(_instance) and not _instance.is_inside_tree():
			_on_instance_tree_exiting()
		if is_instance_valid(_instance):
			_instance.queue_free()
		_instance = null
	
	
	## Determines if the UI should be mounted or not.[br]
	## [br]
	## [param host_ui] - The UI view that the UI will be mounted on.[br]
	## [param context] - Context data.[br]
	## Returns [code]true[/code] if the node can be mounted.
	func should_mount(host_ui: Node, context: RefCounted) -> bool:
		return _should_mount(host_ui, context)
	
	
	## Builds the UI instance.[br]
	## [br]
	## [param host_ui] - The UI view that the UI will be mounted on.[br]
	## [param context] - Context data.[br]
	## Returns the instance of the built [Control] node.
	func build(host_ui: Node, context: RefCounted) -> Control:
		_instance = _build(host_ui, context)
		if not _instance:
			return null
		_on_instance_built()
		_instance.tree_exiting.connect(_on_instance_tree_exiting, CONNECT_ONE_SHOT)
		_instance.tree_exited.connect(_on_instance_tree_exited, CONNECT_ONE_SHOT)
		
		return _instance
	
	
	func _build(_host_ui: Node, _context: RefCounted) -> Control:
		if not _Scene:
			assert(false, "No scene provided")
			return null
		
		return _Scene.instantiate()
	
	
	func _should_mount(_host_ui: Node, _context: RefCounted) -> bool:
		return true
	
	
	func _on_instance_tree_exited() -> void:
		_instance = null


## Describes a UI View which can be registered.
class ViewRegistration extends RefCounted:
	## The token identifying the view.
	var token: StringName
	## Scene path for the view.
	var scene: String
	
	
	func _init(token_: StringName, scene_: String) -> void:
		token = token_
		scene = scene_
