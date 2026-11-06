extends CanvasLayer

signal question_answered(correct: bool)
var file_path = "res://data/questions.json"
@onready var question_label = $Panel/VBoxContainer/QuestionLabel
@onready var feedback_label = $Panel/VBoxContainer/FeedbackLabel

# ชุดตัวเลือก
@onready var choices_container = $Panel/VBoxContainer/ChoicesContainer
@onready var choice_buttons = [
	$Panel/VBoxContainer/ChoicesContainer/Choice1,
	$Panel/VBoxContainer/ChoicesContainer/Choice2,
	$Panel/VBoxContainer/ChoicesContainer/Choice3,
	$Panel/VBoxContainer/ChoicesContainer/Choice4,
	$Panel/VBoxContainer/ChoicesContainer/Choice5
]

# ชุดเติมคำ
@onready var input_container = $Panel/VBoxContainer/InputContainer
@onready var answer_input = $Panel/VBoxContainer/InputContainer/AnswerInput
@onready var submit_button = $Panel/VBoxContainer/InputContainer/SubmitButton

var current_question_data = {}
var current_question_id: String = ""
var questions_list: Array = []

func _ready():
	for i in range(choice_buttons.size()):
		var button = choice_buttons[i]
		button.pressed.connect(func(): _on_choice_selected(button.text if button.text != "" else button.icon.resource_path))
	
	submit_button.pressed.connect(_on_submit_input)
	answer_input.text_submitted.connect(func(_text): _on_submit_input())
	
	load_questions_from_json()
	load_question_by_id("q_5_1")

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
	
	var q_type = data.get("type", "multiple_choice")
	
	if q_type == "text_input":
		choices_container.visible = false
		input_container.visible = true
		answer_input.text = ""
		answer_input.editable = true
		submit_button.disabled = false
		answer_input.grab_focus()
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
				
				# ตรวจสอบว่าเป็น Path รูปภาพหรือไม่
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
	var is_correct = (selected_value == correct_val)
	_finish_answering(is_correct)

func _on_submit_input():
	var user_text = answer_input.text.strip_edges()
	if user_text == "":
		return
	answer_input.editable = false
	submit_button.disabled = true
	
	var correct_val = str(current_question_data.get("correct_answer", "")).strip_edges()
	var is_correct = (user_text.to_lower() == correct_val.to_lower())
	_finish_answering(is_correct)

func _finish_answering(is_correct: bool):
	if is_correct:
		feedback_label.text = "✓ ตอบถูกต้อง!"
		feedback_label.modulate = Color.GREEN
	else:
		feedback_label.text = "✗ ตอบผิด!"
		feedback_label.modulate = Color.RED
		
	question_answered.emit(is_correct)
	
	# อัปเดตเข้า GameState
	if GameState.has_signal("question_answered"):
		GameState.question_answered.emit(current_question_id, is_correct)
	if is_correct and not GameState.questions_answered.has(current_question_id):
		GameState.questions_answered.append(current_question_id)
		
	await get_tree().create_timer(1.2).timeout
	hide()
