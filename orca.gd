extends CharacterBody2D

signal player_caught
signal state_changed(new_state: int)   # Signal for sound/VFX state triggers

enum State { PATROL, CHASE, RETURN }

@export var speed: float = 100.0
@export var chase_multiplier: float = 1.5     # Speed multiplier when chasing
@export var lose_sight_time: float = 1.5      # Time before giving up chase after losing sight (seconds)
@export var path_follow: PathFollow2D
@export var sight_range: float = 200.0
@export_range(10, 180) var sight_angle: float = 90.0
@export var debug_draw: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var vision: RayCast2D = $Vision

var state: State = State.PATROL
var has_caught := false
var facing := Vector2.RIGHT
var player: Node2D
var last_seen_pos := Vector2.ZERO
var lose_timer := 0.0

func _ready() -> void:
	# Automatically checks for either HitBox or Area2D collision nodes
	if has_node("HitBox"):
		$HitBox.body_entered.connect(_on_hitbox_body_entered)
	elif has_node("Area2D"):
		$Area2D.body_entered.connect(_on_hitbox_body_entered)
		
	if path_follow:
		global_position = path_follow.global_position

func _physics_process(delta: float) -> void:
	if path_follow == null:
		return
	match state:
		State.PATROL:
			_patrol(delta)
		State.CHASE:
			_chase(delta)
		State.RETURN:
			_return_to_path(delta)
	_update_visual()

# ---------- STATE: PATROL (Walk along Path2D) ----------
func _patrol(delta: float) -> void:
	var old_pos := global_position
	path_follow.progress += speed * delta
	global_position = path_follow.global_position
	_face(global_position - old_pos)

	if can_see_player():
		_change_state(State.CHASE)

# ---------- STATE: CHASE (Pursue Player) ----------
func _chase(delta: float) -> void:
	if can_see_player():
		last_seen_pos = player.global_position   # Store last seen position
		lose_timer = lose_sight_time
	else:
		lose_timer -= delta
		if lose_timer <= 0.0:
			_change_state(State.RETURN)
			return

	# Move towards the last known player position
	var to_target := last_seen_pos - global_position
	if to_target.length() > 4.0:
		velocity = to_target.normalized() * speed * chase_multiplier
		move_and_slide()   # Slide along walls without passing through
		_face(velocity)
	else:
		velocity = Vector2.ZERO   # Reached last seen point, wait and observe

# ---------- STATE: RETURN (Return to Patrol Path) ----------
func _return_to_path(delta: float) -> void:
	if can_see_player():
		_change_state(State.CHASE)
		return

	var target := path_follow.global_position
	var to_target := target - global_position
	if to_target.length() <= speed * delta:
		global_position = target
		_change_state(State.PATROL)
		return

	velocity = to_target.normalized() * speed
	move_and_slide()
	_face(velocity)

# ---------- State Machine Handling ----------
func _change_state(new_state: State) -> void:
	if new_state == state:
		return
	state = new_state

	match state:
		State.CHASE:
			if player:
				last_seen_pos = player.global_position
			lose_timer = lose_sight_time
		State.RETURN:
			_snap_guide_to_nearest_point()

	print("Orca → ", State.keys()[state])
	state_changed.emit(state)

# Snap path_follow progress to the closest point on the curve relative to Orca
func _snap_guide_to_nearest_point() -> void:
	if path_follow and path_follow.get_parent() is Path2D:
		var path := path_follow.get_parent() as Path2D
		var local_pos := path.to_local(global_position)
		path_follow.progress = path.curve.get_closest_offset(local_pos)

# ---------- Helper Functions ----------
func _face(dir: Vector2) -> void:
	if dir.length() > 0.01:
		facing = dir.normalized()
		if absf(dir.x) > 0.01:
			sprite.flip_h = dir.x > 0  

func _update_visual() -> void:
	match state:
		State.PATROL:
			sprite.modulate = Color.WHITE
		State.CHASE:
			sprite.modulate = Color.RED
		State.RETURN:
			sprite.modulate = Color.ORANGE
	queue_redraw()

func can_see_player() -> bool:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			return false

	var to_player := player.global_position - global_position

	# Condition 1: Within distance range?
	if to_player.length() > sight_range:
		return false

	# Condition 2: Within vision cone angle?
	var angle := absf(rad_to_deg(facing.angle_to(to_player)))
	if angle > sight_angle / 2.0:
		return false

	# Condition 3: Line of sight blocked by wall?
	vision.target_position = vision.to_local(player.global_position)
	vision.force_raycast_update()
	return vision.get_collider() == player

func _draw() -> void:
	if not debug_draw:
		return
	var base_angle := facing.angle()
	var half := deg_to_rad(sight_angle / 2.0)
	var points := PackedVector2Array([Vector2.ZERO])
	for i in range(11):
		var a := base_angle - half + (half * 2.0) * i / 10.0
		points.append(Vector2.RIGHT.rotated(a) * sight_range)
	var cone_color := Color(1, 0, 0, 0.25) if state == State.CHASE else Color(1, 1, 0, 0.25)
	draw_colored_polygon(points, cone_color)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if has_caught:
		return
	if body.is_in_group("player"):
		has_caught = true
		print("Player caught!")
		player_caught.emit()
