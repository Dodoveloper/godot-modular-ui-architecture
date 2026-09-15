const PopupsModule = preload("res://addons/modular_ui_architecture/modules/popups/popups.md.gd")
const InputBindingsModule = preload("res://addons/modular_ui_architecture/modules/input_bindings/input_bindings.md.gd")
const GameUiModule = preload("res://addons/modular_ui_architecture/modules/game_ui/game_ui.md.gd")
const PolicyStoreModule = preload("res://addons/modular_ui_architecture/modules/policy_store/policy_store.md.gd")

const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const ToggleRenameBinding = preload("./bindings/toggle_rename.bind.gd")
const RenameButtonAttachment = preload("./attachments/rename_button.attach.gd")

const TOGGLE_RENAME_ACTION := &"toggle_rename"

static var IMPORTS := [
	PopupsModule,
	InputBindingsModule,
	GameUiModule,
	PolicyStoreModule,
]


class RenameModule extends GdlrModule:
	var reg_input_bindings: CapInputBindingsRegistry
	var reg_attachments: CapUiAttachmentsRegistry
	var svc_popups: CapPopups
	var svc_input_bindings: CapInputBindings
	var svc_policy_store: CapPolicyStore


	func register() -> void:
		_register_bindings()
		_register_attachments()


	func _register_bindings() -> void:
		var toggle_rename_binding := ToggleRenameBinding.new(
			svc_popups, svc_policy_store, UiLayersTypes.UiLayer.WINDOW
		)
		reg_input_bindings.register_binding(TOGGLE_RENAME_ACTION, toggle_rename_binding)


	func _register_attachments() -> void:
		var button_attachment := RenameButtonAttachment.new(svc_input_bindings)
		reg_attachments.register_attachment(button_attachment)
