extends TextureRect
class_name BookSlot

signal slot_changed

var current_item: String = ""

const BOOK_TEXTURES = {
	"book_blue": "res://assets/inventory/book_blue.svg",
	"book_white": "res://assets/inventory/book_white.svg",
	"book_orange": "res://assets/inventory/book_orange.svg"
}

func _ready():
	# กำหนดขนาดช่องหนังสือใหม่: กว้าง 58px, สูง 124px
	custom_minimum_size = Vector2(58, 124)
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_vertical = Control.SIZE_SHRINK_END
	_refresh_display()

func set_book(item_id: String):
	current_item = item_id
	_refresh_display()
	slot_changed.emit()

func _refresh_display():
	if current_item != "" and BOOK_TEXTURES.has(current_item):
		var path = BOOK_TEXTURES[current_item]
		if ResourceLoader.exists(path):
			texture = load(path)
			modulate = Color.WHITE
		else:
			texture = null
			modulate = Color.BLUE if current_item == "book_blue" else (Color.WHITE if current_item == "book_white" else Color.ORANGE)
	else:
		texture = null
		# ช่องว่างให้โปร่งใส สำหรับรับคลิกลากวาง
		modulate = Color(1, 1, 1, 0.02)

func _can_drop_data(_at_position: Vector2, data) -> bool:
	return data is Dictionary and data.has("item_id")

func _drop_data(_at_position: Vector2, data):
	var new_item = data["item_id"]
	
	if current_item != "":
		Inventory.collect(current_item, "return_" + str(Time.get_ticks_msec()))
		
	set_book(new_item)
	
	if data.get("is_source", false):
		Inventory.remove_item(new_item, 1)
	elif data.has("from_slot") and data["from_slot"] != self:
		data["from_slot"].set_book("")

func _get_drag_data(_at_position: Vector2):
	if current_item == "":
		return null
		
	var preview = TextureRect.new()
	preview.texture = texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_SCALE
	preview.custom_minimum_size = Vector2(58, 124)
	preview.position = -preview.custom_minimum_size / 2
	
	var preview_root = Control.new()
	preview_root.add_child(preview)
	set_drag_preview(preview_root)
	
	return {
		"item_id": current_item,
		"from_slot": self,
		"is_source": false
	}

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if current_item != "":
			Inventory.collect(current_item, "return_" + str(Time.get_ticks_msec()))
			set_book("")
