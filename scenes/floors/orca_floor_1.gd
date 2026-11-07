extends CharacterBody2D

signal quiz_requested

var quiz_triggered := false

func _on_area_2d_body_entered(body: Node2D) -> void:
	print("Something entered: ", body.name)

	if quiz_triggered:
		return

	if body.name == "Player2":
		quiz_triggered = true
		print("Player near Orca!")
		quiz_requested.emit()
