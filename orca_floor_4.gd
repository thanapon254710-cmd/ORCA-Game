extends Node

@export var shake_duration: float = 0.6   # ลดเวลาสั่นให้น้อยลงนิดหน่อย
@export var shake_intensity: float = 12.0 # ลดความแรงสั่นหน้าจอลง

# ---------- ปรับค่าสมดุลสำหรับชั้นแรก (เริ่มต้นง่ายขึ้น) ----------
@export var floor5_speed: float = 100.0           # ความเร็วเดินปรกติ (ช้าลง)
@export var floor5_chase_mult: float = 2.0       # ตัวคูณความเร็วไล่ล่า (ไล่ไม่กระชาก)
@export var floor5_sight_range: float = 200.0    # ระยะสายตา (มองเห็นได้สั้นลง)
@export var floor5_sight_angle: float = 80.0     # กรวยสายตา (แคบลง แอบซอกง่ายขึ้น)
@export var floor5_lose_sight_time: float = 2.0  # เวลาติดตามดมกลิ่น (หลบพ้นแล้วถอยกลับไวขึ้น)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var orcas := get_tree().get_nodes_in_group("orca")
	if orcas.is_empty():
		var parent := get_parent()
		var single_orca := parent.get_node_or_null("Orca1")
		if single_orca == null:
			single_orca = parent.get_node_or_null("Orca")
		if single_orca:
			orcas.append(single_orca)

	for orca in orcas:
		if "speed" in orca:
			orca.speed = floor5_speed
		if "chase_multiplier" in orca:
			orca.chase_multiplier = floor5_chase_mult
		if "sight_range" in orca:
			orca.sight_range = floor5_sight_range
		if "sight_angle" in orca:
			orca.sight_angle = floor5_sight_angle
		if "lose_sight_time" in orca:
			orca.lose_sight_time = floor5_lose_sight_time

		if orca.has_signal("player_caught"):
			if not orca.player_caught.is_connected(_on_player_caught):
				orca.player_caught.connect(_on_player_caught)

func _on_player_caught() -> void:
	print("GAME OVER - FLOOR 4")
	get_tree().paused = true

	await _trigger_screen_shake()
	await get_tree().create_timer(0.8, true, false, true).timeout

	get_tree().paused = false

	# Respawn at PlayerSpawn instead of the original Player position.
	await TransitionManager.respawn_player()

func _trigger_screen_shake() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
		
	var original_offset := camera.offset
	var elapsed := 0.0
	
	while elapsed < shake_duration:
		camera.offset = original_offset + Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		
	camera.offset = original_offset
