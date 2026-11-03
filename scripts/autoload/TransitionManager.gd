
extends CanvasLayer

# Maps floor numbers to their scene files.
const FLOOR_SCENES: Dictionary = {
	3: "res://scenes/floors/floor3.tscn",
	4: "res://scenes/floors/floor4.tscn",
	5: "res://scenes/floors/floor5.tscn"
}

@export var fade_duration: float = 0.4

var is_transitioning: bool = false
var fade_overlay: ColorRect


func _ready() -> void:
	# Keep this overlay above the game scenes.
	layer = 100

	# Create the full-screen black overlay.
	fade_overlay = ColorRect.new()
	fade_overlay.name = "FadeOverlay"
	fade_overlay.color = Color(0, 0, 0, 0)
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Make the overlay cover the entire screen.
	fade_overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	add_child(fade_overlay)


# Main function for changing floors.
func change_floor(
	target_floor: int,
	spawn_marker_name: String = "PlayerSpawn"
) -> void:

	# Prevent multiple transitions at once.
	if is_transitioning:
		return

	# Do not transition after game over.
	if GameState.game_is_over:
		return

	# Check whether the destination floor exists.
	if not FLOOR_SCENES.has(target_floor):
		push_error("Invalid destination floor: %d" % target_floor)
		return

	var scene_path: String = FLOOR_SCENES[target_floor]
	var packed_scene: PackedScene = load(scene_path) as PackedScene

	if packed_scene == null:
		push_error("Could not load floor scene: " + scene_path)
		return

	is_transitioning = true

	# Fade out.
	await _fade_to(1.0)

	# Change to the destination scene.
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
		push_error("The destination scene could not be found.")
		await _fade_to(0.0)
		is_transitioning = false
		return

	# Find the Player in the new floor.
	var player_node: Node = new_scene.find_child(
		"Player",
		true,
		false
	)

	# Find the destination spawn marker.
	var spawn_node: Node = new_scene.find_child(
		spawn_marker_name,
		true,
		false
	)

	# Move the Player to the spawn marker.
	if player_node is Node2D and spawn_node is Marker2D:
		var player: Node2D = player_node as Node2D
		var spawn: Marker2D = spawn_node as Marker2D

		player.global_position = spawn.global_position
	else:
		push_warning(
			"Player or spawn marker not found. "
			+ "Check the destination scene."
		)

	# Update the global floor state.
	GameState.change_floor(target_floor)

	# Fade in.
	await _fade_to(0.0)

	is_transitioning = false


# Fades the screen to the requested alpha value.
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
