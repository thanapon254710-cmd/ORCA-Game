extends CharacterBody2D

signal player_caught
signal state_changed(new_state: int)

enum State { PATROL, CHASE, RETURN }

@export var speed: float = 100.0
@export var chase_multiplier: float = 1.8
@export var lose_sight_time: float = 2.0
@export var path_follow: PathFollow2D
@export var sight_range: float = 220.0
@export_range(10, 180) var sight_angle: float = 100.0
@export var debug_draw: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var vision: RayCast2D = $Vision

# ---------- Audio Nodes ----------
@onready var sfx_detect: AudioStreamPlayer2D = $SfxDetect if has_node("SfxDetect") else null

var state: State = State.PATROL
var has_caught := false
var facing := Vector2.RIGHT
var player: Node2D
var last_seen_pos := Vector2.ZERO
var return_stuck_timer := 0.0
var state_timer := 0.0 # ตัวแปรหน่วงเวลาป้องกัน State สลับรัวๆ

func _ready() -> void:
	has_caught = false
	state = State.PATROL
	
	if path_follow == null:
		if get_parent() is PathFollow2D:
			path_follow = get_parent() as PathFollow2D
		elif has_node("../PathFollow2D"):
			path_follow = get_node("../PathFollow2D") as PathFollow2D

	if has_node("HitBox"):
		$HitBox.body_entered.connect(_on_hitbox_body_entered)
	elif has_node("Area2D"):
		$Area2D.body_entered.connect(_on_hitbox_body_entered)
		
	if path_follow:
		global_position = path_follow.global_position

func _physics_process(delta: float) -> void:
	if has_caught:
		return
		
	state_timer += delta

	match state:
		State.PATROL:
			_patrol(delta)
		State.CHASE:
			_chase(delta)
		State.RETURN:
			_return_to_path(delta)
	_update_visual()

# ---------- STATE: PATROL ----------
func _patrol(delta: float) -> void:
	if path_follow == null:
		return

	# ต้องอยู่ใน PATROL อย่างน้อย 0.15 วินาที ก่อนจะเริ่มไล่ใหม่ เพื่อตัดลูปสลับรัว
	if state_timer >= 0.15 and can_see_player():
		_change_state(State.CHASE)
		return

	var old_pos := global_position
	path_follow.progress += speed * delta
	global_position = path_follow.global_position

	var move := global_position - old_pos
	if move.length() > 0.01:
		_face(move)

# ---------- STATE: CHASE ----------
func _chase(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")

	# 1. หาก Player เข้า Safe Zone (is_hiding = true) ให้ยกเลิกการไล่ล่าและถอยกลับทันที (ไม่รอ 0.2 วิ)
	if player and "is_hiding" in player and player.is_hiding:
		_change_state(State.RETURN)
		return

	# 2. หากคลาดสายตาทั่วไป (เช่น หลบหลังกำแพง) ให้หน่วง 0.2 วิ ตัดอาการสั่นรัว
	if player == null or not can_see_player():
		if state_timer >= 0.2:
			_change_state(State.RETURN)
			return

	if can_see_player():
		last_seen_pos = player.global_position

	var to_target := last_seen_pos - global_position
	if to_target.length() > 5.0:
		var target_dir := to_target.normalized()
		var move_velocity := target_dir * (speed * chase_multiplier)
		
		if is_on_wall():
			var wall_n := get_wall_normal().normalized()
			if wall_n.length() > 0.0:
				move_velocity = move_velocity.slide(wall_n)
				
		velocity = move_velocity
		move_and_slide()
		
		if velocity.length() > 5.0:
			_face(velocity)
	else:
		velocity = Vector2.ZERO

# ---------- STATE: RETURN ----------
func _return_to_path(delta: float) -> void:
	# ถ้าอยู่ใน RETURN เกิน 0.2 วินาทีแล้วมองเห็น Player ชัดเจน จึงสลับกลับ CHASE
	if state_timer >= 0.2 and can_see_player():
		_change_state(State.CHASE)
		return

	if path_follow == null:
		_change_state(State.PATROL)
		return

	path_follow.progress += speed * delta
	return_stuck_timer += delta

	var target := path_follow.global_position
	var to_target := target - global_position
	
	# ปรับเงื่อนไขให้เข้าใกล้และต้องอยู่สถานะ RETURN มาแล้วอย่างน้อย 0.2 วินาที
	if (to_target.length() <= 16.0 and state_timer >= 0.2) or return_stuck_timer >= 1.5:
		global_position = target
		_change_state(State.PATROL)
		return

	var target_dir := to_target.normalized()
	var move_velocity := target_dir * speed
	
	if is_on_wall():
		var wall_n := get_wall_normal().normalized()
		if wall_n.length() > 0.0:
			move_velocity = move_velocity.slide(wall_n)
			
	velocity = move_velocity
	move_and_slide()
	
	if velocity.length() > 5.0:
		_face(velocity)

# ---------- State Machine Handling ----------
func _change_state(new_state: State) -> void:
	if new_state == state:
		return
	state = new_state
	state_timer = 0.0 # รีเซ็ตเวลาสะสมทุกครั้งที่เปลี่ยนสถานะ

	match state:
		State.PATROL:
			pass
		State.CHASE:
			if player == null:
				player = get_tree().get_first_node_in_group("player")
			if player:
				last_seen_pos = player.global_position
				_face((player.global_position - global_position).normalized())
			
			if sfx_detect and sfx_detect.has_method("play"):
				sfx_detect.play()
				
		State.RETURN:
			return_stuck_timer = 0.0
			_snap_guide_to_nearest_point()

	print("Orca → ", State.keys()[state])
	state_changed.emit(state)

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

	if "is_hiding" in player and player.is_hiding:
		return false

	var to_player := player.global_position - global_position

	if to_player.length() > sight_range:
		return false

	var angle := absf(rad_to_deg(facing.angle_to(to_player)))
	if angle > sight_angle / 2.0:
		return false

	vision.target_position = vision.to_local(player.global_position)
	vision.add_exception(self)
	
	# ปิดการชน Area2D อื่นๆ ชนเฉพาะ Physics Body (ผู้เล่น/กำแพง)
	vision.collide_with_areas = false
	vision.collide_with_bodies = true
	vision.force_raycast_update()
	
	var collider := vision.get_collider()
	return collider == null or collider == player or collider.is_in_group("player")

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

# ---------- HitBox Trigger ----------
func _on_hitbox_body_entered(body: Node2D) -> void:
	if has_caught:
		return
	if body.is_in_group("player"):
		# 3. หากผู้เล่นกำลังซ่อนตัวอยู่ ห้ามจับเด็ดขาด!
		if "is_hiding" in body and body.is_hiding:
			return
			
		has_caught = true
		print("Player caught!")
		player_caught.emit()
