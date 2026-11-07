extends Node2D

@onready var floor_popup: AcceptDialog = $CanvasLayer/FloorPopup
@onready var player = $Player2

func _ready() -> void:
	# IntroUI now owns the floor-entry dialogue and movement lock.
	floor_popup.hide()

func _on_popup_confirmed() -> void:
	# ให้ Player กลับมาเดินได้
	player.set_process(true)
	player.set_physics_process(true)
	player.set_process_input(true)
	player.set_process_unhandled_input(true)
