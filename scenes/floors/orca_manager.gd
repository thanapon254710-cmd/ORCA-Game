extends Node

func _ready() -> void:
	# ค้นหาโหนด Orca1 ในแมพ แล้วต่อ Signal
	var orca = get_parent().get_node_or_null("Orca")
	if orca and orca.has_signal("player_caught"):
		orca.player_caught.connect(_on_player_caught)

func _on_player_caught() -> void:
	print("GAME OVER")
	get_tree().paused = true                   # หยุดเกมทั้งหมด
	await get_tree().create_timer(1.0).timeout # ค้างไว้ 1 วินาทีให้รู้ว่าโดนจับ
	get_tree().paused = false
	get_tree().reload_current_scene()          # เริ่มด่านใหม่
