
extends Area2D

@export_range(0, 100, 1) var question_index: int = 0

const QUESTIONS_PATH = "res://questions.json"
const TARGET_FLOOR = 5

var question_id: String = ""
var question_data: Dictionary = {}
var question_ui: CanvasLayer = null
var prompt: Label = null


# --------------------------------------------------
# INITIALIZATION
# --------------------------------------------------

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0

	monitoring = true
	monitorable = true

	_load_question()

	prompt = Label.new()
	prompt.text = "E - Interact"
	prompt.position = Vector2(-35, -45)
	prompt.visible = false
	add_child(prompt)


# --------------------------------------------------
# LOAD QUESTION FROM QUESTIONS.JSON
# --------------------------------------------------

func _load_question() -> void:

	if not FileAccess.file_exists(QUESTIONS_PATH):
		push_error("questions.json not found!")
		return

	var file = FileAccess.open(
		QUESTIONS_PATH,
		FileAccess.READ
	)

	if file == null:
		push_error("Cannot open questions.json!")
		return

	var parsed = JSON.parse_string(file.get_as_text())

	if not parsed is Dictionary:
		push_error("Invalid questions.json structure!")
		return

	var floor_questions: Array = []

	for question in parsed.get("questions", []):
		if question.get("floor", -1) == TARGET_FLOOR:
			floor_questions.append(question)

	if question_index >= floor_questions.size():
		push_error(
            "Question index %d does not exist on Floor %d. Found %d questions."
			% [
				question_index,
				TARGET_FLOOR,
				floor_questions.size()
			]
		)
		return

	question_data = floor_questions[question_index]

	question_id = str(
		question_data.get("id", "")
	)

	print(
        "Loaded question: %s (ID: %s)"
		% [
			question_data.get("subject", ""),
			question_id
		]
	)


# --------------------------------------------------
# PLAYER INTERACTION
# --------------------------------------------------

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


# --------------------------------------------------
# DISPLAY QUESTION UI
# --------------------------------------------------

func _show_question() -> void:

	if is_instance_valid(question_ui):
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

	# Question subject

	var title = Label.new()
	title.text = str(
		question_data.get("subject", "Question")
	)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	layout.add_child(title)

	# Question description

	var question_label = Label.new()
	question_label.text = str(
		question_data.get("question", "")
	)
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	layout.add_child(question_label)

	# Determine question type

	var question_type = str(
		question_data.get("type", "")
	)

	# MULTIPLE CHOICE

	if question_type == "multiple_choice":

		for choice in question_data.get("choices", []):

			var button = Button.new()
			button.text = str(choice)

			button.pressed.connect(
				_submit_answer.bind(str(choice))
			)

			layout.add_child(button)

	# SINGLE TEXT INPUT

	elif question_type == "text_input":

		var answer_input = LineEdit.new()
		answer_input.placeholder_text = "Enter your answer"

		layout.add_child(answer_input)

		var submit_button = Button.new()
		submit_button.text = "Submit"

		submit_button.pressed.connect(
			_submit_text.bind(answer_input)
		)

		layout.add_child(submit_button)

	# DOUBLE TEXT INPUT

	elif question_type == "text_input_double":

		var answer_a = LineEdit.new()
		answer_a.placeholder_text = "Enter A"

		layout.add_child(answer_a)

		var answer_b = LineEdit.new()
		answer_b.placeholder_text = "Enter B"

		layout.add_child(answer_b)

		var submit_button = Button.new()
		submit_button.text = "Submit"

		submit_button.pressed.connect(
			_submit_double.bind(answer_a, answer_b)
		)

		layout.add_child(submit_button)

	# UNSUPPORTED QUESTION TYPE

	else:

		push_error(
			"Unsupported question type: " + question_type
		)


# --------------------------------------------------
# SUBMIT SINGLE TEXT ANSWER
# --------------------------------------------------

func _submit_text(answer_input: LineEdit) -> void:

	_submit_answer(answer_input.text)


# --------------------------------------------------
# SUBMIT DOUBLE TEXT ANSWER
# --------------------------------------------------

func _submit_double(
	answer_a: LineEdit,
	answer_b: LineEdit
) -> void:

	var combined_answer = (
		answer_a.text.strip_edges()
		+ ", "
		+ answer_b.text.strip_edges()
	)

	_submit_answer(combined_answer)


# --------------------------------------------------
# CHECK ANSWER
# --------------------------------------------------

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

		if is_instance_valid(question_ui):
			question_ui.queue_free()

		question_ui = null

		set_focused(false)

	else:

		print("Incorrect! Try again.")
