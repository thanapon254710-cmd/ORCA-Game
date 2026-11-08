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

	# เมื่อเดินออกจาก Orca ให้ซ่อน Quiz
	orca_floor_1.quiz_closed.connect(_on_orca_quiz_closed)

	# ชนะ Orca → ลานจอดรถ
	question_box.floor_1_cleared.connect(_on_floor_1_cleared)

	# แพ้ Orca → ชั้น 5
	question_box.floor_1_game_over.connect(_on_floor_1_game_over)


func _on_popup_confirmed() -> void:
	# ให้ Player กลับมาเดินได้
	player.set_process(true)
	player.set_physics_process(true)
	player.set_process_input(true)
	player.set_process_unhandled_input(true)

	print("Player can move!")


func _on_orca_quiz_requested() -> void:
	# ถ้าชนะหรือแพ้แล้ว ไม่ให้เล่น Quiz อีก
	if question_box.floor_1_battle_finished:
		print("Floor 1 Battle already finished!")
		return

	print("Opening Floor 1 Quiz!")

	# แสดงกล่องคำถาม
	question_box.show()

	# ตรวจสอบสถานะ QuestionBox
	print("QuestionBox visible: ", question_box.visible)
	print("QuestionBox script: ", question_box.get_script())

	# เริ่มหรือ Continue Quiz Battle
	if question_box.has_method("start_floor_1_battle"):
		print("Starting Quiz Battle!")
		question_box.start_floor_1_battle()
	else:
		push_error("QuestionBox ไม่มีฟังก์ชัน start_floor_1_battle")


func _on_orca_quiz_closed() -> void:
	print("Closing Floor 1 Quiz!")
	question_box.hide()


# ชนะ Orca → ไปลานจอดรถ
func _on_floor_1_cleared() -> void:
	print("WIN! Going to Parking Lot")
	get_tree().change_scene_to_file("res://scenes/parking.tscn")


# แพ้ Orca → ไปชั้น 5
func _on_floor_1_game_over() -> void:
	print("LOSE! Going to Floor 5")
	get_tree().change_scene_to_file("res://scenes/floors/floor5.tscn")
