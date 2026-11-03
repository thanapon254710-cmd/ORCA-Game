extends CharacterBody2D

const SPEED = 200.0

func _physics_process(delta):
	# รับค่าการกดปุ่ม 4 ทิศทาง (ลูกศร หรือ WASD)
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# กำหนดความเร็วตามทิศทางที่กด
	velocity = direction * SPEED
	
	# สั่งให้เคลื่อนที่และชนกำแพง
	move_and_slide()
