extends Node

@export var shake_duration: float = 0.5   # ระยะเวลาสั่น (วินาที)
@export var shake_intensity: float = 12.0 # ความแรงของการสั่น (พิกเซล)

func _ready() -> void:
	# ตั้งค่าให้ OrcaManager ทำงานได้แม้เกมจะ paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# ค้นหาโหนด Orca (รองรับทั้งชื่อ Orca และ Orca1)
	var parent := get_parent()
	var orca := parent.get_node_or_null("Orca1")
	if orca == null:
		orca = parent.get_node_or_null("Orca")
		
	if orca and orca.has_signal("player_caught"):
		orca.player_caught.connect(_on_player_caught)

func _on_player_caught() -> void:

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

		if not is_instance_valid(camera):
			return

		camera.offset = original_offset + Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)

		await tree.process_frame

		elapsed += get_process_delta_time()

	if is_instance_valid(camera):
		camera.offset = original_offset
