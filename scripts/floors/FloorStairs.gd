
extends Area2D

# Destination floor number.
@export_range(3, 5, 1) var target_floor: int = 4

# Name of the spawn marker in the destination floor.
@export var destination_spawn_marker: String = "PlayerSpawn"

var player_inside: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = false


func _unhandled_input(event: InputEvent) -> void:
	if not player_inside:
		return

	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()

		TransitionManager.change_floor(
			target_floor,
			destination_spawn_marker
		)
