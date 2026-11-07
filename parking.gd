extends Node2D

signal puzzle_completed

@onready var instruction_label: Label = $UI/InstructionLabel
@onready var success_label: Label = $UI/SuccessLabel

var selected_car: ParkingCar = null

func _ready():
	# แสดงข้อความวิธีเล่นค้างไว้ 4 วินาทีแล้วค่อยๆ จางหายไป
	instruction_label.visible = true
	success_label.visible = false
	_fade_out_instructions()

	# เชื่อมต่อสัญญาณจากรถทุกคันในฉาก
	for child in get_children():
		if child is ParkingCar:
			child.car_selected.connect(_on_car_selected)
			if child.is_red_car:
				child.red_car_escaped.connect(_on_red_car_escaped)

func _fade_out_instructions():
	await get_tree().create_timer(4.0).timeout
	var tween = create_tween()
	tween.tween_property(instruction_label, "modulate:a", 0.0, 1.0)
	await tween.finished
	instruction_label.visible = false

func _on_car_selected(car: ParkingCar):
	if selected_car != null:
		selected_car.set_selected(false)
		
	selected_car = car
	selected_car.set_selected(true)

func _unhandled_input(event):
	# คลิกขวาเพื่อยกเลิกการเลือกรถ
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if selected_car != null:
			selected_car.set_selected(false)
			selected_car = null

func _on_red_car_escaped():
	print("รถสีแดงหลุดออกจากลานจอดรถสำเร็จ!")
	
	# แสดงข้อความว่าคุณออกจากที่นี่ได้แล้ว
	success_label.modulate.a = 0.0
	success_label.visible = true
	var tween = create_tween()
	tween.tween_property(success_label, "modulate:a", 1.0, 0.5)
	
	puzzle_completed.emit()
	
	# อัปเดตสถานะเข้า GameState กลาง
	if GameState.has_signal("question_answered"):
		GameState.question_answered.emit("q_parking_puzzle", true)
	if not GameState.questions_answered.has("q_parking_puzzle"):
		GameState.questions_answered.append("q_parking_puzzle")
		
	# รอสักครู่แล้วเปิดทางหรือเปลี่ยนกลับไปยังฉากหลัก
	await get_tree().create_timer(2.5).timeout
	# queue_free() หรือ get_tree().change_scene_to_file("res://scenes/main.tscn")
