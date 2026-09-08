@abstract
class_name CapUiAttachmentsRegistry
extends GdlrCapability

const GameUiTypes = preload("../types.gd")


@abstract func register_attachment(attachment: GameUiTypes.UiAttachment) -> void
@abstract func unregister_attachment(attachment: GameUiTypes.UiAttachment) -> void
@abstract func get_attachments() -> Array[GameUiTypes.UiAttachment]
