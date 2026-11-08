extends CanvasLayer

@onready var user_info_label: Label = $BackgroundDim/CenterContainer/BoardCard/VBoxContainer/UserInfoLabel
@onready var time_info_label: Label = $BackgroundDim/CenterContainer/BoardCard/VBoxContainer/TimeInfoLabel
@onready var items_list_label: Label = $BackgroundDim/CenterContainer/BoardCard/VBoxContainer/ItemScroll/ItemListLabel
@onready var play_again_btn: Button = $BackgroundDim/CenterContainer/BoardCard/VBoxContainer/HBoxContainer/PlayAgainBtn
@onready var exit_btn: Button = $BackgroundDim/CenterContainer/BoardCard/VBoxContainer/HBoxContainer/ExitBtn

func _ready():
	play_again_btn.pressed.connect(_on_play_again)
	exit_btn.pressed.connect(func(): get_tree().quit())
	
	var sm = get_node_or_null("/root/SaveManager")
	if not sm:
		return
		
	var result = sm.record_run_completion(sm.latest_reward_name)
	
	# แสดงผลรอบล่าสุดชัดเจน
	$BackgroundDim/CenterContainer/BoardCard/VBoxContainer/HeaderLabel.text = "★ MISSION COMPLETE / สรุปผลรอบล่าสุด ★"
	
	user_info_label.text = "ผู้เล่น: %s   |   ครั้งที่เล่น: %d" % [result["username"], result["play_count"]]
	
	var time_str = sm.format_seconds(result["clear_time"])
	time_info_label.text = "⏱ เวลาที่ใช้: %s   |   💀 จำนวนการตาย: %d ครั้ง" % [time_str, result["deaths"]]
	time_info_label.modulate = Color(1.0, 0.85, 0.3)
	
	# แสดงของรางวัลที่ได้รับในรอบนี้
	var reward_text = result["reward"] if result["reward"] != "" else "ไม่มีของรางวัล"
	items_list_label.text = "🎁 รางวัลที่สุ่มได้รอบนี้:\n• " + reward_text

func _on_play_again():
	# รีสตาร์ทกลับไปหน้าแรกสุดของโปรเจกต์
	get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn")
