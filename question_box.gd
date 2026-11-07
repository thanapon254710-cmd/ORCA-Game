extends CanvasLayer

signal question_answered(correct: bool)
signal question_closed
signal floor_1_cleared
signal floor_1_game_over

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

# กลุ่มช่องกรอก 4 ช่อง (Quad Input)
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
var floor_1_pool: Array = []

# --- ตัวแปรสำหรับระบบแบทเทิลชั้น 1 ---
var is_floor_1_battle: bool = false
var player_hearts: int = 3
var monster_hearts: int = 3

var battle_hud: Control
var player_heart_icons: Array[TextureRect] = []
var monster_heart_icons: Array[TextureRect] = []
var player_sprite: TextureRect
var monster_sprite: TextureRect

# พาธรูปภาพ (สามารถเปลี่ยนให้ตรงกับโฟลเดอร์ sprites ของคุณได้ครับ)
const PLAYER_TEX_PATH = "res://data/picture/player_battle.png"
const MONSTER_TEX_PATH = "res://data/picture/orca_monster.png"
const HEART_TEX_PATH = "res://data/picture/heart.png"

func _ready():
	_create_close_button()
	_create_battle_hud()
	
	# ผูกปุ่มคำตอบ
	for btn in choice_buttons:
		btn.pressed.connect(func(): _on_choice_selected(btn.text if btn.text != "" else (btn.icon.resource_path if btn.icon else "")))
	
	submit_button.pressed.connect(_on_submit_input)
	single_input.text_submitted.connect(func(_t): _on_submit_input())
	
	input_a.text_submitted.connect(func(_t): input_b.grab_focus())
	input_b.text_submitted.connect(func(_t): _on_submit_input())
	
	input_1.text_submitted.connect(func(_t): input_2.grab_focus())
	input_2.text_submitted.connect(func(_t): input_3.grab_focus())
	input_3.text_submitted.connect(func(_t): input_4.grab_focus())
	input_4.text_submitted.connect(func(_t): _on_submit_input())
	
	load_questions_from_json()

func _create_close_button():
	var close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "×"
	close_button.tooltip_text = "Close (ESC)"
	close_button.custom_minimum_size = Vector2(35, 35)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_button.offset_left = -43
	close_button.offset_top = 8
	close_button.offset_right = -8
	close_button.offset_bottom = 43
	close_button.pressed.connect(close_question)
	$Panel.add_child(close_button)


func _create_battle_hud():
	battle_hud = Control.new()
	battle_hud.name = "BattleHUD"
	battle_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	battle_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# ให้ battle_hud แสดงอยู่ชั้นบนสุด
	add_child(battle_hud)
	
	# --- 1. ตัวละครผู้เล่น (ฝั่งล่างซ้าย) ---
	player_sprite = TextureRect.new()
	player_sprite.custom_minimum_size = Vector2(160, 220)
	player_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	player_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	player_sprite.position = Vector2(60, 360)
	if ResourceLoader.exists(PLAYER_TEX_PATH):
		player_sprite.texture = load(PLAYER_TEX_PATH)
	else:
		# หากยังไม่มีรูป ให้สร้างบล็อกสีน้ำเงินจำลองเป็นตัวผู้เล่นไว้ก่อน
		var placeholder = ColorRect.new()
		placeholder.color = Color(0.2, 0.4, 0.8, 0.8)
		placeholder.set_anchors_preset(Control.PRESET_FULL_RECT)
		player_sprite.add_child(placeholder)
	battle_hud.add_child(player_sprite)
	
	# แถวหัวใจของผู้เล่น (ใต้ตัวละคร)
	var p_heart_box = HBoxContainer.new()
	p_heart_box.position = Vector2(65, 590)
	p_heart_box.add_theme_constant_override("separation", 10)
	battle_hud.add_child(p_heart_box)
	
	player_heart_icons.clear()
	for i in range(3):
		var h = TextureRect.new()
		h.custom_minimum_size = Vector2(36, 36)
		h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if ResourceLoader.exists(HEART_TEX_PATH):
			h.texture = load(HEART_TEX_PATH)
		else:
			# แสดงหัวใจสี่เหลี่ยมสีแดงแบบพิกเซลทันที
			var red_box = ColorRect.new()
			red_box.color = Color.RED
			red_box.set_anchors_preset(Control.PRESET_FULL_RECT)
			h.add_child(red_box)
		p_heart_box.add_child(h)
		player_heart_icons.append(h)
		
	# --- 2. มอนสเตอร์ออก้า (ฝั่งล่างขวา) ---
	monster_sprite = TextureRect.new()
	monster_sprite.custom_minimum_size = Vector2(230, 230)
	monster_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	monster_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	monster_sprite.position = Vector2(860, 350)
	if ResourceLoader.exists(MONSTER_TEX_PATH):
		monster_sprite.texture = load(MONSTER_TEX_PATH)
	else:
		var placeholder = ColorRect.new()
		placeholder.color = Color(0.6, 0.1, 0.4, 0.8)
		placeholder.set_anchors_preset(Control.PRESET_FULL_RECT)
		monster_sprite.add_child(placeholder)
	battle_hud.add_child(monster_sprite)
	
	# แถวหัวใจของออก้า (ใต้ออก้า)
	var m_heart_box = HBoxContainer.new()
	m_heart_box.position = Vector2(895, 590)
	m_heart_box.add_theme_constant_override("separation", 10)
	battle_hud.add_child(m_heart_box)
	
	monster_heart_icons.clear()
	for i in range(3):
		var h = TextureRect.new()
		h.custom_minimum_size = Vector2(36, 36)
		h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if ResourceLoader.exists(HEART_TEX_PATH):
			h.texture = load(HEART_TEX_PATH)
		else:
			var red_box = ColorRect.new()
			red_box.color = Color.RED
			red_box.set_anchors_preset(Control.PRESET_FULL_RECT)
			h.add_child(red_box)
		m_heart_box.add_child(h)
		monster_heart_icons.append(h)
		
	battle_hud.visible = false

