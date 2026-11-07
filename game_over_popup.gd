extends CanvasLayer
## A real scene child of Orca. Existing floor code controls pause and respawn.

func _ready() -> void:
	hide()
	var orca: Node = get_parent()
	if orca.has_signal("player_caught"):
		orca.player_caught.connect(show_game_over)
		SaveManager.add_death()

func show_game_over() -> void:
	$Backdrop.show()
	$GameOverImage.show()
	show()

func _input(_event: InputEvent) -> void:
	if visible:
		get_viewport().set_input_as_handled()
