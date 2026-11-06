extends Area2D
class_name ParkingCar

signal car_selected(car: ParkingCar)
signal red_car_escaped

@export var is_red_car: bool = false
@export_enum("vertical", "horizontal") var orientation: String = "vertical"
@export var grid_step: float = 32.0

@onready var sprite: Sprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $Collision

var is_selected: bool = false
var is_moving: bool = false

# กำหนดขอบเขตลานจอดรถตามขนาดฉากจริง (1152 x 648)
# ปรับตัวเลขนี้เพื่อให้พอดีกับขอบแนวต้นไม้
var map_min_x: float = 120.0  # ขอบซ้าย
var map_max_x: float = 1000.0 # ขอบขวา
var map_min_y: float = 100.0  # ขอบบน
var map_max_y: float = 560.0  # ขอบล่าง

func _ready():
	input_event.connect(_on_input_event)

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		car_selected.emit(self)

func set_selected(selected: bool):
	is_selected = selected
	if is_selected:
		modulate = Color(1.3, 1.3, 1.3)
	else:
		modulate = Color.WHITE

func _unhandled_input(event):
	if not is_selected or is_moving:
		return
		
	var move_dir = Vector2.ZERO
	
	if orientation == "vertical":
		if event.is_action_pressed("move_up") or (event is InputEventKey and event.pressed and event.keycode == KEY_W):
			move_dir = Vector2.UP
		elif event.is_action_pressed("move_down") or (event is InputEventKey and event.pressed and event.keycode == KEY_S):
			move_dir = Vector2.DOWN
	else:
		if event.is_action_pressed("move_left") or (event is InputEventKey and event.pressed and event.keycode == KEY_A):
			move_dir = Vector2.LEFT
		elif event.is_action_pressed("move_right") or (event is InputEventKey and event.pressed and event.keycode == KEY_D):
			move_dir = Vector2.RIGHT
			
	if move_dir != Vector2.ZERO:
		try_move(move_dir)

func try_move(dir: Vector2):
	var target_pos = position + (dir * grid_step)
	
	# --- เงื่อนไขสำหรับ "รถสีแดง" ---
	if is_red_car:
		# ถ้ากดลง (Vector2.DOWN) แล้วพิกัดเป้าหมายข้ามขอบล่างของแมพ -> ขับหลุดออกจากฉากสำเร็จ
		if dir == Vector2.DOWN and target_pos.y > map_max_y:
			is_moving = true
			var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_property(self, "position", position + (dir * 250), 0.8)
			await tween.finished
			red_car_escaped.emit()
			return
		
		# ถ้ารถสีแดงพยายามขับขึ้นด้านบน ห้ามเลยขอบบนเด็ดขาด
		if target_pos.y < map_min_y:
			return

	# --- เงื่อนไขสำหรับ "รถคันอื่นๆ ทุกคัน" ---
	# ห้ามขยับเกินขอบเขตทั้ง 4 ด้าน
	if target_pos.x < map_min_x or target_pos.x > map_max_x or \
	   target_pos.y < map_min_y or target_pos.y > map_max_y:
		return

	# ตรวจสอบการชนกับรถคันอื่น (ใช้ intersect_shape เช็กเต็มพื้นที่ตัวรถ)
	if can_move_to(target_pos):
		is_moving = true
		var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "position", target_pos, 0.12)
		await tween.finished
		is_moving = false

func can_move_to(target_pos: Vector2) -> bool:
	if not collision_shape or not collision_shape.shape:
		return true

	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = collision_shape.shape
	
	# คำนวณ Transform โดยอิงจาก Global Transform เดิม เพื่อรักษา Scale และมุมหมุนจริงไว้
	var next_transform = global_transform
	next_transform.origin = target_pos + collision_shape.position.rotated(rotation)
	query.transform = next_transform
	
	query.collide_with_areas = true
	# ปิด bodies เพื่อไม่ให้ไปตรวจจับชนกับ TileMap หรือพื้นหลัง
	query.collide_with_bodies = false
	
	# ต้องใส่เป็น self.get_rid() ระบบฟิสิกส์ถึงจะตัดตัวเองออกได้ถูกต้อง 100%
	query.exclude = [self.get_rid()]

	var collisions = space_state.intersect_shape(query, 16)
	
	for hit in collisions:
		var collider = hit.get("collider")
		# ตรวจสอบว่าสิ่งที่ชนเป็นรถคันอื่น และไม่ใช่ตัวเอง
		if collider is ParkingCar and collider != self:
			return false
			
	return true
