extends PanelContainer

signal slot_changed

@onready var label: Label = $Label

func set_symbol(text_value: String):
	label.text = text_value

func get_symbol() -> String:
	return label.text

func _get_drag_data(_at_position: Vector2):
	if label.text == "":
		return null
		
	var preview_label = Label.new()
	preview_label.text = label.text
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	preview_label.custom_minimum_size = Vector2(300, 40)
	
	var preview_control = Control.new()
	preview_control.add_child(preview_label)
	preview_label.position = -preview_label.size / 2
	set_drag_preview(preview_control)
	
	return {
		"from_slot": self,
		"text": label.text
	}

func _can_drop_data(_at_position: Vector2, data) -> bool:
	return data is Dictionary and data.has("text")

func _drop_data(_at_position: Vector2, data):
	var from_slot = data["from_slot"]
	var incoming_text = data["text"]
	
	var current_text = label.text
	label.text = incoming_text
	from_slot.label.text = current_text
	
	slot_changed.emit()
