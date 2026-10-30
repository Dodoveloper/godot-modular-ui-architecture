extends UiLayerNode
## The layer that Overlays mount into, drawn above windows and blocking the layers below it.[br]
## [br]
## It has no custom behaviour yet. Its own script lets addon users customize this layer (for
## example, restricting what it accepts in [method UiLayerNode._can_mount_scene]) without affecting
## other layers. The [code]OVERLAY[/code] entry in [code]UiLayersService[/code] points here.
