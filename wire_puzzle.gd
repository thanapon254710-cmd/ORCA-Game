extends CanvasLayer

signal question_answered(correct: bool)

@onready var left_buttons = [
	$Panel/HBoxContainer/LeftContainer/LeftBtn0,
	$Panel/HBoxContainer/LeftContainer/LeftBtn1,
	$Panel/HBoxContainer/LeftContainer/LeftBtn2,
	$Panel/HBoxContainer/LeftContainer/LeftBtn3
]

@onready var right_buttons = [
	$Panel/HBoxContainer/RightContainer/RightBtn0,
	$Panel/HBoxContainer/RightContainer/RightBtn1,
	$Panel/HBoxContainer/RightContainer/RightBtn2,
	$Panel/HBoxContainer/RightContainer/RightBtn3
]

@onready var wires_layer: Control = $Panel/WiresLayer
@onready var feedback_label: Label = $Panel/FeedbackLabel
@onready var reset_button: Button = $Panel/ResetButton

# ชุดสีที่เป็นมิตรกับคนตาบอดสี (Okabe-Ito Palette) พร้อมสัญลักษณ์กำกับ
const COLOR_DATA = {
	"orange": {"color": Color("#E66101"), "symbol": ""},
	"yellow": {"color": Color("#F0E442"), "symbol": ""},
	"sky_blue": {"color": Color("#56B4E9"), "symbol": ""},
	"purple": {"color": Color("#5E3C99"), "symbol": ""}
}

var left_color_keys = ["orange", "yellow", "sky_blue", "purple"]
var right_color_keys = ["orange", "yellow", "sky_blue", "purple"]

var selected_left_index: int = -1
var connections = {}

func _ready():
	reset_button.pressed.connect(reset_puzzle)
	
	# สุ่มสลับตำแหน่งสีฝั่งขวา
	right_color_keys.shuffle()
	
	_setup_buttons()

func _setup_buttons():
	for i in range(4):
		var l_btn = left_buttons[i]
		var r_btn = right_buttons[i]
		
		var l_key = left_color_keys[i]
		var r_key = right_color_keys[i]
		
		# ล้าง modulate เดิมออกเพื่อไม่ให้สีกดทับ
		l_btn.modulate = Color.WHITE
		r_btn.modulate = Color.WHITE
		
		# ใส่สัญลักษณ์แทนชื่อสี (ถ้าไม่อยากให้มีสัญลักษณ์เลย ให้เปลี่ยนเป็น "")
		l_btn.text = COLOR_DATA[l_key]["symbol"]
		r_btn.text = COLOR_DATA[r_key]["symbol"]
		
		# ตั้งค่า StyleBox ให้สีปุ่มสดใส ไม่มืดหม่น
		_apply_button_color(l_btn, COLOR_DATA[l_key]["color"])
		_apply_button_color(r_btn, COLOR_DATA[r_key]["color"])
		
		l_btn.pressed.connect(func(): _on_left_button_clicked(i))
		r_btn.pressed.connect(func(): _on_right_button_clicked(i))

# ฟังก์ชันปรับแต่งพื้นหลังปุ่มให้แสดงสีสดใสตรงๆ
func _apply_button_color(btn: Button, col: Color):
	var style = StyleBoxFlat.new()
	style.bg_color = col
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_color_override("font_color", Color.BLACK if col.get_luminance() > 0.5 else Color.WHITE)
	btn.add_theme_font_size_override("font_size", 24)

func _on_left_button_clicked(index: int):
	selected_left_index = index
	feedback_label.text = "Selected wire. Now click matching slot on the right."
	feedback_label.modulate = Color.WHITE

func _on_right_button_clicked(right_idx: int):
	if selected_left_index == -1:
		feedback_label.text = "Click a left wire first!"
		feedback_label.modulate = Color.YELLOW
		return
		
	if connections.has(selected_left_index):
		connections[selected_left_index]["line"].queue_free()
		connections.erase(selected_left_index)
		
	var start_pos = left_buttons[selected_left_index].global_position + Vector2(left_buttons[selected_left_index].size.x, left_buttons[selected_left_index].size.y / 2)
	var end_pos = right_buttons[right_idx].global_position + Vector2(0, right_buttons[right_idx].size.y / 2)
	
	var line = Line2D.new()
	line.width = 10.0 # เพิ่มความหนาของเส้นสายไฟ
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.default_color = COLOR_DATA[left_color_keys[selected_left_index]]["color"]
	line.add_point(start_pos)
	line.add_point(end_pos)
	wires_layer.add_child(line)
	
	connections[selected_left_index] = {
		"right_index": right_idx,
		"line": line
	}
	
	selected_left_index = -1
	feedback_label.text = ""
	
	if connections.size() == 4:
		_check_wires()


func _check_wires():
	var all_correct = true

	for l_idx in connections.keys():
		var r_idx = connections[l_idx]["right_index"]
		if left_color_keys[l_idx] != right_color_keys[r_idx]:
			all_correct = false
			break

	if all_correct:
		feedback_label.text = "you got ☾ "
		feedback_label.modulate = Color.GREEN

		# Notify the fuse box
		question_answered.emit(true)

		# Notify GameState
		if GameState.has_signal("question_answered"):
			GameState.question_answered.emit("q_4_408", true)

		# Mark question as completed
		if not GameState.questions_answered.has("q_4_408"):
			GameState.questions_answered.append("q_4_408")

		# Wait before changing the room
		await get_tree().create_timer(1.5).timeout

		# Remove puzzle and change to the powered-on room
		queue_free()
		get_tree().change_scene_to_file.call_deferred(
			"res://scenes/room/room408เปิดไฟ.tscn"
		)

	else:
		feedback_label.text = "try again"
		feedback_label.modulate = Color.RED

		await get_tree().create_timer(1.0).timeout
		reset_puzzle()


func reset_puzzle():
	selected_left_index = -1
	for child in wires_layer.get_children():
		child.queue_free()
	connections.clear()
	feedback_label.text = ""
