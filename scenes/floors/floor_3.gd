extends Node2D

# ระบุ Layer ของ TileMap ที่ใช้ดาวน์โหลดหรือวางบล็อกรั้ว (ตามโจทย์คือ Layer 3)
@export var gate_layer: int = 3

func _ready() -> void:
	# ตรวจสอบสถานะตอนเริ่มเกมว่าเคยปลดล็อกหรือยัง
	update_gate_visibility()

func _process(_delta: float) -> void:
	# ตรวจสอบสถานะแบบ Real-time เพื่อให้เมื่อผู้เล่นใช้ Gold Key เปิดประตูแล้ว รั้วจะหายไปทันที
	update_gate_visibility()

func update_gate_visibility() -> void:
	# พิกัดรั้ว 3 จุดของชั้น 3: (3, 15), (4, 15), (5, 15)
	var gate_positions: Array[Vector2i] = [
		Vector2i(3, 15),
		Vector2i(4, 15),
		Vector2i(5, 15)
	]

	# ตรวจสอบว่ามีโหนดลูกชื่อ TileMap อยู่ในฉากหรือไม่
	if has_node("TileMap"):
		var tilemap = $TileMap as TileMap
		# เช็กค่าสถานะ floor3_gate_unlocked จาก GameState
		if GameState.floor3_gate_unlocked:
			# ถ้าใช้ Gold Key ปดล็อกแล้ว -> ลบช่อง Tile ของรั้วทั้ง 3 ตำแหน่งออกใน Layer 3
			for pos in gate_positions:
				tilemap.erase_cell(gate_layer, pos)
		else:
			# ถ้ายังไม่ปลดล็อก (ปล่อยให้มีบล็อกรั้วกั้นอยู่ตามเดิม)
			pass
