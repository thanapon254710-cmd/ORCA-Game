extends CanvasLayer

signal puzzle_completed
signal puzzle_closed

@onready var backdrop: TextureRect = $BookshelfBackdrop
@onready var shelves_container: VBoxContainer = $BookshelfBackdrop/ShelvesContainer
@onready var shelf_top: HBoxContainer = $BookshelfBackdrop/ShelvesContainer/ShelfTop
@onready var shelf_middle: HBoxContainer = $BookshelfBackdrop/ShelvesContainer/ShelfMiddle
@onready var shelf_bottom: HBoxContainer = $BookshelfBackdrop/ShelvesContainer/ShelfBottom

@onready var check_button: Button = $CheckButton
@onready var reset_button: Button = $ResetButton

var feedback_label: Label
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
	
	check_button.pressed.connect(_on_check_pressed)
	reset_button.pressed.connect(reset_puzzle)
	
	# เตรียมหนังสือ 15 เล่มเข้ากระเป๋าสำหรับทดสอบ (ฟ้า 6, ขาว 6, ส้ม 3)
	if Inventory != null:
		if Inventory.get_count("book_blue") < 6:
			for i in range(6 - Inventory.get_count("book_blue")):
				Inventory.collect("book_blue", "init_b_" + str(i))
		if Inventory.get_count("book_white") < 6:
			for i in range(6 - Inventory.get_count("book_white")):
				Inventory.collect("book_white", "init_w_" + str(i))
		if Inventory.get_count("book_orange") < 3:
			for i in range(3 - Inventory.get_count("book_orange")):
				Inventory.collect("book_orange", "init_o_" + str(i))

func _setup_layout_dimensions():
	shelves_container.position = Vector2(52, 29)
	shelves_container.size = Vector2(667, 476)
	shelves_container.add_theme_constant_override("separation", 52)
	
	for shelf in [shelf_top, shelf_middle, shelf_bottom]:
		shelf.custom_minimum_size = Vector2(667, 124)
		shelf.alignment = BoxContainer.ALIGNMENT_CENTER
		shelf.add_theme_constant_override("separation", 2)

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
		bottom_slots.append(slot_b)

func _create_feedback_label():
	# สร้าง Label แสดงข้อความผลลัพธ์ลอยตรงกลางด้านล่าง
	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_label.position = Vector2(52, 450)
	feedback_label.size = Vector2(667, 40)
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
		check_button.disabled = true
		feedback_label.text = "✓ That’s right! The bookshelf is perfectly organized."
		feedback_label.modulate = Color.GREEN
		
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
	for slot in (top_slots + middle_slots + bottom_slots):
		if slot.current_item != "":
			Inventory.collect(slot.current_item, "reset_" + str(Time.get_ticks_msec()) + "_" + str(randi()))
			slot.set_book("")
