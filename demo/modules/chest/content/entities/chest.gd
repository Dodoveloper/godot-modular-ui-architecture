extends Area2D
## A world entity that grants a fixed set of rewards once, showing one queued Attention Dialog
## popup per reward.


const Utils = preload("res://addons/modular_ui_architecture/shared/classes/utils.gd")
const PolicyStoreTypes = preload("res://addons/modular_ui_architecture/modules/policy_store/types.gd")
const AttentionDialog = preload("res://demo/shared/ui/attention_dialog/attention_dialog.gd")

const ATTENTION_DIALOG_PATH := "res://demo/modules/chest/content/ui/attention_dialog.tscn"

## Names of the items granted when this chest is opened, in display order.
@export var reward_names: PackedStringArray = []
## Amounts matching [member reward_names] by index. Missing entries default to [code]1[/code].
@export var reward_amounts: PackedInt32Array = []
## Icons matching [member reward_names] by index. Missing entries show no icon.
@export var reward_icons: Array[Texture2D] = []

var _is_opened := false
var _svc_popups: CapPopups
var _svc_policy_store: CapPolicyStore


func _enter_tree() -> void:
	await Utils.await_module_graph_started()
	
	_svc_popups = GdlrModuleManager.request(CapPopups, self)
	_svc_policy_store = GdlrModuleManager.request(CapPolicyStore, self)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _is_opened:
		return
	if not body.is_in_group(&"player"):
		return
	if not _svc_policy_store.is_allowed(PolicyStoreTypes.Category.OPEN_GAMEPLAY_POPUP_UI):
		return
	
	_is_opened = true
	_grant_rewards()
	queue_free()


func _grant_rewards() -> void:
	for i in reward_names.size():
		var config := AttentionDialog.Config.new()
		config.main_text = reward_names[i]
		config.amount = reward_amounts[i] if i < reward_amounts.size() else 1
		config.texture = reward_icons[i] if i < reward_icons.size() else null
		
		_svc_popups.open_popup_queued(
			ATTENTION_DIALOG_PATH, Color(0.0, 0.0, 0.0, 0.0),
			_configure_popup.bind(config)
		)


static func _configure_popup(popup: AttentionDialog, config: AttentionDialog.Config) -> void:
	popup.configure(config)
