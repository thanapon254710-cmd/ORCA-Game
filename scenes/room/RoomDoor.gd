extends Area2D

@export var destination_scene: String = ""
@export var destination_spawn_marker: String = ""

@export var prompt_text: String = "Press E to enter"

var prompt: Label


func _ready() -> void:

	prompt = Label.new()
	prompt.name = "Prompt"
	prompt.text = prompt_text
	prompt.position = Vector2(-65, -55)
	prompt.z_index = 10
	prompt.visible = false

	add_child(prompt)


func can_interact() -> bool:

	return (
		not destination_scene.is_empty()
		and not TransitionManager.is_transitioning
		and not GameState.game_is_over
	)


func set_focused(on: bool) -> void:

	if is_instance_valid(prompt):
		prompt.visible = on


func interact(_player: Node) -> void:

	if not can_interact():
		return

	var target_scene = destination_scene

	# Check if Room 408 has been powered
	if destination_scene == "res://scenes/room/room408.tscn":
		if GameState.room408_powered:
			target_scene = "res://scenes/room/room408เปิดไฟ.tscn"

	TransitionManager.change_scene_to_room(
		target_scene,
		destination_spawn_marker
	)
