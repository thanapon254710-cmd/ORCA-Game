extends CharacterBody2D

signal quiz_requested
signal quiz_closed  # เพิ่ม: แจ้งให้ปิด Quiz

var quiz_triggered := false


func _on_hit_box_body_entered(body: Node2D) -> void:
	print("Something entered: ", body.name)

	if quiz_triggered:
		return

	if body.name == "Player2":
		quiz_triggered = true
		print("Player near Orca!")

		print("Before emitting signal")
		quiz_requested.emit()
		print("After emitting signal")


# เพิ่ม: เมื่อ Player2 เดินออกจาก HitBox
func _on_hit_box_body_exited(body: Node2D) -> void:
	if body.name == "Player2":
		quiz_triggered = false
		print("Player left Orca!")
		quiz_closed.emit()
