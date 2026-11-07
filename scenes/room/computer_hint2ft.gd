
extends Area2D

@export var prompt_text: String = "E - Open Computer"
@export var puzzle_scene: PackedScene = preload("res://order_iot.tscn")

const QUESTION_ID = "q_2_esp32_order"
const HINT_IMAGE_PATH = "res://data/picture/bookshelf.png"

var prompt: Label
var puzzle_instance: Node = null
var hint_layer: CanvasLayer = null


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
	return (
		not is_instance_valid(puzzle_instance)
		and not is_instance_valid(hint_layer)
	)


func set_focused(value: bool):
	if is_instance_valid(prompt):
		prompt.visible = value and can_interact()


func interact(_player: Node):
	if not can_interact():
		return

	# If IoT was already completed, show only the hint.
	if GameState.questions_answered.has(QUESTION_ID):
		show_hint_only()
		return

	# First interaction: open IoT puzzle.
	if puzzle_scene == null:
		push_error("IoT puzzle scene is not assigned!")
		return

	puzzle_instance = puzzle_scene.instantiate()
	get_tree().root.add_child(puzzle_instance)

	if puzzle_instance.has_signal("puzzle_closed"):
		puzzle_instance.puzzle_closed.connect(_on_puzzle_closed)


func show_hint_only() -> void:
	var texture = load(HINT_IMAGE_PATH)

	if texture == null:
		push_error("Could not load bookshelf.png!")
		return

	hint_layer = CanvasLayer.new()
	get_tree().root.add_child(hint_layer)

	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.85)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hint_layer.add_child(background)

	var image = TextureRect.new()
	image.texture = texture
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hint_layer.add_child(image)

	await get_tree().create_timer(3.0).timeout

	if is_instance_valid(hint_layer):
		hint_layer.queue_free()

	hint_layer = null


func _on_puzzle_closed():
	if is_instance_valid(puzzle_instance):
		puzzle_instance.queue_free()

	puzzle_instance = null

	if is_instance_valid(prompt):
		prompt.visible = false
