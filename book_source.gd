extends TextureRect
class_name BookSource

@export_enum("book_blue", "book_white", "book_orange") var item_id: String = "book_blue"

var count_label: Label

func _ready():
	# สร้าง Label นับจำนวนเล่มติดไว้ที่มุมรูป
	count_label = Label.new()
	count_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	count_label.offset_left = -30
	count_label.offset_top = -25
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(count_label)
	
	custom_minimum_size = Vector2(50, 70)
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	if Inventory != null:
		Inventory.changed.connect(update_count)
	update_count()

func update_count():
	if Inventory == null:
		return
	var count = Inventory.get_count(item_id)
	count_label.text = "x%d" % count
	# ถ้าของหมดให้กองหนังสือจางลง
	modulate = Color.WHITE if count > 0 else Color(1, 1, 1, 0.3)

func _get_drag_data(_at_position: Vector2):
	var count = Inventory.get_count(item_id)
	if count <= 0:
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
		"item_id": item_id,
		"is_source": true
	}
