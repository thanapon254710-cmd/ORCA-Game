
extends CharacterBody2D

const SPEED = 200.0

# Interaction system
var nearby_interactables: Array[Node] = []
var focused_interactable: Node = null
var facing_direction: String = "down"

@onready var interact_area: Area2D = $InteractArea


func _ready() -> void:
	add_to_group("player")
	facing_direction = "down"
	$AnimatedSprite2D.play("Idle_down")
	interact_area.area_entered.connect(_on_area_entered)
	interact_area.area_exited.connect(_on_area_exited)


func _physics_process(_delta: float) -> void:
	# Existing player movement
	var direction = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
        "move_down"
	)

	velocity = direction * SPEED
	move_and_slide()

	# Update interaction focus
	_update_focus()
	update_animation(velocity)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if is_instance_valid(focused_interactable):
			if focused_interactable.has_method("interact"):
				focused_interactable.interact(self)
				get_viewport().set_input_as_handled()


# Find the interactable object
func _get_interactable(area: Area2D) -> Node:
	if area.has_method("interact"):
		return area

	var parent = area.get_parent()

	if parent and parent.has_method("interact"):
		return parent

	return null


# Detect nearby interactables
func _on_area_entered(area: Area2D) -> void:
	var obj = _get_interactable(area)

	if obj and obj not in nearby_interactables:
		nearby_interactables.append(obj)


# Stop detecting when leaving the interaction area
func _on_area_exited(area: Area2D) -> void:
	var obj = _get_interactable(area)

	if obj:
		nearby_interactables.erase(obj)

		if obj == focused_interactable:
			_set_focus(null)


# Find the closest usable object
func _update_focus() -> void:
	var best: Node = null
	var best_distance = INF

	for obj in nearby_interactables:
		if not is_instance_valid(obj):
			continue

		if obj.has_method("can_interact"):
			if not obj.can_interact():
				continue

		if not (obj is Node2D):
			continue

		var distance = global_position.distance_squared_to(
			obj.global_position
		)

		if distance < best_distance:
			best_distance = distance
			best = obj

	if best != focused_interactable:
		_set_focus(best)


# Change focused object
func _set_focus(obj: Node) -> void:
	if is_instance_valid(focused_interactable):
		if focused_interactable.has_method("set_focused"):
			focused_interactable.set_focused(false)

	focused_interactable = obj

	if is_instance_valid(focused_interactable):
		if focused_interactable.has_method("set_focused"):
			focused_interactable.set_focused(true)
			
func update_animation(direction: Vector2) -> void:
	var sprite: AnimatedSprite2D = $AnimatedSprite2D

	if direction == Vector2.ZERO:
		sprite.play("Idle_" + facing_direction)
		return

	if absf(direction.x) > absf(direction.y):
		if direction.x > 0:
			facing_direction = "right"
		else:
			facing_direction = "left"
	else:
		if direction.y > 0:
			facing_direction = "down"
		else:
			facing_direction = "up"

	sprite.play("Walk_" + facing_direction)
