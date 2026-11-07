
extends Area2D

const HINT_IMAGE = preload("res://assets/sprites/408_hint.png")

var prompt: Label
var hint_layer: CanvasLayer


func _ready():
	collision_layer = 1
	collision_mask = 0
	monitoring = true

	set_process_unhandled_input(true)

	prompt = Label.new()
	prompt.text = "E - View Hint"
	prompt.position = Vector2(-45, -48)
	prompt.visible = false
	add_child(prompt)


func can_interact() -> bool:
	return not is_instance_valid(hint_layer)


func set_focused(value: bool):
	if is_instance_valid(prompt):
		prompt.visible = value and can_interact()


func interact(_player: Node):
	if not can_interact():
		return

	hint_layer = CanvasLayer.new()
	get_tree().root.add_child(hint_layer)

	# Dark background
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.85)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hint_layer.add_child(background)

	# Hint image
	var image = TextureRect.new()
	image.texture = HINT_IMAGE
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	hint_layer.add_child(image)

	# Close button
	var close_button = Button.new()
	close_button.text = "Close (Esc)"
	close_button.position = Vector2(20, 20)
	close_button.pressed.connect(close_hint)
	hint_layer.add_child(close_button)


func _unhandled_input(event):
	if is_instance_valid(hint_layer):
		if event.is_action_pressed("ui_cancel"):
			close_hint()
			get_viewport().set_input_as_handled()


func close_hint():
	if is_instance_valid(hint_layer):
		hint_layer.queue_free()
		hint_layer = null
