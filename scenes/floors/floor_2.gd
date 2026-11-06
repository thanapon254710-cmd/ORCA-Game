extends Node2D

# รวบรวมโหนด CollisionShape2D ของโต๊ะทั้งหมดเข้ามาเก็บไว้ใน Array
@onready var table_collisons: Array[CollisionShape2D] = [
	$CollisionShape2D,
	$CollisionShape2D8,
	$CollisionShape2D7,
	$CollisionShape2D9,
	$CollisionShape2D10,
	$CollisionShape2D3,
	$CollisionShape2D4,
	$CollisionShape2D2,
	$CollisionShape2D5,
	$CollisionShape2D6
]

func _ready() -> void:
	# เปิดใช้งานกันชนของโต๊ะทั้งหมดทันทีเมื่อเข้าฉาก (เพื่อให้ผู้เล่นเดินชนและไม่ทะลุผ่าน)
	enable_table_collisions()

# ฟังก์ชันเปิดระบบกันชน
func enable_table_collisions() -> void:
	for shape in table_collisons:
		if shape:
			shape.disabled = false # ตั้งค่าเป็น false หมายถึง "เปิดใช้งานการชน"
