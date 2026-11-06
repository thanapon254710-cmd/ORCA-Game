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
	get_tree().paused = true                   # หยุดเกมทั้งหมด
	
	# ทำเอฟเฟกต์ภาพสั่น
	await _trigger_screen_shake()
	
	# รอจนครบ 1 วินาที (หากสั่นเสร็จก่อน)
	await get_tree().create_timer(0.5).timeout
	
	get_tree().paused = false
	get_tree().reload_current_scene()          # เริ่มด่านใหม่

# ฟังก์ชันสุ่มเขย่ากล้อง Camera2D
func _trigger_screen_shake() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
		
	var original_offset := camera.offset
	var elapsed := 0.0
	
	while elapsed < shake_duration:
		# สุ่มตำแหน่ง offset ของกล้อง
		camera.offset = original_offset + Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		# ใช้ process_frame เพื่ออัปเดตตำแหน่งกล้องทุกเฟรมแม้ขณะ paused
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		
	camera.offset = original_offset # คืนค่าตำแหน่งกล้องเดิม
