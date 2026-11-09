extends CanvasLayer

signal puzzle_completed
signal puzzle_closed

@onready var backdrop: TextureRect = $BookshelfBackdrop
@onready var shelves_container: Control = $BookshelfBackdrop/ShelvesContainer
@onready var shelf_top: HBoxContainer = $BookshelfBackdrop/ShelvesContainer/ShelfTop
@onready var shelf_middle: HBoxContainer = $BookshelfBackdrop/ShelvesContainer/ShelfMiddle
@onready var shelf_bottom: HBoxContainer = $BookshelfBackdrop/ShelvesContainer/ShelfBottom

@onready var check_button: Button = $CheckButton
@onready var reset_button: Button = $ResetButton

var feedback_label: Label
var _solved: bool = false
var top_slots: Array[BookSlot] = []
var middle_slots: Array[BookSlot] = []
var bottom_slots: Array[BookSlot] = []

# เฉลยตำแหน่งจริงตามภาพ (ชั้นละ 11 ช่อง เป๊ะ 100%)
const SOLUTION_TOP = [
	"book_blue", "book_white", "book_orange", "book_blue", "book_white", "book_orange",
	"", "", "", "", "book_blue"
]

const SOLUTION_MIDDLE = [
	"book_white",
	"", "", "", "", "", "",
	"book_blue", "book_blue", "book_white", "book_orange"
]

const SOLUTION_BOTTOM = [
	"", "", "", "", "", "", "", "",
	"book_white", "book_white", "book_blue"
]

func _ready():
	_setup_layout_dimensions()
	_create_shelf_slots()
	_create_feedback_label()
	set_process_unhandled_input(true)
	
	check_button.pressed.connect(_on_check_pressed)
	reset_button.pressed.connect(reset_puzzle)

func _place(node: Control, pos: Vector2, dimensions: Vector2) -> void:
	node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	node.position = pos
	node.size = dimensions

func _fit_puzzle() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var factor = minf((viewport_size.x - 32.0) / 760.0, (viewport_size.y - 32.0) / 710.0)
	transform = Transform2D(0.0, Vector2.ONE * factor, 0.0, (viewport_size - Vector2(760, 710) * factor) / 2.0)

func _setup_layout_dimensions():
	_place(backdrop, Vector2.ZERO, Vector2(760, 590))
	_place($BackgroundDim, Vector2.ZERO, Vector2(760, 710))
	$BackgroundDim.color = Color(0.12, 0.12, 0.12, 1)
	_place(shelves_container, Vector2.ZERO, Vector2(760, 590))
	var rows = [shelf_top, shelf_middle, shelf_bottom]
	var heights = [29.0, 211.0, 401.0]
	for i in 3:
		_place(rows[i], Vector2(52, heights[i]), Vector2(667, 110 if i == 2 else 124))
		rows[i].alignment = BoxContainer.ALIGNMENT_CENTER
		rows[i].add_theme_constant_override("separation", 2)
	_place($BottomDock, Vector2(0, 594), Vector2(760, 116))
	var dock_style := StyleBoxFlat.new()
	dock_style.bg_color = Color(0.45, 0.45, 0.45, 1)
	dock_style.content_margin_left = 12.0
	dock_style.content_margin_right = 140.0
	$BottomDock.add_theme_stylebox_override("panel", dock_style)
	$BottomDock/HBoxContainer.add_theme_constant_override("separation", 12)
	for source in $BottomDock/HBoxContainer.get_children():
		source.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_place(check_button, Vector2(630, 605), Vector2(115, 40))
	_place(reset_button, Vector2(630, 656), Vector2(115, 40))
	_fit_puzzle()
	get_viewport().size_changed.connect(_fit_puzzle)

func _create_shelf_slots():
	for i in range(11):
		var slot_t = BookSlot.new()
		shelf_top.add_child(slot_t)
		top_slots.append(slot_t)
		
		var slot_m = BookSlot.new()
		shelf_middle.add_child(slot_m)
		middle_slots.append(slot_m)
		
		var slot_b = BookSlot.new()
		shelf_bottom.add_child(slot_b)
		slot_b.custom_minimum_size.y = 110
		bottom_slots.append(slot_b)

func _create_feedback_label():
	# สร้าง Label แสดงข้อความผลลัพธ์ลอยตรงกลางด้านล่าง
	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_label.position = Vector2(200, 625)
	feedback_label.size = Vector2(420, 60)
	feedback_label.add_theme_font_size_override("font_size", 22)
	feedback_label.text = ""
	add_child(feedback_label)

func _on_check_pressed():
	var current_top = top_slots.map(func(slot): return slot.current_item)
	var current_middle = middle_slots.map(func(slot): return slot.current_item)
	var current_bottom = bottom_slots.map(func(slot): return slot.current_item)
	
	var is_correct = (current_top == SOLUTION_TOP and \
					  current_middle == SOLUTION_MIDDLE and \
					  current_bottom == SOLUTION_BOTTOM)
	
	if is_correct:
		_solved = true
		check_button.disabled = true
		feedback_label.text = "✓ That’s right! The bookshelf is perfectly organized."
		feedback_label.modulate = Color.GREEN
		GameState.floor2_gate_unlocked = true
		puzzle_completed.emit()
		if GameState.has_signal("question_answered"):
			GameState.question_answered.emit("q_2_bookshelf", true)
		if not GameState.questions_answered.has("q_2_bookshelf"):
			GameState.questions_answered.append("q_2_bookshelf")
			
		await get_tree().create_timer(2.2).timeout
		puzzle_closed.emit()
	else:
		feedback_label.text = "✗ The order is not yet correct; please check the positions again."
		feedback_label.modulate = Color.RED
		check_button.disabled = true
		await get_tree().create_timer(1.2).timeout
		feedback_label.text = ""
		check_button.disabled = false

func reset_puzzle():
	feedback_label.text = ""
	_return_books_to_inventory()

# คืนหนังสือทุกเล่มที่วางบนชั้นกลับเข้า Inventory แล้วเคลียร์ช่อง
func _return_books_to_inventory() -> void:
	var index := 0
	for slot in (top_slots + middle_slots + bottom_slots):
		if slot.current_item != "":
			Inventory.collect(slot.current_item, "return_%d_%d_%d" % [Time.get_ticks_msec(), index, randi()])
			slot.set_book("")
		index += 1

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close_puzzle()
		get_viewport().set_input_as_handled()


func close_puzzle() -> void:
	# ถ้ายังไม่ผ่านปริศนา (เช่น กด ESC กลางคัน) ให้คืนหนังสือที่วางไว้กลับเข้า Inventory
	# ถ้าผ่านแล้ว หนังสือถือว่าถูกใช้ไปแล้ว ไม่ต้องคืน
	if not _solved:
		_return_books_to_inventory()
	queue_free()
