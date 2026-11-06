extends Node

@export var shake_duration: float = 0.5   # ระยะเวลาสั่น
@export var shake_intensity: float = 12.0 # ความแรงของการสั่น

@export var floor5_speed: float = 160.0
@export var floor5_chase_mult: float = 2.0
@export var floor5_sight_range: float = 240.0
@export var floor5_sight_angle: float = 100.0
@export var floor5_lose_sight_time: float = 3.0

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
	print("GAME OVER - FLOOR 5")
	
	# 1. ทำหน้าจอสั่น (ปล่อยให้เสียง Jumpscare เล่นขนานกันไป)
	await _trigger_screen_shake()
	
	# 2. รอเวลา 0.8 วินาที เพื่อให้เสียง Jumpscare (SfxCaught) เล่นจนจบ
	# (ตั้งค่า ignore_paused = true เพื่อไม่ให้ Timer ค้างแม้ฉากหยุด)
	await get_tree().create_timer(0.8, true, false, true).timeout
	
	# 3. โหลดด่านใหม่หลังจากเสียงเล่นจบแล้ว
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
