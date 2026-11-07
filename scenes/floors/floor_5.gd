extends Node2D

@onready var popup_text: Label = $CanvasLayer/PopupText
var popup_time_left: float = 0.0

# ดึงโหนด TileMap จากในฉากมาใช้งานอัตโนมัติ 
@onready var target_tilemap: TileMap = $TileMap 

# fence location
@export var fence_coords: Array[Vector2i] = [
	Vector2i(9, 15),
	Vector2i(10, 15),
	Vector2i(11, 15),
	Vector2i(12, 15),
	Vector2i(13, 15),
	Vector2i(14, 15)
]

func _ready() -> void:
	popup_text.hide()
	# call function remove fences
	GameState.question_answered.connect(_on_question_answered)
	
	# Check previously completed questions when returning to Floor 5
	check_all_questions_completed()

func _on_question_answered(question_id: String, is_correct: bool) -> void:
	# Ignore incorrect answers
	if not is_correct:
		return

	check_all_questions_completed()

func check_all_questions_completed() -> void:
	var required_questions = [
		"q_5_1",
		"q_5_2",
		"q_5_3"
	]

	for question_id in required_questions:
		if not GameState.questions_answered.has(question_id):
			return

	# All questions are correct!
	remove_fences()

func remove_fences() -> void:
	if target_tilemap:
		for coord in fence_coords:
			target_tilemap.set_cell(3, coord, -1)

		print("The barrier has fallen! The way down to the 4th floor is now open.")

func show_popup(message: String) -> void:
	popup_text.text = message
	popup_text.show()
	popup_time_left = 2.0
	
func _process(delta: float) -> void:
	if popup_time_left > 0.0:
		popup_time_left -= delta
		if popup_time_left <= 0.0:
			popup_text.hide()

# ---------- ระบบควบคุม Hiding Spot ทั้ง 3 จุด ----------

# ฟังก์ชันตัวกลางช่วยจัดการสถานะการซ่อนของ Player
func _set_player_hiding(body: Node2D, hiding: bool) -> void:
	if body.is_in_group("player"):
		if hiding:
			if "hiding_zones_count" in body:
				body.hiding_zones_count += 1
			body.is_hiding = true
			print("Player entered Hiding Zone! (is_hiding = true)")
		else:
			if "hiding_zones_count" in body:
				body.hiding_zones_count = max(0, body.hiding_zones_count - 1)
				if body.hiding_zones_count == 0:
					body.is_hiding = false
			else:
				body.is_hiding = false
			print("Player left Hiding Zone!")

# จุดซ่อนที่ 1
func _on_hiding_spot_1_body_entered(body: Node2D) -> void:
	_set_player_hiding(body, true)

func _on_hiding_spot_1_body_exited(body: Node2D) -> void:
	_set_player_hiding(body, false)

# จุดซ่อนที่ 2
func _on_hiding_spot_2_body_entered(body: Node2D) -> void:
	_set_player_hiding(body, true)

func _on_hiding_spot_2_body_exited(body: Node2D) -> void:
	_set_player_hiding(body, false)

# จุดซ่อนที่ 3
func _on_hiding_spot_3_body_entered(body: Node2D) -> void:
	_set_player_hiding(body, true)

func _on_hiding_spot_3_body_exited(body: Node2D) -> void:
	_set_player_hiding(body, false)
