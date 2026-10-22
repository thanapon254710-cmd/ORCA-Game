
extends Node

# Shared game state for ORCA-Game.
# This node will be registered as an Autoload named "GameState".

signal floor_changed(new_floor: int)
signal question_answered(question_id: String, is_correct: bool)
signal player_caught
signal game_over(reason: String)

var current_floor: int = 5
var questions_answered: Array[String] = []
var game_is_over: bool = false


func change_floor(new_floor: int) -> void:
	if game_is_over:
		return

	if new_floor < 1 or new_floor > 5:
		push_warning("Invalid floor number: %d" % new_floor)
		return

	current_floor = new_floor
	floor_changed.emit(current_floor)


func mark_question_answered(question_id: String, is_correct: bool) -> void:
	if game_is_over:
		return

	if is_correct and not questions_answered.has(question_id):
		questions_answered.append(question_id)

	question_answered.emit(question_id, is_correct)


func catch_player() -> void:
	if game_is_over:
		return

	game_is_over = true
	player_caught.emit()
	game_over.emit("caught_by_orca")


func end_game(reason: String) -> void:
	if game_is_over:
		return

	game_is_over = true
	game_over.emit(reason)


func reset_game() -> void:
	current_floor = 5
	questions_answered.clear()
	game_is_over = false
