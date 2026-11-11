@abstract
class_name CapUiLayersRegistry
extends GdlrCapability


const UiLayersTypes = preload("../types.gd")


## Registers a UI layer, so [CapUiLayers] creates a node for it when the layers are enabled.[br]
## [br]
## Layers can only be registered before the layers are created, which is during
## [method GdlrModule.register]. Registering later pushes an error. So does a duplicate token, an
## empty token, a script that doesn't extend [UiLayerNode], or an order already used by another
## layer.[br]
## [br]
## [param registration] - Description of the layer.
@abstract func register_layer(registration: UiLayersTypes.UiLayerRegistration) -> void
## Returns the registered layers, sorted by ascending order. The first entry is drawn lowest.
@abstract func get_layer_registrations() -> Array[UiLayersTypes.UiLayerRegistration]
## Stops accepting registrations. [CapUiLayers] should call this when it creates the layer nodes.
@abstract func seal() -> void
