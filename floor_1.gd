extends Node2D

@onready var floor_popup: AcceptDialog = $CanvasLayer/FloorPopup
@onready var player = $Player2

func _ready() -> void:
	# หยุดการเคลื่อนไหวของ Player
	player.set_process(false)
	player.set_physics_process(false)
	player.set_process_input(false)
	player.set_process_unhandled_input(false)

	# เปิด Popup
	floor_popup.popup_centered(Vector2i(600, 450))

	# รอให้กด OK
	floor_popup.confirmed.connect(_on_popup_confirmed)


func _on_popup_confirmed() -> void:
	# ให้ Player กลับมาเดินได้
	player.set_process(true)
	player.set_physics_process(true)
	player.set_process_input(true)
	player.set_process_unhandled_input(true)
