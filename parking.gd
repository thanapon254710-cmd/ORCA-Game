extends Node2D

signal puzzle_completed

@onready var instruction_label: Label = $UI/InstructionLabel
@onready var success_label: Label = $UI/SuccessLabel

var _ending_started := false

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

# ตัวอย่างใน parking.gd ตอนตรวจว่ารถสีแดงหลุดถึงจุด EXIT แล้ว
func _on_red_car_escaped():
	if _ending_started:
		return
	_ending_started = true
	for car in get_children():
		if car is ParkingCar:
			car.set_process_unhandled_input(false)
	print("รถสีแดงหลบหนีสำเร็จ!")
	
	# โหลดและเปิดหน้าต่างสุ่มรางวัล PCG
	var gacha_scene = load("res://reward_gacha.tscn")
	var gacha_instance = gacha_scene.instantiate()
	add_child(gacha_instance)
	
	# รอรับสัญญาณเมื่อผู้เล่นกดรับของรางวัลเสร็จสิ้น
	# รอรับสัญญาณเมื่อผู้เล่นกดรับของรางวัลเสร็จสิ้น
	# รอรับสัญญาณเมื่อผู้เล่นกดรับของรางวัลเสร็จสิ้น
	gacha_instance.reward_claimed.connect(func(item):
		var item_name = item.get("name_th", item.get("name", "Unknown Item"))
		var item_desc = item.get("desc_th", "")
		
		# นำชื่อไอเทมและคำอธิบายสุ่มมารวมกัน
		var full_reward_desc = item_name
		if item_desc != "":
			full_reward_desc += " (%s)" % item_desc
			
		print("ผู้เล่นได้รับ: ", full_reward_desc)
		
		# ส่งเข้า SaveManager
		if Engine.has_singleton("SaveManager") or get_node_or_null("/root/SaveManager"):
			SaveManager.latest_reward_name = full_reward_desc
			
		# โหลดหน้า ScoreBoard
		var sb_path = "res://score_board.tscn"
		if not ResourceLoader.exists(sb_path):
			sb_path = "res://scenes/ui/score_board.tscn"
			
		var sb_scene = load(sb_path)
		if sb_scene:
			var sb = sb_scene.instantiate()
			add_child(sb)
			
		# บันทึกสถานะว่าเคลียร์ลานจอดรถแล้ว
		if GameState.has_signal("question_answered"):
			GameState.question_answered.emit("q_parking_escaped", true)
		if not GameState.questions_answered.has("q_parking_escaped"):
			GameState.questions_answered.append("q_parking_escaped")
	)
