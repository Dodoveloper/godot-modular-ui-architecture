extends UiLayerNode
## The layer that HUD Views mount into.[br]
## [br]
## It accepts a single direct child. The HUD is one View, and a HUD View holds its own widgets
## (health bar, minimap, hotbar...) internally. Mounting a second View here is refused, and
## [method UiLayerNode.mount_node] returns [code]null[/code].[br]
## [br]
## Its behaviour is currently identical to the window layer (see [code]window_ui_layer.gd[/code]).
## It has its own script so you can change how the HUD layer handles its UI (for example, allowing
## several children or adding HUD-specific mounting logic) without changing the window layer.


func _can_mount_scene(_Scene: PackedScene) -> bool:
	return get_mounted_nodes().is_empty()
