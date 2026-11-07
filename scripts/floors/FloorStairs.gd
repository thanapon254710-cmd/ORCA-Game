extends Area2D

# Destination floor number.
@export_range(1, 5, 1) var target_floor: int = 4

# Name of the spawn marker in the destination floor.
@export var destination_spawn_marker: String = ""

@export var prompt_text: String = "Press E to use stairs"

@export var stair_puzzle_scene: PackedScene

var stair_puzzle: CanvasLayer = null

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

	# Check all four passkeys first.
	if target_floor == 3 and not GameState.has_all_passkeys():
		var popup := AcceptDialog.new()
		popup.add_to_group("question_box")
		popup.title = "Gate Locked"
		popup.dialog_text = "Four passkeys are required to unlock this gate."

		get_tree().root.add_child(popup)
		popup.confirmed.connect(func(): popup.queue_free())
		popup.canceled.connect(func(): popup.queue_free())
		popup.popup_centered()
		return

	# Open the existing French symbol puzzle.
	if target_floor == 3:
		if is_instance_valid(stair_puzzle):
			return

		if stair_puzzle_scene == null:
			push_error("Stair puzzle scene is not assigned!")
			return

		stair_puzzle = stair_puzzle_scene.instantiate()
		get_tree().root.add_child(stair_puzzle)

		stair_puzzle.question_answered.connect(
			_on_stair_puzzle_answered
		)

		return

	# Normal stairs to other floors.
	TransitionManager.change_floor(
		target_floor,
		destination_spawn_marker
	)

func _on_stair_puzzle_answered(correct: bool) -> void:
	if not correct:
		return

	if target_floor == 3:
		TransitionManager.change_floor(
			target_floor,
			destination_spawn_marker
		)
