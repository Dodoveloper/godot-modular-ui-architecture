extends UiLayerNode
## The layer that DEFAULT-layer UI mounts into, the fallback for Views that don't pick a layer.[br]
## [br]
## It has no custom behaviour yet. Its own script lets addon users customize this layer (for
## example, restricting what it accepts in [method UiLayerNode._can_mount_scene]) without affecting
## other layers. The [code]DEFAULT[/code] entry in [code]UiLayersService[/code] points here.
