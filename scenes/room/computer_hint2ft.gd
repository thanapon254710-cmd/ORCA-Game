
extends Area2D

@export var prompt_text: String = "E - Open IoT Question"
@export var puzzle_scene: PackedScene = preload("res://order_iot.tscn")

var prompt: Label
var puzzle_instance: Node = null


func _ready():
	collision_layer = 1
	collision_mask = 0
	monitoring = true

	prompt = Label.new()
	prompt.text = prompt_text
	prompt.position = Vector2(-65, -48)
	prompt.visible = false
	add_child(prompt)


func can_interact() -> bool:
	return not is_instance_valid(puzzle_instance)


func set_focused(value: bool):
	if is_instance_valid(prompt):
		prompt.visible = value and can_interact()


func interact(_player: Node):
	if not can_interact():
		return

	if puzzle_scene == null:
		push_error("IoT puzzle scene is not assigned!")
		return

	puzzle_instance = puzzle_scene.instantiate()
	get_tree().root.add_child(puzzle_instance)

	if puzzle_instance.has_signal("puzzle_closed"):
		puzzle_instance.puzzle_closed.connect(_on_puzzle_closed)


func _on_puzzle_closed():
	if is_instance_valid(puzzle_instance):
		puzzle_instance.queue_free()

	puzzle_instance = null

	if is_instance_valid(prompt):
		prompt.visible = false
