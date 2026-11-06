extends Node

@export var shake_duration: float = 0.6
@export var shake_intensity: float = 16.0

# ปรับค่าพลัง Floor 2 ให้สมดุลกับซอกตู้หนังสือ
@export var floor2_speed: float = 140.0
@export var floor2_chase_mult: float = 2.0
@export var floor2_sight_range: float = 220.0     # ปรับสั้นลงเป็น 220 เพื่อไม่ให้มองเห็นทะลุข้ามห้องเกินไป
@export var floor2_sight_angle: float = 90.0      # ปรับเหลือ 90 องศา เพื่อให้มองลอดช่องตู้หนังสือพอดี[cite: 5]
@export var floor2_lose_sight_time: float = 3.0   # ให้เวลาดมกลิ่นตามไล่หลังหลุดสายตา 3 วินาที

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# ค้นหา Orca ในกลุ่ม "orca" เหมือน Floor 3
	var orcas := get_tree().get_nodes_in_group("orca")
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
	
	await _trigger_screen_shake()
	await get_tree().create_timer(0.3).timeout
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
