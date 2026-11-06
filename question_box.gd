extends CanvasLayer

signal question_answered(correct: bool)
signal question_closed

@onready var question_label: Label = $Panel/VBoxContainer/QuestionLabel
@onready var question_image: TextureRect = $Panel/VBoxContainer/QuestionImage
@onready var feedback_label: Label = $Panel/VBoxContainer/FeedbackLabel

# กลุ่มตัวเลือก (Multiple Choice)
@onready var choices_container: VBoxContainer = $Panel/VBoxContainer/ChoicesContainer
@onready var choice_buttons = [
	$Panel/VBoxContainer/ChoicesContainer/Choice1,
	$Panel/VBoxContainer/ChoicesContainer/Choice2,
	$Panel/VBoxContainer/ChoicesContainer/Choice3,
	$Panel/VBoxContainer/ChoicesContainer/Choice4,
	$Panel/VBoxContainer/ChoicesContainer/Choice5
]

# กลุ่มช่องกรอก (Input)
@onready var input_container: VBoxContainer = $Panel/VBoxContainer/InputContainer
@onready var single_input: LineEdit = $Panel/VBoxContainer/InputContainer/AnswerInput
@onready var double_input_container: HBoxContainer = $Panel/VBoxContainer/InputContainer/DoubleInputContainer
@onready var input_a: LineEdit = $Panel/VBoxContainer/InputContainer/DoubleInputContainer/AnswerInputA
@onready var input_b: LineEdit = $Panel/VBoxContainer/InputContainer/DoubleInputContainer/AnswerInputB

# กลุ่มช่องกรอก 4 ช่อง (Quad Input - ข้อ 3.1)
@onready var quad_input_container: GridContainer = $Panel/VBoxContainer/InputContainer/QuadInputContainer
@onready var label_1: Label = $Panel/VBoxContainer/InputContainer/QuadInputContainer/Label1
@onready var input_1: LineEdit = $Panel/VBoxContainer/InputContainer/QuadInputContainer/AnswerInput1
@onready var label_2: Label = $Panel/VBoxContainer/InputContainer/QuadInputContainer/Label2
@onready var input_2: LineEdit = $Panel/VBoxContainer/InputContainer/QuadInputContainer/AnswerInput2
@onready var label_3: Label = $Panel/VBoxContainer/InputContainer/QuadInputContainer/Label3
@onready var input_3: LineEdit = $Panel/VBoxContainer/InputContainer/QuadInputContainer/AnswerInput3
@onready var label_4: Label = $Panel/VBoxContainer/InputContainer/QuadInputContainer/Label4
@onready var input_4: LineEdit = $Panel/VBoxContainer/InputContainer/QuadInputContainer/AnswerInput4

@onready var submit_button: Button = $Panel/VBoxContainer/InputContainer/SubmitButton

var current_question_data = {}
var current_question_id: String = ""
var questions_list: Array = []
var current_question_index: int = 0

func _ready():
	# Create the close button
	var close_button = Button.new()

	close_button.name = "CloseButton"
	close_button.text = "×"
	close_button.tooltip_text = "Close (ESC)"

	close_button.custom_minimum_size = Vector2(35, 35)
	close_button.focus_mode = Control.FOCUS_NONE

	# Position at the top-right corner of the panel
	close_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)

	close_button.offset_left = -43
	close_button.offset_top = 8
	close_button.offset_right = -8
	close_button.offset_bottom = 43

	# Connect button
	close_button.pressed.connect(close_question)

	$Panel.add_child(close_button)
	
	# ผูกการคลิกช้อยส์
	for btn in choice_buttons:
		btn.pressed.connect(func(): _on_choice_selected(btn.text if btn.text != "" else (btn.icon.resource_path if btn.icon else "")))
	
	# ผูกปุ่มกดยืนยัน
	submit_button.pressed.connect(_on_submit_input)
	single_input.text_submitted.connect(func(_t): _on_submit_input())
	
	# กด Enter ข้ามช่องสำหรับ Double Input (A -> B -> ส่งคำตอบ)
	input_a.text_submitted.connect(func(_t): input_b.grab_focus())
	input_b.text_submitted.connect(func(_t): _on_submit_input())
	
	# กด Enter ข้ามช่องสำหรับ Quad Input (1 -> 2 -> 3 -> 4 -> ส่งคำตอบ)
	input_1.text_submitted.connect(func(_t): input_2.grab_focus())
	input_2.text_submitted.connect(func(_t): input_3.grab_focus())
	input_3.text_submitted.connect(func(_t): input_4.grab_focus())
	input_4.text_submitted.connect(func(_t): _on_submit_input())
	
	load_questions_from_json()
	
func _unhandled_key_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				close_question()
				get_viewport().set_input_as_handled()

func open_question(data: Dictionary) -> void:
	current_question_index = 0
	display_question(data)

func load_questions_from_json():
	var file_path = "res://data/questions.json"
	if not FileAccess.file_exists(file_path):
		push_error("ไม่พบไฟล์: " + file_path)
		return
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	
	if parsed and parsed.has("questions"):
		questions_list = parsed["questions"]
		print("โหลดสำเร็จ: ", questions_list.size(), " ข้อ")

func load_question_by_id(target_id: String):
	for q in questions_list:
		if q.get("id") == target_id:
			display_question(q)
			return
	push_warning("ไม่พบคำถาม ID: " + target_id)

