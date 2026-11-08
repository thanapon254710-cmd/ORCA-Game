
extends Node

# Shared game state for ORCA-Game.
# This node will be registered as an Autoload named "GameState".

signal floor_changed(new_floor: int)
signal question_answered(question_id: String, is_correct: bool)
signal player_caught
signal game_over(reason: String)

var room407_intro_seen: bool = false
var floor5_intro_seen: bool = false

var floor_dialogues_seen: Dictionary = {}

var current_floor: int = 5
var questions_answered: Array[String] = []
var game_is_over: bool = false
var room408_powered: bool = false

# Floor 4 passkey progress
var pk1_collected: bool = false
var pk2_collected: bool = false
var pk3_collected: bool = false
var pk4_collected: bool = false

# Gate unlock progress
var floor2_gate_unlocked: bool = false
var floor3_gate_unlocked: bool = false
var floor4_gate_unlocked: bool = false

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
	floor_dialogues_seen.clear()
	room407_intro_seen = false
	floor5_intro_seen = false
	Inventory.reset_inventory()
	current_floor = 5
	questions_answered.clear()
	game_is_over = false
	room408_powered = false
	pk1_collected = false
	pk2_collected = false
	pk3_collected = false
	pk4_collected = false
	floor2_gate_unlocked = false
	floor3_gate_unlocked = false
	floor4_gate_unlocked = false

func has_all_passkeys() -> bool:
	return (
		pk1_collected
		and pk2_collected
		and pk3_collected
		and pk4_collected
	)

func collect_passkey(number: int) -> void:
	var symbol := ""
	var message := ""

	match number:
		1:
			if pk1_collected:
				return
			pk1_collected = true
			symbol = "⇑"

		2:
			if pk2_collected:
				return
			pk2_collected = true
			symbol = "⊡"

		3:
			if pk3_collected:
				return
			pk3_collected = true
			symbol = "✧"

		4:
			if pk4_collected:
				return
			pk4_collected = true
			symbol = "☾"

		_:
			push_warning("Invalid passkey number!")
			return

	message = "Passkey %s Acquired!" % [symbol]

	var popup := AcceptDialog.new()
	popup.title = "Passkey Acquired"
	popup.dialog_text = message
	get_tree().root.add_child(popup)
	popup.confirmed.connect(func(): popup.queue_free())
	popup.canceled.connect(func(): popup.queue_free())
	popup.popup_centered()

func has_all_ft2_books() -> bool:
	return (
		Inventory.get_count("book_white") >= 6
		and Inventory.get_count("book_blue") >= 6
		and Inventory.get_count("book_orange") >= 3
	)

func finish_story() -> void:
	var error := get_tree().change_scene_to_file("res://scenes/ui/ending.tscn")
	if error != OK:
		push_error("Could not load ending: " + error_string(error))
