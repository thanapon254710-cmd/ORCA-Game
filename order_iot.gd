extends CanvasLayer

signal question_answered(correct: bool)
signal puzzle_closed

const QUESTION_ID = "q_2_esp32_order"

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var feedback_label: Label = $Panel/VBoxContainer/FeedbackLabel
@onready var check_button: Button = $Panel/VBoxContainer/CheckButton
@onready var reset_button: Button = $Panel/VBoxContainer/ResetButton
@onready var reward_overlay: TextureRect = $RewardOverlay

@onready var target_slots = [
	$Panel/VBoxContainer/TargetContainer/TargetSlot0,
	$Panel/VBoxContainer/TargetContainer/TargetSlot1,
	$Panel/VBoxContainer/TargetContainer/TargetSlot2
]

@onready var source_slots = [
	$Panel/VBoxContainer/SourceContainer/SourceSlot0,
	$Panel/VBoxContainer/SourceContainer/SourceSlot1,
	$Panel/VBoxContainer/SourceContainer/SourceSlot2
]

const CORRECT_STEPS = [
	"Click upload code",
	"Press PROGRAM button until code is successfully uploaded",
	"Press RESET button"
]


func _ready():
	title_label.text = "Order Step to upload code into ESP32 (IoT)"

	reward_overlay.visible = false
	reward_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reward_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reward_overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reward_overlay.z_index = 100

	var img_path = "res://data/picture/bookshelf.png"

	if ResourceLoader.exists(img_path):
		reward_overlay.texture = load(img_path)
	else:
		push_error("bookshelf.png not found!")

	check_button.pressed.connect(_on_check_pressed)
	reset_button.pressed.connect(reset_puzzle)

	# เรียกสร้างปุ่มกากบาท
	_create_close_button()

	reset_puzzle()

	if GameState.questions_answered.has(QUESTION_ID):
		check_button.disabled = true
		reset_button.disabled = true
		feedback_label.text = "Already completed!"
		feedback_label.modulate = Color.GREEN
		_show_hint_and_close()


# สร้างปุ่มกากบาทและแปะไว้ที่ตัว CanvasLayer (self) โดยตรง
func _create_close_button():
	if has_node("CloseButton"):
		return
	var close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "×"
	close_button.tooltip_text = "Close (ESC)"
	close_button.custom_minimum_size = Vector2(45, 45)
	close_button.focus_mode = Control.FOCUS_NONE
	
	# ตั้งค่าให้อยู่มุมขวาบนสุดของหน้าจอ
	close_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_button.offset_left = -70
	close_button.offset_top = 20
	close_button.offset_right = -25
	close_button.offset_bottom = 65
	close_button.z_index = 999 # บังคับให้อยู่บนสุดเสมอ
	
	close_button.pressed.connect(close_puzzle)
	add_child(close_button) # แปะที่ตัว CanvasLayer หลัก


# ใช้ _input และดักจับปุ่ม ESC (KEY_ESCAPE) โดยตรงเพื่อให้ทำงานได้ชัวร์ 100%
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and visible:
		close_puzzle()
		get_viewport().set_input_as_handled()


func close_puzzle() -> void:
	puzzle_closed.emit()
	queue_free()


func reset_puzzle():
	feedback_label.text = ""
	check_button.disabled = false
	reset_button.disabled = false
	reward_overlay.visible = false

	for slot in target_slots:
		slot.set_symbol("")

	var shuffled = CORRECT_STEPS.duplicate()
	shuffled.shuffle()

	while shuffled == CORRECT_STEPS:
		shuffled.shuffle()

	for i in range(source_slots.size()):
		source_slots[i].set_symbol(shuffled[i])


func _on_check_pressed():
	if GameState.questions_answered.has(QUESTION_ID):
		return

	var player_steps = []

	for slot in target_slots:
		player_steps.append(slot.get_symbol().strip_edges())

	var is_correct = (player_steps == CORRECT_STEPS)

	if is_correct:
		feedback_label.text = "✓ Correct! Step order completed."
		feedback_label.modulate = Color.GREEN

		check_button.disabled = true
		reset_button.disabled = true

		GameState.mark_question_answered(QUESTION_ID, true)
		question_answered.emit(true)
		_show_hint_and_close()

	else:
		feedback_label.text = "✗ Try again! Wrong sequence."
		feedback_label.modulate = Color.RED

func _show_hint_and_close() -> void:
	reward_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reward_overlay.modulate.a = 0.0
	reward_overlay.visible = true

	var tween = create_tween()
	tween.tween_property(reward_overlay, "modulate:a", 1.0, 0.4)

	await get_tree().create_timer(3.0).timeout

	hide()
	puzzle_closed.emit()

func _close_already_completed() -> void:
	puzzle_closed.emit()
	queue_free()