func display_question(data: Dictionary):
	current_question_data = data
	current_question_id = data.get("id", "")
	feedback_label.text = ""
	question_label.text = data.get("question", "")
	
	# 1. จัดการรูปภาพประกอบโจทย์
	var img_path = data.get("image_path", "")
	if img_path != "" and ResourceLoader.exists(img_path):
		question_image.texture = load(img_path)
		question_image.visible = true
		question_image.custom_minimum_size = Vector2(0, 150)
	else:
		question_image.texture = null
		question_image.visible = false
	
	var q_type = data.get("type", "multiple_choice")
	
	# 2. กรณีช่องกรอก 4 ช่อง (ข้อ 3.1 XOR)
	if q_type == "text_input_quad":
		choices_container.visible = false
		input_container.visible = true
		single_input.visible = false
		double_input_container.visible = false
		quad_input_container.visible = true
		
		# กำหนด Label ข้อความ XOR ในโค้ดโดยตรง
		label_1.text = "0 XOR 0 = "
		label_2.text = "0 XOR 1 = "
		label_3.text = "1 XOR 0 = "
		label_4.text = "1 XOR 1 = "
		
		# ล้างค่าช่องพิมพ์และเปิดให้แก้ไข
		for inp in [input_1, input_2, input_3, input_4]:
			inp.text = ""
			inp.editable = true
			inp.placeholder_text = "0 หรือ 1"
			
		submit_button.disabled = false
		input_1.grab_focus()
		
	# 3. กรณีช่องกรอกคู่ (ข้อ 5.2)
	elif q_type == "text_input_double":
		choices_container.visible = false
		input_container.visible = true
		single_input.visible = false
		double_input_container.visible = true
		quad_input_container.visible = false
		
		input_a.text = ""
		input_b.text = ""
		input_a.placeholder_text = "A ="
		input_b.placeholder_text = "B ="
		
		input_a.editable = true
		input_b.editable = true
		submit_button.disabled = false
		input_a.grab_focus()
		
	# 4. กรณีช่องกรอกเดี่ยว (ข้อ 5.1)
	elif q_type == "text_input":
		choices_container.visible = false
		input_container.visible = true
		single_input.visible = true
		double_input_container.visible = false
		quad_input_container.visible = false
		
		single_input.text = ""
		single_input.editable = true
		submit_button.disabled = false
		single_input.grab_focus()
		
	# 5. กรณีตัวเลือก (Multiple Choice)
	else:
		input_container.visible = false
		choices_container.visible = true
		var choices = data.get("choices", [])
		for i in range(choice_buttons.size()):
			var btn = choice_buttons[i]
			if i < choices.size():
				btn.visible = true
				btn.disabled = false
				var choice_val: String = choices[i]
				
				if choice_val.begins_with("res://") and ResourceLoader.exists(choice_val):
					btn.icon = load(choice_val)
					btn.text = ""
					btn.custom_minimum_size = Vector2(0, 70)
				else:
					btn.icon = null
					btn.text = choice_val
					btn.custom_minimum_size = Vector2(0, 35)
			else:
				btn.visible = false
				
	show()

func _on_choice_selected(selected_value: String):
	for btn in choice_buttons:
		btn.disabled = true
	var correct_val = str(current_question_data.get("correct_answer", ""))
	_finish_answering(selected_value.strip_edges() == correct_val.strip_edges())

func _on_submit_input():
	var q_type = current_question_data.get("type", "")
	var correct_val = str(current_question_data.get("correct_answer", ""))
	var is_correct = false
	
	if q_type == "text_input_quad":
		var u1 = input_1.text.strip_edges()
		var u2 = input_2.text.strip_edges()
		var u3 = input_3.text.strip_edges()
		var u4 = input_4.text.strip_edges()
		
		# เฉลยรูปแบบ "0, 1, 1, 0"
		var parts = correct_val.split(",")
		if parts.size() >= 4:
			is_correct = (
				u1 == parts[0].strip_edges() and
				u2 == parts[1].strip_edges() and
				u3 == parts[2].strip_edges() and
				u4 == parts[3].strip_edges()
			)
			
		for inp in [input_1, input_2, input_3, input_4]:
			inp.editable = false
			
	elif q_type == "text_input_double":
		var val_a = input_a.text.strip_edges().replace(" ", "").to_lower()
		var val_b = input_b.text.strip_edges().replace(" ", "").to_lower()
		
		var parts = correct_val.split(",")
		if parts.size() >= 2:
			var ans_a = parts[0].strip_edges().replace(" ", "").to_lower()
			var ans_b = parts[1].strip_edges().replace(" ", "").to_lower()
			is_correct = (val_a == ans_a and val_b == ans_b)
			
		input_a.editable = false
		input_b.editable = false
	else:
		var user_text = single_input.text.strip_edges().to_lower()
		is_correct = (user_text == correct_val.strip_edges().to_lower())
		single_input.editable = false
		
	submit_button.disabled = true
	_finish_answering(is_correct)

func _finish_answering(is_correct: bool):

	if is_correct:
		feedback_label.text = "✓ correct!"
		feedback_label.modulate = Color.GREEN
	else:
		feedback_label.text = "✗ wrong!"
		feedback_label.modulate = Color.RED

	question_answered.emit(is_correct)

	await get_tree().create_timer(1.2).timeout

	hide()
	question_closed.emit()

func close_question() -> void:
	if not visible:
		return
	hide()
	question_closed.emit()
