extends Node
## Shared inventory for the current run; survives changing floors.
signal changed
signal item_collected(item_id: String)

const ITEM_IDS = ["key_yellow", "key_blue", "key_purple", "key_gold", "book_blue", "book_white", "book_orange"]
const ITEM_NAMES = {
	"key_yellow": "Yellow key", "key_blue": "Blue key",
	"key_purple": "Purple key", "key_gold": "Gold key",
	"book_blue": "Blue book", "book_white": "White book", "book_orange": "Orange book"
}
var _counts: Dictionary = {}
var _collected_pickups: Dictionary = {}

func get_count(item_id: String) -> int:
	return int(_counts.get(item_id, 0))

func has_item(item_id: String, amount: int = 1) -> bool:
	return ITEM_NAMES.has(item_id) and amount > 0 and get_count(item_id) >= amount

func was_collected(pickup_id: String) -> bool:
	return _collected_pickups.has(pickup_id)

func collect(item_id: String, pickup_id: String) -> bool:
	if not ITEM_NAMES.has(item_id) or pickup_id.is_empty() or was_collected(pickup_id):
		return false
	_collected_pickups[pickup_id] = true
	_counts[item_id] = get_count(item_id) + 1
	changed.emit()
	item_collected.emit(item_id)
	return true

func remove_item(item_id: String, amount: int = 1) -> bool:
	if not has_item(item_id, amount):
		return false
	_counts[item_id] = get_count(item_id) - amount
	changed.emit()
	return true

func reset_inventory() -> void:
	_counts.clear()
	_collected_pickups.clear()
	changed.emit()
