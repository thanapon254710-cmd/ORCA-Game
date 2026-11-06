extends Area2D

# Destination floor number.
@export_range(1, 5, 1) var target_floor: int = 4

# Name of the spawn marker in the destination floor.
@export var destination_spawn_marker: String = ""

@export var prompt_text: String = "Press E to use stairs"

var prompt: Label


func _ready() -> void:
	# Create the interaction prompt.
	prompt = Label.new()
	prompt.name = "Prompt"
	prompt.text = prompt_text
	prompt.position = Vector2(-65, -55)
	prompt.z_index = 10
	prompt.visible = false
	add_child(prompt)


# Check whether these stairs can be used.
func can_interact() -> bool:
	return (
		not destination_spawn_marker.is_empty()
		and not TransitionManager.is_transitioning
		and not GameState.game_is_over
	)


# Show or hide the interaction prompt.
func set_focused(on: bool) -> void:
	if is_instance_valid(prompt):
		prompt.visible = on


# Called when the player presses E.
func interact(_player: Node) -> void:
	if not can_interact():
		return

	TransitionManager.change_floor(
		target_floor,
		destination_spawn_marker
	)
