extends Control

func _ready() -> void:
	get_tree().paused = false
	Inventory.get_node("InventoryHUD").hide()
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file("res://score_board.tscn")
