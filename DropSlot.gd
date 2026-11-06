# DropSlot.gd
extends PanelContainer
class_name DropSlot

signal slot_changed

@onready var label: Label = $Label

func set_symbol(symbol: String):
	label.text = symbol

func get_symbol() -> String:
	return label.text

# 1. เมื่อเริ่มลากเมาส์ออกจากช่องนี้
func _get_drag_data(_at_position: Vector2):
	if label.text == "":
		return null
		
	# สร้างภาพพรีวิวจำลองตอนกำลังลากตามเคอร์เซอร์เมาส์
	var preview_label = Label.new()
	preview_label.text = label.text
	preview_label.add_theme_font_size_override("font_size", 36)
	
	var preview_control = Control.new()
	preview_control.add_child(preview_label)
	preview_label.position = -preview_label.size / 2
	set_drag_preview(preview_control)
	
	# ส่งข้อมูลว่าช่องนี้กำลังลากตัวอะไร และมาจากโหนดไหน
	return {
		"from_slot": self,
		"symbol": label.text
	}

# 2. ตรวจสอบว่าช่องนี้ยอมให้วางไหม
func _can_drop_data(_at_position: Vector2, data) -> bool:
	return data is Dictionary and data.has("symbol")

# 3. เมื่อปล่อยเมาส์ลงในช่องนี้
func _drop_data(_at_position: Vector2, data):
	var from_slot = data["from_slot"]
	var incoming_symbol = data["symbol"]
	
	# สลับสัญลักษณ์ระหว่างช่องต้นทางกับช่องปลายทาง (Swap)
	var current_symbol = label.text
	label.text = incoming_symbol
	from_slot.label.text = current_symbol
	
	slot_changed.emit()
