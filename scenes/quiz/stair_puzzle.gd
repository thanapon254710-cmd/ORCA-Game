# StairPuzzle.gd
extends CanvasLayer

signal question_answered(correct: bool)

@onready var hint_label: Label = $Panel/VBoxContainer/HintLabel
@onready var feedback_label: Label = $Panel/VBoxContainer/FeedbackLabel
@onready var check_button: Button = $Panel/VBoxContainer/CheckButton
@onready var reset_button: Button = $Panel/VBoxContainer/ResetButton

# ดึง 4 ช่องเป้าหมาย และ 4 ช่องต้นทาง
@onready var target_slots = [
	$Panel/VBoxContainer/TargetContainer/Slot0,
	$Panel/VBoxContainer/TargetContainer/Slot1,
	$Panel/VBoxContainer/TargetContainer/Slot2,
	$Panel/VBoxContainer/TargetContainer/Slot3
]

@onready var source_slots = [
	$Panel/VBoxContainer/SourceContainer/Item0,
	$Panel/VBoxContainer/SourceContainer/Item1,
	$Panel/VBoxContainer/SourceContainer/Item2,
	$Panel/VBoxContainer/SourceContainer/Item3
]

# ลำดับเฉลยที่ถูกต้อง: เรียง Ascending ตามเลขห้อง 403, 404, 407, 408
const CORRECT_ORDER = ["⇑", "⊡", "✧", "☾"]

func _ready():
	hint_label.text = "Hint: Ascending"
	hint_label.modulate = Color.GOLD
	
	check_button.pressed.connect(_on_unlock_pressed)
	reset_button.pressed.connect(reset_puzzle)
	
	reset_puzzle()

func reset_puzzle():
	feedback_label.text = ""
	check_button.disabled = false
	
	# ล้างช่องเป้าหมายด้านบนให้ว่าง
	for slot in target_slots:
		slot.set_symbol("")
		
	# สุ่มสลับตำแหน่งสัญลักษณ์ในช่องด้านล่าง
	var shuffled = CORRECT_ORDER.duplicate()
	shuffled.shuffle()
	
	# ป้องกันสุ่มได้เฉลยตรงเป๊ะแต่แรก
	while shuffled == CORRECT_ORDER:
		shuffled.shuffle()
		
	for i in range(source_slots.size()):
		source_slots[i].set_symbol(shuffled[i])

func _on_unlock_pressed():
	var player_order = []
	for slot in target_slots:
		player_order.append(slot.get_symbol())
		
	# ตรวจว่าเรียงเป็น ["⇑", "⊡", "✧", "☾"] ครบทุกช่องหรือไม่
	var is_correct = (player_order == CORRECT_ORDER)
	
	if is_correct:
		feedback_label.text = "✓ Door Unlocked! The stairs are open."
		feedback_label.modulate = Color.GREEN
		check_button.disabled = true
		
		# ยิง Signal แจ้งเตือนระบบกลางและ GameState
		question_answered.emit(true)
		if GameState.has_signal("question_answered"):
			GameState.question_answered.emit("q_4_stair", true)
		if not GameState.questions_answered.has("q_4_stair"):
			GameState.questions_answered.append("q_4_stair")
			
		await get_tree().create_timer(1.5).timeout
		hide()
	else:
		feedback_label.text = "try again"
		feedback_label.modulate = Color.RED
