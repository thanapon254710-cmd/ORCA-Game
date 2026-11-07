extends CanvasLayer

@onready var user_info_label: Label = $BackgroundDim/CenterContainer/BoardCard/VBoxContainer/UserInfoLabel
@onready var time_info_label: Label = $BackgroundDim/CenterContainer/BoardCard/VBoxContainer/TimeInfoLabel
@onready var items_list_label: Label = $BackgroundDim/CenterContainer/BoardCard/VBoxContainer/ItemScroll/ItemListLabel
@onready var play_again_btn: Button = $BackgroundDim/CenterContainer/BoardCard/VBoxContainer/HBoxContainer/PlayAgainBtn
@onready var exit_btn: Button = $BackgroundDim/CenterContainer/BoardCard/VBoxContainer/HBoxContainer/ExitBtn

func _ready():
	play_again_btn.pressed.connect(_on_play_again)
	exit_btn.pressed.connect(func(): get_tree().quit())
	
	# ดึงสถิติตัวเองและเซฟลง disk
	var result = SaveManager.record_run_completion(SaveManager.latest_reward_name)
	
	# ปรับแต่งหัวเรื่อง
	$BackgroundDim/CenterContainer/BoardCard/VBoxContainer/HeaderLabel.text = "★ สรุปผลการเล่น / SCOREBOARD ★"
	$BackgroundDim/CenterContainer/BoardCard/VBoxContainer/HeaderLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$BackgroundDim/CenterContainer/BoardCard/VBoxContainer/HeaderLabel.add_theme_font_size_override("font_size", 22)
	
	# แสดงข้อมูลผู้เล่น
	user_info_label.text = "ผู้เล่น: %s   |   เล่นเป็นครั้งที่: %d" % [result["username"], result["play_count"]]
	user_info_label.add_theme_font_size_override("font_size", 16)
	
	var cur_str = SaveManager.format_seconds(result["current_time"])
	var best_str = SaveManager.format_seconds(result["best_time"])
	time_info_label.text = "เวลารอบนี้: %s   |   เวลาที่ดีที่สุด: %s" % [cur_str, best_str]
	time_info_label.add_theme_font_size_override("font_size", 16)
	time_info_label.modulate = Color(1.0, 0.85, 0.3) # สีเหลืองทอง
	
	# แสดงประวัติไอเทม
	var history: Array = result["items_history"]
	if history.is_empty():
		items_list_label.text = "- ยังไม่เคยได้รับไอเทม -"
	else:
		var formatted_items = []
		for item in history:
			formatted_items.append("• " + str(item))
		items_list_label.text = "\n".join(formatted_items)

func _on_play_again():
	# รีสตาร์ทกลับไปหน้าแรกสุดของโปรเจกต์
	get_tree().change_scene_to_file("res://scenes/main.tscn")
