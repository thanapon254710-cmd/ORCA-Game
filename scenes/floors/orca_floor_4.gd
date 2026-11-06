extends Node

@export var shake_duration: float = 0.35  # เวลาสั่นหน้าจอเมื่อโดนจับ (เพิ่มความตื่นเต้นนิดหน่อย)
@export var shake_intensity: float = 8.0  # ความแรงสั่นหน้าจอ

# ---------- ปรับค่าสมดุลสำหรับชั้น 4 (ยากขึ้นนิดหน่อย ท้าทายขึ้น) ----------
@export var floor4_speed: float = 80.0           # เดินตรวจเร็วขึ้น (จาก 50.0 เป็น 80.0)
@export var floor4_chase_mult: float = 1.4       # ไล่ล่าเร็วขึ้นเป็น 112 px/s (ผู้เล่นวิ่ง 200 ยังหนีพ้นแต่ต้องตั้งสติ)
@export var floor4_sight_range: float = 170.0    # มองเห็นไกลขึ้นประมาณ 3-4 ช่องพิกเซล
@export var floor4_sight_angle: float = 65.0     # กรวยสายตากว้างขึ้น เดินผ่านเฉียงๆ อาจโดนเห็นได้
@export var floor4_lose_sight_time: float = 1.0  # ติดตามดมกลิ่น 1 วินาทีหลังพ้นสายตา (ซ่อน Safe Zone ยกเลิกทันทีตามเดิม)

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
			orca.speed = floor4_speed
		if "chase_multiplier" in orca:
			orca.chase_multiplier = floor4_chase_mult
		if "sight_range" in orca:
			orca.sight_range = floor4_sight_range
		if "sight_angle" in orca:
			orca.sight_angle = floor4_sight_angle
		if "lose_sight_time" in orca:
			orca.lose_sight_time = floor4_lose_sight_time

		if orca.has_signal("player_caught"):
			if not orca.player_caught.is_connected(_on_player_caught):
				orca.player_caught.connect(_on_player_caught)

func _on_player_caught() -> void:
	print("GAME OVER - FLOOR 4")
	get_tree().paused = true
	
	await _trigger_screen_shake()
	await get_tree().create_timer(0.8, true, false, true).timeout
	
	get_tree().paused = false
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
