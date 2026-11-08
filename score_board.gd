extends CanvasLayer

@onready var board_card: Panel = $BackgroundDim/CenterContainer/BoardCard
@onready var header_label: Label = $BackgroundDim/CenterContainer/BoardCard/VBoxContainer/HeaderLabel
@onready var item_scroll: ScrollContainer = $BackgroundDim/CenterContainer/BoardCard/VBoxContainer/ItemScroll
@onready var play_again_btn: Button = $BackgroundDim/CenterContainer/BoardCard/VBoxContainer/HBoxContainer/PlayAgainBtn
@onready var exit_btn: Button = $BackgroundDim/CenterContainer/BoardCard/VBoxContainer/HBoxContainer/ExitBtn

# ซ่อน Label เก่าที่ไม่ได้ใช้แล้ว
@onready var user_info_label: Label = $BackgroundDim/CenterContainer/BoardCard/VBoxContainer/UserInfoLabel
@onready var time_info_label: Label = $BackgroundDim/CenterContainer/BoardCard/VBoxContainer/TimeInfoLabel
#@onready var items_title_label: Label = $BackgroundDim/CenterContainer/BoardCard/VBoxContainer/ItemsTitleLabel
@onready var item_list_label: Label = $BackgroundDim/CenterContainer/BoardCard/VBoxContainer/ItemScroll/ItemListLabel
var _has_recorded: bool = false

func _ready():
	play_again_btn.pressed.connect(_on_play_again)
	exit_btn.pressed.connect(func(): get_tree().quit())
	
	# ซ่อนข้อความแบบเก่า
	if user_info_label: user_info_label.hide()
	if time_info_label: time_info_label.hide()
	#if items_title_label: items_title_label.hide()
	if item_list_label: item_list_label.hide()
	
	header_label.text = "★ ตารางสรุปประวัติการเล่นทั้งหมด / LEADERBOARD ★"
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_label.add_theme_font_size_override("font_size", 20)
	
	var sm = get_node_or_null("/root/SaveManager")
	if not sm:
		return
		
	#var data = sm.record_run_completion(sm.latest_reward_name)
	#var all_runs: Array = data.get("all_runs", [])
	# ป้องกันการบันทึกซ้ำซ้อนในเฟรมเดียวกัน
	var all_runs: Array = []
	if not _has_recorded:
		_has_recorded = true
		var data = sm.record_run_completion(sm.latest_reward_name)
		all_runs = data.get("all_runs", [])
	else:
		all_runs = sm.save_data.get("runs_history", [])
	
	_build_scoreboard_table(all_runs)

func _build_scoreboard_table(runs: Array):
	for child in item_scroll.get_children():
		if child != item_list_label:
			child.queue_free()
			
	var grid = GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_scroll.add_child(grid)
	
	# หัวตาราง
	var headers = ["", "ชื่อผู้เล่น", "ครั้งที่เล่น", "เวลาที่ใช้", "จำนวนการตาย", "รางวัลที่สุ่มได้"]
	for title in headers:
		var h = Label.new()
		h.text = title
		h.add_theme_font_size_override("font_size", 16)
		h.modulate = Color(1.0, 0.85, 0.3)
		grid.add_child(h)
		
	if runs.is_empty():
		return
		
	var total_count = runs.size()
	for i in range(total_count - 1, -1, -1):
		var run = runs[i]
		var is_latest = (i == total_count - 1)
		var row_color = Color(0.4, 1.0, 0.5) if is_latest else Color.WHITE
		
		# 1. ข้อความ "เล่นครั้งล่าสุด >>"
		var c0 = Label.new()
		c0.text = "เล่นครั้งล่าสุด >>" if is_latest else ""
		c0.modulate = Color(1.0, 0.3, 0.3) if is_latest else Color.WHITE
		c0.add_theme_font_size_override("font_size", 14)
		grid.add_child(c0)
		
		# 2. ชื่อผู้เล่น
		var c1 = Label.new()
		c1.text = str(run.get("username", "Guest"))
		c1.modulate = row_color
		c1.add_theme_font_size_override("font_size", 14)
		grid.add_child(c1)
		
		# 3. ครั้งที่เล่น (แปลงเป็นจำนวนเต็ม int ตัด .0 ทิ้ง)
		var c2 = Label.new()
		c2.text = "%d" % int(float(run.get("play_count", 1)))
		c2.modulate = row_color
		c2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c2.add_theme_font_size_override("font_size", 14)
		grid.add_child(c2)
		
		# 4. เวลาที่ใช้ (แปลงเป็น นาที กับ วินาที)
		var c3 = Label.new()
		var total_sec = float(run.get("clear_time", 0.0))
		var mins = int(total_sec) / 60
		var secs = int(total_sec) % 60
		if mins > 0:
			c3.text = "%d นาที %02d วินาที" % [mins, secs]
		else:
			c3.text = "%d วินาที" % secs
		c3.modulate = row_color
		c3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c3.add_theme_font_size_override("font_size", 14)
		grid.add_child(c3)
		
		# 5. จำนวนการตาย
		var c4 = Label.new()
		c4.text = "%d" % int(float(run.get("deaths", 0)))
		c4.modulate = row_color
		c4.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c4.add_theme_font_size_override("font_size", 14)
		grid.add_child(c4)
		
		# 6. รางวัลที่สุ่มได้พร้อม Stat
		var c5 = Label.new()
		var rew = str(run.get("reward", ""))
		c5.text = rew if rew != "" else "-"
		c5.modulate = row_color
		c5.add_theme_font_size_override("font_size", 14)
		grid.add_child(c5)

func _on_play_again():
	get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn")
