extends Node2D

# ระบุ Layer ของ TileMap ที่ใช้ดาวน์โหลดหรือวางบล็อกรั้ว (ตามโจทย์คือ Layer 3)
@export var gate_layer: int = 3

func _ready() -> void:
	# ตรวจสอบสถานะตอนเริ่มเกมว่าเคยปลดล็อกหรือยัง
	update_gate_visibility()

func _process(_delta: float) -> void:
	# ตรวจสอบสถานะแบบ Real-time เพื่อให้เมื่อผู้เล่นวางหนังสือถูกต้องแล้ว รั้วจะหายไปทันที
	update_gate_visibility()

func update_gate_visibility() -> void:
	# พิกัดรั้ว 3 จุดของชั้น 2: (9, 17), (10, 17), (11, 17)
	var gate_positions: Array[Vector2i] = [
		Vector2i(9, 17),
		Vector2i(10, 17),
		Vector2i(11, 17)
	]

	# ตรวจสอบว่ามีโหนดลูกชื่อ TileMap อยู่ในฉากหรือไม่
	if has_node("TileMap"):
		var tilemap = $TileMap as TileMap
		# เช็กค่าสถานะ floor2_gate_unlocked จาก GameState (เมื่อวางหนังสือในพัซเซิลถูกต้องแล้วให้เซตค่านี้เป็น true)
		if GameState.floor2_gate_unlocked:
			# ถ้าปลดล็อกแล้ว -> ลบช่อง Tile ของรั้วทั้ง 3 ตำแหน่งออกใน Layer 3
			for pos in gate_positions:
				tilemap.erase_cell(gate_layer, pos)
		else:
			# ถ้ายังไม่ปลดล็อก (ปล่อยให้มีบล็อกรั้วกั้นอยู่ตามเดิม)
			pass
