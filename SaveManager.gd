extends Node

const SAVE_PATH = "user://local_scores.json"

var current_username: String = "Guest"
var run_start_ticks: int = 0
var current_run_deaths: int = 0
var latest_reward_name: String = ""

var save_data: Dictionary = {
	"runs_history": [],
	"users": {}
}

func _ready():
	load_data_from_disk()

func start_new_run(username: String):
	current_username = username.strip_edges()
	if current_username == "":
		current_username = "Guest"
	run_start_ticks = Time.get_ticks_msec()
	current_run_deaths = 0

func add_death():
	current_run_deaths += 1

func load_data_from_disk():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			if parsed.has("runs_history"):
				save_data["runs_history"] = parsed["runs_history"]
			if parsed.has("users"):
				save_data["users"] = parsed["users"]
		file.close()

func record_run_completion(reward_name: String = "") -> Dictionary:
	var time_spent_sec = (Time.get_ticks_msec() - run_start_ticks) / 1000.0
	latest_reward_name = reward_name
	
	if not save_data.has("users"):
		save_data["users"] = {}
	if not save_data.has("runs_history"):
		save_data["runs_history"] = []
		
	if not save_data["users"].has(current_username):
		save_data["users"][current_username] = {
			"play_count": 0,
			"best_time_sec": 999999.0,
			"fewest_deaths": 9999,
			"items_history": []
		}
	
	var user_rec: Dictionary = save_data["users"][current_username]
	if not user_rec.has("play_count"):
		user_rec["play_count"] = 0
	if not user_rec.has("best_time_sec"):
		user_rec["best_time_sec"] = 999999.0
	if not user_rec.has("fewest_deaths"):
		user_rec["fewest_deaths"] = 9999
	if not user_rec.has("items_history"):
		user_rec["items_history"] = []
		
	user_rec["play_count"] += 1
	
	if time_spent_sec < user_rec["best_time_sec"]:
		user_rec["best_time_sec"] = time_spent_sec
	if current_run_deaths < user_rec["fewest_deaths"]:
		user_rec["fewest_deaths"] = current_run_deaths
	if reward_name != "" and not user_rec["items_history"].has(reward_name):
		user_rec["items_history"].append(reward_name)
		
	# บันทึกข้อมูลของรอบปัจจุบันนี้
	var current_run_summary = {
		"username": current_username,
		"clear_time": time_spent_sec,
		"deaths": current_run_deaths,
		"reward": reward_name,
		"play_count": user_rec["play_count"],
		"date": Time.get_datetime_string_from_system(false, true)
	}
	
	# เก็บประวัติรอบนี้ลงบนสุดของประวัติรวม
	save_data["runs_history"].append(current_run_summary)
	_save_data_to_disk()
	
	return {
		"latest": current_run_summary,
		"all_runs": save_data["runs_history"]
	}

func _save_data_to_disk():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()

func format_seconds(seconds: float) -> String:
	var total_sec = int(seconds)
	var mins = total_sec / 60
	var secs = total_sec % 60
	return "%02d:%02d" % [mins, secs]