func _update_hearts_ui():
	for i in range(3):
		player_heart_icons[i].modulate.a = 1.0 if i < player_hearts else 0.15
		monster_heart_icons[i].modulate.a = 1.0 if i < monster_hearts else 0.15

func start_floor_1_battle():
	# ถ้าเคยเริ่ม Battle แล้ว ให้กลับมาเล่นต่อ
	if is_floor_1_battle:
		show()
		battle_hud.visible = true
		_update_hearts_ui()
		print("Continue Floor 1 Battle!")
		return

	# เริ่ม Battle ครั้งแรกเท่านั้น
	is_floor_1_battle = true
	player_hearts = 3
	monster_hearts = 3
	battle_hud.visible = true
	_update_hearts_ui()

	floor_1_pool.clear()	
	for q in questions_list:
		var q_id = str(q.get("id", ""))
		if q_id.begins_with("q1") or q.get("floor") == 1:
			floor_1_pool.append(q)

	floor_1_pool.shuffle()
	_next_floor_1_question()

func _next_floor_1_question():
	if floor_1_pool.is_empty():
		for q in questions_list:
			if str(q.get("id", "")).begins_with("q_1_") or q.get("floor") == 1:
				floor_1_pool.append(q)
		floor_1_pool.shuffle()
		
	if floor_1_pool.is_empty():
		push_warning("ไม่พบคำถามชั้น 1 ใน questions.json")
		return
		
	var next_q = floor_1_pool.pop_front()
	display_question(next_q)

func load_questions_from_json():
	var file_path = "res://questions.json"
	if not FileAccess.file_exists(file_path):
		push_error("ไม่พบไฟล์: " + file_path)
		return
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	
	if parsed and parsed.has("questions"):
		questions_list = parsed["questions"]
		print("โหลดคำถามสำเร็จ: ", questions_list.size(), " ข้อ")

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
	
	var req_key = data.get("required_key", "")
	if req_key != "" and not Inventory.has_item(req_key):
		var key_display = str(Inventory.ITEM_NAMES.get(req_key, req_key))
		feedback_label.text = "🔒 Locked! Requires " + key_display + " to unlock."
		feedback_label.modulate = Color.ORANGE
		choices_container.visible = false
		input_container.visible = false
		question_image.visible = false
		show()
		return
	
	var img_path = data.get("image_path", "")
	if img_path != "" and ResourceLoader.exists(img_path):
		question_image.texture = load(img_path)
		question_image.visible = true
		question_image.custom_minimum_size = Vector2(0, 320)
	else:
		question_image.texture = null
		question_image.visible = false
	
	var q_type = data.get("type", "multiple_choice")
	
	if q_type == "text_input_quad":
		choices_container.visible = false
		input_container.visible = true
		single_input.visible = false
		double_input_container.visible = false
		quad_input_container.visible = true
		quad_input_container.columns = 4
		
		label_1.text = "0 XOR 0 = "
		label_2.text = "0 XOR 1 = "
		label_3.text = "1 XOR 0 = "
		label_4.text = "1 XOR 1 = "
		
		for inp in [input_1, input_2, input_3, input_4]:
			inp.text = ""
			inp.editable = true
			inp.placeholder_text = "0 or 1"
			inp.custom_minimum_size = Vector2(60, 35)
		submit_button.disabled = false
		input_1.grab_focus()
		
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
		
	else:
		input_container.visible = false
		choices_container.visible = true
		quad_input_container.visible = false
		double_input_container.visible = false
		
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
	# ถ้าอยู่ในโหมดดวลชั้น 1 ให้ปรับกล่องคำถามให้อยู่ด้านบนกึ่งกลางเหมือนบอลลูนคำพูด
	if is_floor_1_battle:
		$Panel.position = Vector2(240, 30)
		# ขยายความสูงเป็น 310px เพื่อให้คลุมครบทั้ง 5 ตัวเลือก
		$Panel.size = Vector2(670, 310)
		# สั่งรีเซ็ตขนาดอัตโนมัติตามเนื้อหาด้านใน
		$Panel.reset_size()

