extends CanvasLayer

@onready var text_label: Label = $DialogueUI/Panel/TextLabel
@onready var fade_overlay: ColorRect = $FadeOverlay

# รายการข้อความที่จะให้แสดงทีละหน้า
var dialogue_steps: Array[String] = [
	"Just a moment ago, you were sitting in your game dev class, but with a single blink, you suddenly found yourself in the 5th-floor restroom of the Main Building.",
    "You hear the Orca mascot’s voice declare: “I’m taking you with me.” You need to find a way to escape the Main Building now. If you don't know where to start, try picking a path and stay on your guard. The friends you know might not always be on your side."
]

var current_step: int = 0
var is_transitioning: bool = false

func _ready() -> void:
	# เปิดเกมมาให้แสดงข้อความแรกทันที
	show_current_dialogue()

func _unhandled_input(event: InputEvent) -> void:
	if is_transitioning:
		return
		
	# เมื่อผู้เล่นกดปุ่ม Enter (ui_accept) หรือ Spacebar
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		current_step += 1
		if current_step < dialogue_steps.size():
			# แสดงข้อความหน้าถัดไป
			show_current_dialogue()
		else:
			# ข้อความหมดแล้ว -> ทำเอฟเฟกต์กระพริบตาแล้วย้ายไป floor5
			trigger_blink_transition()

func show_current_dialogue() -> void:
	text_label.text = dialogue_steps[current_step]

func trigger_blink_transition() -> void:
	is_transitioning = true
	
	# ใช้ Tween ทำอนิเมชันเฟดหน้าจอเป็นสีดำสนิท (หลับตา)
	var tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.6)
	await tween.finished
	
	# เปลี่ยนไปฉาก floor5 (ตรวจสอบ path ไฟล์ floor5 ของคุณให้ถูกต้อง)
	get_tree().change_scene_to_file("res://scenes/floors/floor5.tscn")
