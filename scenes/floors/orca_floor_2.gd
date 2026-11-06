extends Node

@export var shake_duration: float = 0.6   # ระยะเวลาสั่น (วินาที)
@export var shake_intensity: float = 15.0 # ความแรงของการสั่น (พิกเซล)

# ค่าพารามิเตอร์ของ Orca ประจำ Floor 2
@export var floor2_speed: float = 130.0
@export var floor2_chase_mult: float = 1.8
@export var floor2_sight_range: float = 200.0
@export var floor2_sight_angle: float = 90.0
@export var floor2_lose_sight_time: float = 2.5

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# ค้นหา Orca ในกลุ่ม "orca"
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
	
	# 1. ทำหน้าจอสั่น (ปล่อยให้เสียง Jumpscare เล่นขนานกันไป)
	await _trigger_screen_shake()
	
	# 2. รอเวลา 0.8 วินาที เพื่อให้เสียง Jumpscare (SfxCaught) เล่นจนจบ
	# (ใส่ ignore_paused = true เพื่อไม่ให้ Timer ค้างแม้ฉากหยุด)
	await get_tree().create_timer(0.8, true, false, true).timeout
	
	# 3. คืนค่า Pause แล้วเริ่มฉากใหม่
	get_tree().paused = false
	get_tree().reload_current_scene()

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
