const GameUiModule = preload("res://addons/modular_ui_architecture/modules/game_ui/game_ui.md.gd")
const InputBindingsModule = preload("res://addons/modular_ui_architecture/modules/input_bindings/input_bindings.md.gd")
const TooltipsModule = preload("res://addons/modular_ui_architecture/modules/tooltips/tooltips.md.gd")
const PolicyStoreModule = preload("res://addons/modular_ui_architecture/modules/policy_store/policy_store.md.gd")

const UiLayersTypes = preload("res://addons/modular_ui_architecture/modules/ui_layers/types.gd")
const GameUiTypes = preload("res://addons/modular_ui_architecture/modules/game_ui/types.gd")
const PolicyStoreTypes = preload("res://addons/modular_ui_architecture/modules/policy_store/types.gd")
const ToggleInventoryBinding = preload("./bindings/toggle_inventory.bind.gd")
const InventoryButtonAttachment = preload("./attachments/inventory_button.attach.gd")
const Inventory = preload("./content/ui/inventory.gd")

const INVENTORY_PATH := "res://demo/modules/inventory/content/ui/inventory.tscn"
const TOGGLE_INVENTORY_ACTION := &"toggle_inventory"

static var IMPORTS := [
	GameUiModule,
	InputBindingsModule,
	TooltipsModule,
	PolicyStoreModule,
]


class InventoryModule extends GdlrModule:
	var reg_input_bindings: CapInputBindingsRegistry
	var reg_views: CapViewsRegistry
	var reg_attachments: CapUiAttachmentsRegistry
	var svc_game_ui: CapGameUi
	var svc_input_bindings: CapInputBindings
	var svc_policy_store: CapPolicyStore
	
	
	func register() -> void:
		_register_bindings()
		_register_views()
		_register_attachments()
	
	
	func _register_bindings() -> void:
		var toggle_inventory_binding := ToggleInventoryBinding.new(
			svc_game_ui, UiLayersTypes.UiLayer.WINDOW
		)
		reg_input_bindings.register_binding(TOGGLE_INVENTORY_ACTION, toggle_inventory_binding)
	
	
	func _register_views() -> void:
		var inventory_registration := GameUiTypes.ViewRegistration.new(
			Tokens.Scenes.Views.INVENTORY_TOKEN,
			INVENTORY_PATH,
		)
		reg_views.register_view(inventory_registration)
		
		svc_game_ui.view_mounted.connect(_on_game_ui_view_mounted)
	
	
	func _register_attachments() -> void:
		var button_attachment := InventoryButtonAttachment.new(svc_input_bindings)
		reg_attachments.register_attachment(button_attachment)
	
	
	func _on_game_ui_view_mounted(token: StringName) -> void:
		if token != Tokens.Scenes.Views.INVENTORY_TOKEN:
			return
		
		var inventory: Inventory = svc_game_ui.get_view(token)
		svc_policy_store.block(PolicyStoreTypes.Category.OPEN_POPUP_UI, inventory)
		inventory.close_requested.connect(_on_inventory_close_requested.bind(token))
		inventory.tree_exiting.connect(_on_inventory_tree_exiting.bind(inventory))
	
	
	func _on_inventory_close_requested(token: StringName) -> void:
		svc_game_ui.unmount_view(token)
	
	
	func _on_inventory_tree_exiting(inventory: Inventory) -> void:
		svc_policy_store.unblock(PolicyStoreTypes.Category.OPEN_POPUP_UI, inventory)
