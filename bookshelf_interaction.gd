
extends Area2D

@export var puzzle_scene: PackedScene = preload("res://bookshelf_puzzle.tscn")

var puzzle_instance: CanvasLayer
var prompt: Label


func _ready():
	prompt = Label.new()
	prompt.text = "E - Arrange Books"
	prompt.position = Vector2(-55, -48)
	prompt.visible = false
	add_child(prompt)


func can_interact() -> bool:
	return (
		not is_instance_valid(puzzle_instance)
		and not GameState.game_is_over
	)


func set_focused(value: bool):
	if is_instance_valid(prompt):
		prompt.visible = value and can_interact()


func interact(_player: Node):
	if not can_interact():
		return

	if not GameState.questions_answered.has("q_2_esp32_order"):
		show_message("Complete the IoT computer question first!")
		return

	if not GameState.has_all_ft2_books():
		var white = Inventory.get_count("book_white")
		var blue = Inventory.get_count("book_blue")
		var orange = Inventory.get_count("book_orange")

		return

	puzzle_instance = puzzle_scene.instantiate()
	get_tree().root.add_child(puzzle_instance)

	puzzle_instance.puzzle_closed.connect(_on_puzzle_closed)


func _on_puzzle_closed():
	if is_instance_valid(puzzle_instance):
		puzzle_instance.queue_free()

	puzzle_instance = null


func show_message(message: String):
	var popup = AcceptDialog.new()
	popup.title = "Bookshelf Locked"
	popup.dialog_text = message

	get_tree().root.add_child(popup)
	popup.confirmed.connect(func(): popup.queue_free())
	popup.canceled.connect(func(): popup.queue_free())
	popup.popup_centered()
