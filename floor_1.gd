extends Node2D

@onready var floor_popup: AcceptDialog = $CanvasLayer/FloorPopup
@onready var player = $Player2
@onready var orca_floor_1 = $OrcaFloor1
@onready var question_box = $QuestionBox


func _ready() -> void:
	# ซ่อน Quiz ตอนเริ่มเกม
	question_box.hide()

	# ตรวจสอบและเชื่อม Signal จาก Orca
	if orca_floor_1.has_signal("quiz_requested"):
		orca_floor_1.connect(
			"quiz_requested",
			_on_orca_quiz_requested
		)
		print("Orca signal connected!")
	else:
		push_error("OrcaFloor1 ไม่มี signal quiz_requested")

	# หยุด Player ระหว่าง Popup ต้อนรับ
	player.set_process(false)
	player.set_physics_process(false)
	player.set_process_input(false)
	player.set_process_unhandled_input(false)

	# เชื่อมปุ่ม OK ของ Popup
	floor_popup.confirmed.connect(_on_popup_confirmed)

	# เปิด Popup ต้อนรับ
	floor_popup.popup_centered(Vector2i(600, 450))
	
	orca_floor_1.quiz_closed.connect(_on_orca_quiz_closed)


func _on_popup_confirmed() -> void:
	# ให้ Player กลับมาเดินได้
	player.set_process(true)
	player.set_physics_process(true)
	player.set_process_input(true)
	player.set_process_unhandled_input(true)

	print("Player can move!")


func _on_orca_quiz_requested() -> void:
	print("Opening Floor 1 Quiz!")

	# แสดงกล่องคำถาม
	question_box.show()

	# ตรวจสอบสถานะ QuestionBox
	print("QuestionBox visible: ", question_box.visible)
	print("QuestionBox script: ", question_box.get_script())

	# เริ่ม Quiz Battle
	if question_box.has_method("start_floor_1_battle"):
		print("Starting Quiz Battle!")
		question_box.start_floor_1_battle()
	else:
		push_error("QuestionBox ไม่มีฟังก์ชัน start_floor_1_battle")

func _on_orca_quiz_closed() -> void:
	print("Closing Floor 1 Quiz!")
	question_box.hide()
