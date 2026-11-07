extends CanvasLayer

signal username_confirmed(username: String)

@onready var name_input: LineEdit = $Background/Card/VBoxContainer/NameInput
@onready var start_button: Button = $Background/Card/VBoxContainer/StartButton
@onready var warning_label: Label = $Background/Card/VBoxContainer/WarningLabel
@onready var title_label: Label = $Background/Card/VBoxContainer/TitleLabel

func _ready():
	# ตกแต่งข้อความ
	title_label.text = "— ENTER SURVIVOR NAME —\nกรุณากรอกชื่อผู้เล่น"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 16)
	
	name_input.placeholder_text = "ใส่ชื่อของคุณที่นี่... (Press Enter)"
	name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_input.custom_minimum_size = Vector2(0, 42)
	name_input.add_theme_font_size_override("font_size", 16)
	
	start_button.text = "START SURVIVAL (เริ่มเกม)"
	start_button.custom_minimum_size = Vector2(0, 40)
	
	warning_label.text = ""
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	start_button.pressed.connect(_on_start_pressed)
	name_input.text_submitted.connect(func(_t): _on_start_pressed())
	name_input.grab_focus()

func _on_start_pressed():
	var user_text = name_input.text.strip_edges()
	if user_text == "":
		warning_label.text = "กรุณาใส่ชื่อก่อนเริ่มเกม / Enter username"
		warning_label.modulate = Color.RED
		return
		
	# ส่งชื่อและรีเซ็ตค่าเริ่มต้นของรอบนี้
	SaveManager.start_new_run(user_text)
	username_confirmed.emit(user_text)
	queue_free()
