
extends Area2D

@export var question_id: String

var question_data: Dictionary = {}
var question_ui: CanvasLayer
var prompt: Label


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0

	# Detect the player's interaction area.
	collision_mask = 2

	_load_question()

	# Interaction prompt.
	prompt = Label.new()
	prompt.text = "E - Interact"
	prompt.position = Vector2(-35, -45)
	prompt.visible = false
	add_child(prompt)


func _load_question() -> void:
	var file = FileAccess.open(
		"res://data/questions.json",
		FileAccess.READ
	)

	if file == null:
		push_error("Cannot load questions.json")
		return

	var data = JSON.parse_string(file.get_as_text())

	for question in data.get("questions", []):
		if question.get("id") == question_id:
			question_data = question
			return

	push_error("Question not found: " + question_id)


func can_interact() -> bool:
	return (
		not question_data.is_empty()
		and not GameState.questions_answered.has(question_id)
	)


func set_focused(value: bool) -> void:
	if is_instance_valid(prompt):
		prompt.visible = value and can_interact()


func interact(_player: Node) -> void:
	if not can_interact():
		return

	_show_question()


func _show_question() -> void:
	if question_ui:
		return

	question_ui = CanvasLayer.new()
	get_tree().root.add_child(question_ui)

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-250, -170)
	panel.size = Vector2(500, 340)
	question_ui.add_child(panel)

	var layout = VBoxContainer.new()
	panel.add_child(layout)

	var title = Label.new()
	title.text = question_data.get("subject", "Question")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)

	var question_label = Label.new()
	question_label.text = question_data.get("question", "")
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(question_label)

	if question_data.get("type") == "multiple_choice":
		for choice in question_data.get("choices", []):
			var button = Button.new()
			button.text = str(choice)
			button.pressed.connect(
				_submit_answer.bind(str(choice))
			)
			layout.add_child(button)

	elif question_data.get("type") == "text_input":
		var answer_input = LineEdit.new()
		answer_input.placeholder_text = "Enter your answer"
		layout.add_child(answer_input)

		var submit_button = Button.new()
		submit_button.text = "Submit"
		submit_button.pressed.connect(
			_submit_text.bind(answer_input)
		)
		layout.add_child(submit_button)


func _submit_text(answer_input: LineEdit) -> void:
	_submit_answer(answer_input.text)


func _submit_answer(answer: String) -> void:
	var correct_answer = str(
		question_data.get("correct_answer", "")
	).strip_edges()

	var is_correct = (
		answer.strip_edges().to_lower()
		== correct_answer.to_lower()
	)

	GameState.mark_question_answered(
		question_id,
		is_correct
	)

	if is_correct:
		print("Correct! ", question_id)
		question_ui.queue_free()
		question_ui = null
		set_focused(false)
	else:
		print("Incorrect! Try again.")