func _on_choice_selected(selected_value: String):
	for btn in choice_buttons:
		btn.disabled = true
	var correct_val = str(current_question_data.get("correct_answer", ""))
	var is_correct = (correct_val == "*" or selected_value.strip_edges() == correct_val.strip_edges())
	_finish_answering(is_correct)

func _on_submit_input():
	var q_type = current_question_data.get("type", "")
	var correct_val = str(current_question_data.get("correct_answer", ""))
	var is_correct = false
	
	if q_type == "text_input_quad":
		var u1 = input_1.text.strip_edges()
		var u2 = input_2.text.strip_edges()
		var u3 = input_3.text.strip_edges()
		var u4 = input_4.text.strip_edges()
		
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
	if is_floor_1_battle:
		_handle_floor_1_answer(is_correct)
		return
		
	if is_correct:
		feedback_label.text = "✓ correct!"
		feedback_label.modulate = Color.GREEN
		var required_key: String = str(current_question_data.get("required_key", ""))
		if required_key != "" and Inventory.has_item(required_key):
			Inventory.remove_item(required_key)
		
		var reward_k = current_question_data.get("reward_key", "")
		if reward_k != "":
			var unique_pickup_id = "reward_" + current_question_id + "_" + str(Time.get_ticks_msec())
			Inventory.collect(reward_k, unique_pickup_id)
			var key_name = str(Inventory.ITEM_NAMES.get(reward_k, reward_k))
			feedback_label.text += " Received " + key_name + "!"
			
		question_answered.emit(is_correct)
		if GameState.has_signal("question_answered"):
			GameState.question_answered.emit(current_question_id, is_correct)
		if not GameState.questions_answered.has(current_question_id):
			GameState.questions_answered.append(current_question_id)
			
		await get_tree().create_timer(1.5).timeout
		
		hide()
		question_closed.emit()
	else:
		feedback_label.text = "try again"
		feedback_label.modulate = Color.RED
		var q_type = current_question_data.get("type", "multiple_choice")
		if q_type == "text_input":
			single_input.editable = true
			single_input.text = ""
			submit_button.disabled = false
			single_input.grab_focus()
		elif q_type == "text_input_double":
			input_a.editable = true
			input_b.editable = true
			input_a.text = ""
			input_b.text = ""
			submit_button.disabled = false
			input_a.grab_focus()
		elif q_type == "text_input_quad":
			for inp in [input_1, input_2, input_3, input_4]:
				inp.editable = true
				inp.text = ""
			submit_button.disabled = false
			input_1.grab_focus()
		else:
			for btn in choice_buttons:
				btn.disabled = false

func _handle_floor_1_answer(is_correct: bool):
	if is_correct:
		monster_hearts -= 1
		feedback_label.text = "✓ Correct! Oga loses one heart!"
		feedback_label.modulate = Color.GREEN
		
		var tween = create_tween()
		tween.tween_property(monster_sprite, "modulate", Color.RED, 0.15)
		tween.tween_property(monster_sprite, "modulate", Color.WHITE, 0.15)
	else:
		player_hearts -= 1
		feedback_label.text = "✗ Wrong! You lose 1 heart!"
		feedback_label.modulate = Color.RED
		
		var tween = create_tween()
		tween.tween_property(player_sprite, "modulate", Color.RED, 0.15)
		tween.tween_property(player_sprite, "modulate", Color.WHITE, 0.15)
		
	_update_hearts_ui()
	await get_tree().create_timer(1.5).timeout
	
	if monster_hearts <= 0:
		feedback_label.text = "🎉 Congratulations! You have successfully defeated Oga!"
		feedback_label.modulate = Color.GREEN
		await get_tree().create_timer(2.0).timeout
		battle_hud.visible = false
		is_floor_1_battle = false
		hide()
		floor_1_cleared.emit()
		get_tree().paused = false
		get_tree().change_scene_to_file.call_deferred("res://scenes/parking.tscn")
	elif player_hearts <= 0:
		feedback_label.text = "💀 GAME OVER... You have run out of heart."
		feedback_label.modulate = Color.DARK_RED
		await get_tree().create_timer(2.0).timeout
		battle_hud.visible = false
		is_floor_1_battle = false
		hide()
		floor_1_game_over.emit()
	else:
		_next_floor_1_question()

func close_question() -> void:
	if not visible:
		return
	if is_floor_1_battle and battle_hud:
		battle_hud.visible = false
	hide()
	question_closed.emit()
