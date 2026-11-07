extends Area2D
## Place this scene in a floor, then choose Item Id in the Inspector.
@export_enum("key_yellow", "key_blue", "key_purple", "key_gold", "book_blue", "book_white", "book_orange") var item_id: String = "key_yellow"
## Optional unique ID. Otherwise floor scene path + node path identify this pickup.
@export var pickup_id: String = ""
var _saved_id: String

func _ready() -> void:
	var scene: Node = get_tree().current_scene
	if not pickup_id.is_empty():
		_saved_id = pickup_id
	elif scene != null:
		_saved_id = scene.scene_file_path + ":" + str(scene.get_path_to(self))
	else:
		_saved_id = str(get_path())
	$Prompt.text = "E - Pick up " + str(Inventory.ITEM_NAMES.get(item_id, item_id))
	Inventory.changed.connect(_sync_collected)
	_sync_collected()

func _sync_collected() -> void:
	visible = not Inventory.was_collected(_saved_id)
	$Prompt.hide()

func can_interact() -> bool:
	return not GameState.game_is_over and not Inventory.was_collected(_saved_id)

func set_focused(value: bool) -> void:
	$Prompt.visible = value and can_interact()
	$Visual.modulate = Color(1.25, 1.25, 1.25) if value else Color.WHITE

func interact(player: Node) -> void:
	if not can_interact() or not player.is_in_group("player"):
		return
	# Same reach as the player's existing InteractArea, with a wall check.
	if player.global_position.distance_to(global_position) > 90.0:
		return
	var ray := PhysicsRayQueryParameters2D.create(player.global_position, global_position, 1)
	ray.collide_with_areas = false
	if player is CollisionObject2D:
		ray.exclude = [player.get_rid()]
	if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
		return
	Inventory.collect(item_id, _saved_id)
