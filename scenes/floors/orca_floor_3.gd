extends Node

@export var shake_duration: float = 0.6
@export var shake_intensity: float = 15.0

# ปรับระยะสายตาให้แคบและสั้นลง ไม่ให้กว้างเกินไป
@export var floor3_speed: float = 150.0
@export var floor3_chase_mult: float = 2.0
@export var floor3_sight_range: float = 220.0     # ปรับลดจาก 340 เหลือ 220 (ระยะสายตาสั้นลง)
@export var floor3_sight_angle: float = 90.0      # ปรับลดจาก 130 เหลือ 90 องศา (กรวยสายตากระชับขึ้น)
@export var floor3_lose_sight_time: float = 3.0   # เวลาตามดมกลิ่นลดเหลือ 3 วินาที

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# ค้นหา Orca ในกลุ่ม "orca"
	var orcas := get_tree().get_nodes_in_group("orca")
	for orca in orcas:
		if "speed" in orca:
			orca.speed = floor3_speed
		if "chase_multiplier" in orca:
			orca.chase_multiplier = floor3_chase_mult
		if "sight_range" in orca:
			orca.sight_range = floor3_sight_range
		if "sight_angle" in orca:
			orca.sight_angle = floor3_sight_angle
		if "lose_sight_time" in orca:
			orca.lose_sight_time = floor3_lose_sight_time
			
		if orca.has_signal("player_caught"):
			if not orca.player_caught.is_connected(_on_player_caught):
				orca.player_caught.connect(_on_player_caught)

func _on_player_caught() -> void:
	print("GAME OVER - FLOOR 3")
	get_tree().paused = true
	
	await _trigger_screen_shake()
	await get_tree().create_timer(0.4).timeout
	
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
