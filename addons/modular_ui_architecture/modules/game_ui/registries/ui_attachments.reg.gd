extends CapUiAttachmentsRegistry


var _attachments: Dictionary[GameUiTypes.UiAttachment, bool] = {}


func register_attachment(attachment: GameUiTypes.UiAttachment) -> void:
	_attachments[attachment] = true


func unregister_attachment(attachment: GameUiTypes.UiAttachment) -> void:
	if not _attachments.has(attachment):
		push_error("Attachment is not registered")
		return
	
	_attachments.erase(attachment)


func get_attachments() -> Array[GameUiTypes.UiAttachment]:
	return _attachments.keys()
