extends Area2D

const WIRE_PUZZLE_SCENE = preload("res://wire_puzzle.tscn")
const QUESTION_ID = "q_4_408"

var prompt: Label
var wire_puzzle: CanvasLayer


func _ready():
	collision_layer = 1
	collision_mask = 0
	monitoring = true

	prompt = Label.new()
	prompt.text = "E - Repair Fuse Box"
	prompt.position = Vector2(-55, -48)
	prompt.visible = false
	add_child(prompt)


func can_interact() -> bool:
	return (
		not GameState.questions_answered.has(QUESTION_ID)
		and not is_instance_valid(wire_puzzle)
		and not GameState.game_is_over
	)


func set_focused(value: bool):
	if is_instance_valid(prompt):
		prompt.visible = value and can_interact()


func interact(_player: Node):
	if not can_interact():
		return

	wire_puzzle = WIRE_PUZZLE_SCENE.instantiate()
	get_tree().root.add_child(wire_puzzle)
	wire_puzzle.question_answered.connect(_on_puzzle_answered)


func _on_puzzle_answered(correct: bool):
	if correct:
		if not GameState.questions_answered.has(QUESTION_ID):
			GameState.questions_answered.append(QUESTION_ID)

		GameState.collect_passkey(4)
		set_focused(false)
