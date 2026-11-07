extends CanvasLayer

signal username_confirmed(username: String)

@onready var name_input: LineEdit = $Background/Card/VBoxContainer/NameInput
@onready var start_button: Button = $Background/Card/VBoxContainer/StartButton
@onready var warning_label: Label = $Background/Card/VBoxContainer/WarningLabel

func _ready():
	warning_label.text = ""
	start_button.pressed.connect(_on_start_pressed)
	name_input.text_submitted.connect(func(_t): _on_start_pressed())
	name_input.grab_focus()

func _on_start_pressed():
	var user_text = name_input.text.strip_edges()
	if user_text == "":
		warning_label.text = "กรุณาใส่ชื่อก่อนเริ่มเกม / Name cannot be empty"
		warning_label.modulate = Color.RED
		return
		
	SaveManager.start_new_run(user_text)
	username_confirmed.emit(user_text)
	queue_free() # ปิดหน้าต่างตัวเองทิ้ง
