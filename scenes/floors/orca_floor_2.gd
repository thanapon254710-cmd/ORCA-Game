extends Node

@export var shake_duration: float = 0.5   # เวลาสั่นหน้าจอเมื่อโดนจับในชั้น 2
@export var shake_intensity: float = 14.0 # ความแรงสั่นหน้าจอ

# ---------- ปรับค่าสมดุลสำหรับชั้น 2 (ยากที่สุด - วิ่งไวกว่า Player) ----------
@export var floor2_speed: float = 135.0          # เดินตรวจเร็วมาก (135.0 px/s)
@export var floor2_chase_mult: float = 1.65      # ความเร็วไล่ล่า ~222.75 px/s (ไวกว่า Player 200px/s)
@export var floor2_sight_range: float = 260.0    # ระยะสายตาไกลมาก ส่องเห็นเกือบสุดโถงทางเดิน (260.0 px)
@export var floor2_sight_angle: float = 100.0    # กรวยสายตากว้างมาก 100 องศา
@export var floor2_lose_sight_time: float = 2.5  # ติดตามดมกลิ่น 2.5 วินาทีหลังพ้นสายตา

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
			orca.speed = floor2_speed
		if "chase_multiplier" in orca:
			orca.chase_multiplier = floor2_chase_mult
		if "sight_range" in orca:
			orca.sight_range = floor2_sight_range
		if "sight_angle" in orca:
			orca.sight_angle = floor2_sight_angle
		if "lose_sight_time" in orca:
			orca.lose_sight_time = floor2_lose_sight_time

		if orca.has_signal("player_caught"):
			if not orca.player_caught.is_connected(_on_player_caught):
				orca.player_caught.connect(_on_player_caught)

func _on_player_caught() -> void:
	print("GAME OVER - FLOOR 2")
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
