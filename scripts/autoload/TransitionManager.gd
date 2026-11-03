extends CanvasLayer

# Maps floor numbers to their scene files.
const FLOOR_SCENES: Dictionary = {
	5: "res://scenes/floors/floor5.tscn",
	4: "res://scenes/floors/floor4.tscn",
	3: "res://scenes/floors/floor3.tscn",
	2: "res://scenes/floors/floor2.tscn",
	1: "res://scenes/floors/floor1.tscn",
}

# Maps the scene where the Player dies to the respawn floor.
const RESPAWN_FLOORS_BY_SCENE: Dictionary = {
	"res://scenes/floors/floor5.tscn": 5,
	"res://scenes/floors/floor4.tscn": 4,
	"res://scenes/room/room407.tscn": 4,
	"res://scenes/room/room408.tscn": 4,
	"res://scenes/floors/floor3.tscn": 3,
	"res://scenes/floors/floor2.tscn": 2
}

@export var fade_duration: float = 0.4

var is_transitioning: bool = false
var fade_overlay: ColorRect


func _ready() -> void:
	layer = 100

	fade_overlay = ColorRect.new()
	fade_overlay.name = "FadeOverlay"
	fade_overlay.color = Color(0, 0, 0, 0)
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	fade_overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	add_child(fade_overlay)


# Stair transition.
func change_floor(
	target_floor: int,
	spawn_marker_name: String
) -> void:

	if is_transitioning:
		return

	if GameState.game_is_over:
		return

	if not FLOOR_SCENES.has(target_floor):
		push_error("Invalid destination floor: %d" % target_floor)
		return

	await _transition_to_floor(
		target_floor,
		spawn_marker_name,
		false
	)


# Respawn after the Player dies.
func respawn_player() -> void:

	if is_transitioning:
		return

	var current_scene: Node = get_tree().current_scene

	if current_scene == null:
		push_error("Cannot respawn: current scene is missing.")
		return

	var current_scene_path: String = current_scene.scene_file_path

	if not RESPAWN_FLOORS_BY_SCENE.has(current_scene_path):
		push_error(
            "No respawn destination configured for: "
			+ current_scene_path
		)
		return

	var destination_floor: int = RESPAWN_FLOORS_BY_SCENE[
		current_scene_path
	]

	await _transition_to_floor(
		destination_floor,
		"PlayerSpawn",
		true
	)


# Shared transition function for stairs and respawning.
func _transition_to_floor(
	target_floor: int,
	spawn_marker_name: String,
	is_respawn: bool
) -> void:

	if is_transitioning:
		return

	var scene_path: String = FLOOR_SCENES[target_floor]
	var packed_scene: PackedScene = load(scene_path) as PackedScene

	if packed_scene == null:
		push_error("Could not load floor scene: " + scene_path)
		return

	is_transitioning = true

	# Fade out.
	await _fade_to(1.0)

	# Change scene.
	var change_error: Error = get_tree().change_scene_to_packed(
		packed_scene
	)

	if change_error != OK:
		push_error("Failed to change floor scene.")
		await _fade_to(0.0)
		is_transitioning = false
		return

	# Wait until the new scene is ready.
	await get_tree().scene_changed

	var new_scene: Node = get_tree().current_scene

	if new_scene == null:
		push_error("Destination scene could not be found.")
		await _fade_to(0.0)
		is_transitioning = false
		return

	# Find Player.
	var player_node: Node = new_scene.find_child(
		"Player",
		true,
		false
	)

	# Find spawn marker.
	var spawn_node: Node = new_scene.find_child(
		spawn_marker_name,
		true,
		false
	)

	# Move Player to spawn position.
	if player_node is Node2D and spawn_node is Marker2D:
		var player: Node2D = player_node as Node2D
		var spawn: Marker2D = spawn_node as Marker2D

		player.global_position = spawn.global_position
	else:
		push_warning(
            "Player or spawn marker not found. "
			+ "Check the destination scene."
		)

	# Allow gameplay again after a successful respawn.
	if is_respawn:
		GameState.game_is_over = false

	# Update global floor state.
	GameState.change_floor(target_floor)

	# Fade in.
	await _fade_to(0.0)

	is_transitioning = false


# Fade screen to the requested alpha.
func _fade_to(target_alpha: float) -> void:

	var target_color := Color(0, 0, 0, target_alpha)

	var tween: Tween = create_tween()

	tween.tween_property(
		fade_overlay,
		"color",
		target_color,
		fade_duration
	)

	await tween.finished
