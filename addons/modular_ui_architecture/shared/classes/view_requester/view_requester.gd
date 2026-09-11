@tool
extends Node
## Requests a View to be mounted.
##
## This object is meant to be attached as a helper component.
## It is used to declaratively compose scenes that require specific Views without embedding
## view logic directly in the parent node.


const UiLayersTypes = preload("../../../modules/ui_layers/types.gd")
const Utils = preload("../utils.gd")

signal view_mounted(view: Node)

enum MountMode {
	## The View will be mounted on this node owner's [signal ready].
	ON_READY,
	## The View will be mounted manually.
	MANUAL,
}

enum UnmountMode {
	## The View will be unmounted manually.
	MANUAL,
	## The View will be unmounted on this node owner's [signal tree_exited].
	ON_EXIT_TREE,
}

## Token of the View.
@export var token := &"":
	set(value):
		token = value
		update_configuration_warnings()
## Layer the View should be spawned on.
@export var layer := UiLayersTypes.UiLayer.DEFAULT:
	set(value):
		layer = value
		update_configuration_warnings()
## How the View should be mounted.
@export var mount_mode := MountMode.ON_READY
## How the View should be unmounted.
@export var unmount_mode := UnmountMode.MANUAL

## Instance of the requested view.
var view_instance: Node

var _svc_game_ui: CapGameUi


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return
	
	if not token:
		assert(false, "Token not specified")
		return
	if layer == null:
		assert(false, "Layer not specified")
		return
	
	# NOTE: Godular currently doesn't expose a way of knowing when the graph is started,
	# so we resort to this ugliness for now.
	if not GdlrModuleManager._graph_started:
		await GdlrModuleManager.graph_started
	
	_svc_game_ui = GdlrModuleManager.request(CapGameUi, self)
	if mount_mode == MountMode.ON_READY:
		owner.ready.connect(_on_owner_ready)


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	
	if unmount_mode == UnmountMode.ON_EXIT_TREE:
		unmount_view()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not token:
		warnings.append("Token must be specified")
	if layer == null:
		warnings.append("Layer must be specified")
	
	return warnings


func mount_view() -> Node:
	var existing_view := _svc_game_ui.get_view(token)
	# If view is already mounted, return it
	if existing_view:
		view_instance = existing_view
		return existing_view
	
	view_instance = _svc_game_ui.mount_view(token, layer)
	if view_instance:
		print("View %s mounted" % token)
		view_mounted.emit(view_instance)
	else:
		push_warning(
			"View %s could not mount on layer %s"
			% [token, Utils.enum_to_str(UiLayersTypes.UiLayer, layer)]
		)
	
	return view_instance


func unmount_view() -> void:
	if not view_instance:
		return
	
	_svc_game_ui.unmount_view(token)
	view_instance = null


func _on_owner_ready() -> void:
	mount_view()
