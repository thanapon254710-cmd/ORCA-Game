extends Node

@export var shake_duration: float = 0.6   # ระยะเวลาสั่น (วินาที)
@export var shake_intensity: float = 15.0 # ความแรงของการสั่น (พิกเซล)

# ค่าพารามิเตอร์ของ Orca ประจำ Floor 5
@export var floor5_speed: float = 160.0
@export var floor5_chase_mult: float = 2.0
@export var floor5_sight_range: float = 240.0
@export var floor5_sight_angle: float = 100.0
@export var floor5_lose_sight_time: float = 3.0

func _ready() -> void:
	# ตั้งค่าให้ Manager ทำงานได้แม้เกมจะติด paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# ค้นหา Orca ในฉากผ่าน Group "orca"
	var orcas := get_tree().get_nodes_in_group("orca")
	
	# Fallback: หากไม่ได้ใส่ Group ไว้ ให้หาตามชื่อโหนดเดิม
	if orcas.is_empty():
		var parent := get_parent()
		var single_orca := parent.get_node_or_null("Orca1")
		if single_orca == null:
			single_orca = parent.get_node_or_null("Orca")
		if single_orca:
			orcas.append(single_orca)

	# Override ค่าพลังของ Orca ใน Floor 5 และเชื่อมต่อ Signal
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
<<<<<<< Updated upstream

	print("GAME OVER")

	# Save the SceneTree reference before awaiting
	var tree = get_tree()

	if tree == null:
		return

	# Close question popups
	tree.call_group(
		"question_points",
        "close_question_ui"
	)

	# Pause the game
	tree.paused = true

	await _trigger_screen_shake()

	# Check that the tree is still valid
	if not is_instance_valid(tree):
		return

	# Wait using the saved SceneTree reference
	tree.paused = false

	await tree.create_timer(0.5).timeout

	if not is_instance_valid(tree):
		return

	tree.reload_current_scene()
	
# ฟังก์ชันสุ่มเขย่ากล้อง Camera2D
=======
	print("GAME OVER - FLOOR 5")
	get_tree().paused = true
	
	# 1. เล่นเอฟเฟกต์หน้าจอสั่น (ระหว่างนี้เสียง SfxCaught ใน Orca จะเล่นขนานไปด้วย)
	await _trigger_screen_shake()
	
	# 2. รออีก 0.8 วินาที เพื่อให้เสียง Jumpscare เล่นเสร็จสมบูรณ์
	# (ใส่ true ตัวที่ 4 หรือ ignore_paused เพื่อให้ Timer ไม่แช่แข็ง)
	await get_tree().create_timer(0.8, true, false, true).timeout
	
	# 3. คืนค่า Pause แล้วเริ่มฉากใหม่
	get_tree().paused = false
	get_tree().reload_current_scene()

>>>>>>> Stashed changes
func _trigger_screen_shake() -> void:

	# Make sure this node is still inside the scene tree
	if not is_inside_tree():
		return

	var tree = get_tree()

	if tree == null:
		return

	# Get the main viewport safely
	var viewport = tree.root

	if viewport == null:
		return

	var camera = viewport.get_camera_2d()

	if camera == null:
		print("WARNING: No active Camera2D found!")
		return

	var original_offset = camera.offset
	var elapsed = 0.0

	while elapsed < shake_duration:
<<<<<<< Updated upstream

		if not is_instance_valid(camera):
			return

=======
>>>>>>> Stashed changes
		camera.offset = original_offset + Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
<<<<<<< Updated upstream

		await tree.process_frame

		elapsed += get_process_delta_time()

	if is_instance_valid(camera):
		camera.offset = original_offset
=======
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		
	camera.offset = original_offset
>>>>>>> Stashed changes
