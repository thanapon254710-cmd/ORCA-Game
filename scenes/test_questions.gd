
extends Node2D

func _ready() -> void:
	var file := FileAccess.open("res://data/questions.json", FileAccess.READ)

	if file == null:
		push_error("Could not open questions.json")
		return

	var json_text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_text)

	if parsed == null or not parsed is Dictionary:
		push_error("questions.json is invalid JSON or has the wrong format")
		return

	var questions = parsed.get("questions", [])

	if not questions is Array:
		push_error("'questions' must be an array")
		return

	print("Question data loaded successfully: ", questions.size(), " questions")

	for question in questions:
		if not question is Dictionary:
			push_error("A question entry is not an object")
			return

		for field in ["id", "floor", "subject", "type", "question", "choices", "correct_answer"]:
			if not question.has(field):
				push_error("Question is missing field: " + field)
				return

	print("All question entries contain the required fields.")
