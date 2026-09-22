extends RefCounted


static var _block_count: int = 0


static func block() -> void:
	_block_count += 1


static func unblock() -> void:
	if _block_count == 0:
		push_error("Trying to unblock inputs, but counter is 0")
		return
	
	_block_count -= 1


static func is_blocked() -> bool:
	return _block_count > 0
