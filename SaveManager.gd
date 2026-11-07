extends Node

const SAVE_PATH = "user://local_scores.json"

# ตัวแปรจำสถานะของรอบปัจจุบัน
var current_username: String = "Guest"
var run_start_ticks: int = 0
var latest_reward_name: String = ""

var save_data: Dictionary = {
	"users": {}
}

func _ready():
	load_data_from_disk()

# เริ่มนับเวลาของรอบการเล่น
func start_new_run(username: String):
	current_username = username.strip_edges()
	if current_username == "":
		current_username = "Guest"
	run_start_ticks = Time.get_ticks_msec()

# อ่านไฟล์เซฟจากเครื่อง
func load_data_from_disk():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary and parsed.has("users"):
			save_data = parsed
		file.close()

# บันทึกข้อมูลสถิติของ User เมื่อจบเกม
func record_run_completion(reward_name: String = "") -> Dictionary:
	var time_spent_sec = (Time.get_ticks_msec() - run_start_ticks) / 1000.0
	latest_reward_name = reward_name
	
	if not save_data["users"].has(current_username):
		save_data["users"][current_username] = {
			"play_count": 0,
			"best_time_sec": 999999.0,
			"items_history": []
		}
	
	var user_record = save_data["users"][current_username]
	user_record["play_count"] += 1
	
	# อัปเดตเวลาที่ดีที่สุด
	if time_spent_sec < user_record["best_time_sec"]:
		user_record["best_time_sec"] = time_spent_sec
		
	# บันทึกของที่สุ่มได้ (ไม่บันทึกซ้ำ)
	if reward_name != "" and not user_record["items_history"].has(reward_name):
		user_record["items_history"].append(reward_name)
		
	_save_data_to_disk()
	
	return {
		"username": current_username,
		"play_count": user_record["play_count"],
		"current_time": time_spent_sec,
		"best_time": user_record["best_time_sec"],
		"items_history": user_record["items_history"]
	}

func _save_data_to_disk():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()

# ฟังก์ชันแปลงวินาทีเป็นรูปแบบ mm:ss
func format_seconds(seconds: float) -> String:
	var total_sec = int(seconds)
	var mins = total_sec / 60
	var secs = total_sec % 60
	return "%02d:%02d" % [mins, secs]
