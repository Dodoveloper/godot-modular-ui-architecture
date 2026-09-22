@tool
extends Node
## Mounts game-world UI into the modular layer system.
##
## This node is specifically for UI that floats in game-world space and tracks a game-world anchor
## (e.g., nameplates, healthbars, world labels). It is [b]not[/b] a general-purpose local UI mounter.
## [br]
## [b]Usage:[/b] place this node in the same scene as the UI you want to mount (e.g., as a sibling
## of the Pivot in a nameplate) and set it up. The portal will handle the rest at runtime.


const UiLayersTypes = preload("../../../modules/ui_layers/types.gd")
const Utils = preload("../utils.gd")

enum AnchorMode {
	## The UI is reparented into the target layer as-is, with no position tracking.
	NONE,
	## The UI is reparented into the target layer and its position is synced to a game-world node
	## per physics frame.
	WORLD_FOLLOW,
}

## The node (relative to this portal) to reparent into the target layer.
@export var target_ui: Control:
	set(value):
		target_ui = value
		update_configuration_warnings()
## Target UI layer. For most cases, it's recommended to use [enum UiLayersTypes.UiLayer.DEFAULT].
@export var target_layer := UiLayersTypes.UiLayer.DEFAULT
## Determines how the position of [member target_ui] will be updated.
@export var anchor_mode := AnchorMode.NONE:
	set(value):
		anchor_mode = value
		notify_property_list_changed()
## World-space Node2D to follow ([enum AnchorMode.WORLD_FOLLOW] only).[br]
## Leave empty to auto-resolve: uses [member Node.owner] if it is a Node2D, otherwise uses
## [method Node.get_parent] of owner. This allows the portal to be placed inside a UI scene
## (e.g., inside a nameplate scene) and automatically follow the owner's parent at runtime
## (e.g., the entity that owns the nameplate).
@export var world_anchor: Node2D
## When [enum AnchorMode.WORLD_FOLLOW], mirrors [member world_anchor]'s [code]visible[/code],
## [code]modulate[/code], and [code]scale[/code] onto [member target_ui] every frame.[br]
## [br]
## Use this when the owning scene authors visibility/animation (e.g. via toggle actions or an
## [AnimationPlayer]) on the anchor node, expecting it to also affect [member target_ui] as if it
## were still a child (which it no longer is once mounted). [member target_ui]'s own authored
## [code]scale[/code] is preserved as a baseline and composed multiplicatively with the anchor's.
@export var mirror_anchor_visuals := false

var _svc_game_ui: CapGameUi

var _managed_ui: Control


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return
	
	await Utils.await_module_graph_started()
	
	_svc_game_ui = GdlrModuleManager.request(CapGameUi, self)


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	
	if is_instance_valid(_managed_ui):
		_svc_game_ui.unmount_world_ui(_managed_ui)
	_managed_ui = null


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	# Defer mounting so that we're sure the target UI node is ready.
	_mount.call_deferred()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not target_ui:
		warnings.append("Target Ui should be set")
	
	return warnings


func _validate_property(property: Dictionary) -> void:
	match property.name:
		"world_anchor", "mirror_anchor_visuals":
			if anchor_mode == AnchorMode.NONE:
				property.usage = PROPERTY_USAGE_NO_EDITOR


## Returns the mounted UI, mounting it immediately if it hasn't happened yet.[br]
## [br]
## Mounting is normally deferred until after [method Node._ready] so the target UI's
## [code]@onready[/code] state has settled before it's reparented.
## Callers that need the mounted UI earlier than that can call this safely.
func get_managed_ui() -> Control:
	if not is_instance_valid(_managed_ui):
		_mount()
	return _managed_ui


func _mount() -> void:
	if is_instance_valid(_managed_ui):
		return
	if not is_inside_tree():
		return
	if not target_ui:
		push_error("target_ui is not set")
		return
	
	var anchor: Node2D
	if anchor_mode == AnchorMode.WORLD_FOLLOW:
		if world_anchor != null:
			anchor = world_anchor
		elif owner is Node2D:
			anchor = owner as Node2D
		else:
			anchor = owner.get_parent() as Node2D
		if not anchor:
			push_error("world_anchor not found or is not a Node2D")
			return
	
	var mounted_ui: Control
	match anchor_mode:
		AnchorMode.NONE:
			# Screen-space layout: no offset, the UI's anchors will re-resolve against the layer container.
			mounted_ui = _svc_game_ui.mount_world_ui(target_ui, null, target_layer, Vector2.ZERO)
		AnchorMode.WORLD_FOLLOW:
			# World-follow mode: offset from the anchor's world position.
			mounted_ui = _svc_game_ui.mount_world_ui(
				target_ui, anchor, target_layer, target_ui.position, mirror_anchor_visuals
			)
	
	if mounted_ui:
		_managed_ui = target_ui
