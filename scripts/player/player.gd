extends CharacterBody2D

const SPEED = 200.0

# ---------- HEARTBEAT PROXIMITY SETTINGS ----------
@export var max_hear_distance: float = 600.0 # ระยะห่างเริ่มได้ยินเสียงหัวใจเต้น (ยิ่งใกล้ยิ่งดัง)
@export var min_db: float = -15.0            # ความดังต่ำสุดเมื่ออยู่ขอบระยะ (dB)
@export var max_db: float = 6.0              # ความดังสูงสุดเมื่อ Orca ประชิดตัว (dB)

@onready var heartbeat_stream: AudioStreamPlayer = $HeartbeatStream if has_node("HeartbeatStream") else null

var orca: Node2D

# ---------- INTERACTION SYSTEM ----------
var nearby_interactables: Array[Node] = []
var focused_interactable: Node = null

@onready var interact_area: Area2D = $InteractArea


func _ready() -> void:
	add_to_group("player")

	if interact_area:
		interact_area.area_entered.connect(_on_area_entered)
		interact_area.area_exited.connect(_on_area_exited)

	# ค้นหา Orca ตัวแรกในฉาก
	orca = get_tree().get_first_node_in_group("orca")


func _physics_process(_delta: float) -> void:
	# 1. Player movement
	var direction = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	velocity = direction * SPEED
	move_and_slide()

	# 2. Update interaction focus
	_update_focus()

	# 3. Update Heartbeat sound dynamics
	_update_heartbeat_sound()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if is_instance_valid(focused_interactable):
			if focused_interactable.has_method("interact"):
				focused_interactable.interact(self)
				get_viewport().set_input_as_handled()


# ---------- HEARTBEAT SYSTEM LOGIC ----------
func _update_heartbeat_sound() -> void:
	if heartbeat_stream == null:
		return

	# เช็กว่ามีโหนด Orca อยู่ในฉากหรือไม่
	if not is_instance_valid(orca):
		orca = get_tree().get_first_node_in_group("orca")
		if not is_instance_valid(orca):
			if heartbeat_stream.playing:
				heartbeat_stream.stop()
			return

	var dist := global_position.distance_to(orca.global_position)

	if dist <= max_hear_distance:
		if not heartbeat_stream.playing:
			heartbeat_stream.play()

		var factor := 1.0 - (dist / max_hear_distance)
		factor = clampf(factor, 0.0, 1.0)
		
		heartbeat_stream.volume_db = lerpf(min_db, max_db, factor)
		heartbeat_stream.pitch_scale = lerpf(0.75, 1.5, factor)
	else:
		if heartbeat_stream.playing:
			heartbeat_stream.stop()


# ---------- INTERACTION SYSTEM LOGIC ----------
func _get_interactable(area: Area2D) -> Node:
	if area.has_method("interact"):
		return area

	var parent = area.get_parent()

	if parent and parent.has_method("interact"):
		return parent

	return null


func _on_area_entered(area: Area2D) -> void:
	var obj = _get_interactable(area)

	if obj and obj not in nearby_interactables:
		nearby_interactables.append(obj)


func _on_area_exited(area: Area2D) -> void:
	var obj = _get_interactable(area)

	if obj:
		nearby_interactables.erase(obj)

		if obj == focused_interactable:
			_set_focus(null)


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


func _set_focus(obj: Node) -> void:
	if is_instance_valid(focused_interactable):
		if focused_interactable.has_method("set_focused"):
			focused_interactable.set_focused(false)

	focused_interactable = obj

	if is_instance_valid(focused_interactable):
		if focused_interactable.has_method("set_focused"):
			focused_interactable.set_focused(true)
