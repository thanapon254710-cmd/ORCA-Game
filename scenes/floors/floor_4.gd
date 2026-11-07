extends Node2D

# ระบุ Layer ของ TileMap ที่ใช้ดาวน์โหลดหรือวางบล็อกรั้ว (ปกติมักจะเป็น Layer 0)
@export var gate_layer: int = 3

func _ready() -> void:
	# ตรวจสอบสถานะตอนเริ่มเกมว่าเคยปลดล็อกหรือยัง
	update_gate_visibility()

func _process(_delta: float) -> void:
	# ตรวจสอบสถานะแบบ Real-time เพื่อให้ผู้เล่นเพิ่งแก้พัซเซิลเสร็จแล้วเดินกลับมา
	update_gate_visibility()

func update_gate_visibility() -> void:
	# พิกัดรั้ว 3 จุดตามที่ระบุ: (12, 15), (13, 15), (14, 15)
	var gate_positions: Array[Vector2i] = [
		Vector2i(12, 15),
		Vector2i(13, 15),
		Vector2i(14, 15)
	]

	# ตรวจสอบว่ามีโหนดลูกชื่อ TileMap อยู่ในฉากหรือไม่
	if has_node("TileMap"):
		var tilemap = $TileMap as TileMap
		# เช็กค่าสถานะ floor4_gate_unlocked จาก GameState
		if GameState.floor4_gate_unlocked:
			# ถ้าปลดล็อกแล้ว -> ลบช่อง Tile ของรั้วทั้ง 3 ตำแหน่งออก (ทำให้เดินผ่านได้)
			for pos in gate_positions:
				tilemap.erase_cell(gate_layer, pos)
		else:
			# ถ้ายังไม่ปลดล็อก (ปล่อยให้มีบล็อกกั้นอยู่ตามเดิม)
			pass
