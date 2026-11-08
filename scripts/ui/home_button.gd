extends TextureButton

const MENU_SCENE = "res://scenes/ui/start_menu.tscn"
var _returning: bool = false

func _ready() -> void:
	pressed.connect(_go_home)
	mouse_entered.connect(_update_tint, CONNECT_DEFERRED)
	mouse_exited.connect(_update_tint, CONNECT_DEFERRED)
	focus_entered.connect(_update_tint, CONNECT_DEFERRED)
	focus_exited.connect(_update_tint, CONNECT_DEFERRED)

func _update_tint() -> void:
	self_modulate = Color(1.0, 0.55, 0.55) if is_hovered() or has_focus() else Color.WHITE

func _go_home() -> void:
	var tree := get_tree()
	if _returning or TransitionManager.is_transitioning or tree.paused:
		return
	_returning = true
	disabled = true
	# Question windows are attached to the tree root and need explicit cleanup.
	for point in tree.get_nodes_in_group("question_points"):
		if point.has_method("close_question_ui"):
			point.close_question_ui()
	var hud: CanvasLayer = Inventory.get_node("InventoryHUD")
	hud.get_node("Root/Panel").hide()
	hud.get_node("Root/Notice").hide()
	hud.get_node("NoticeTimer").stop()
	var error: Error = tree.change_scene_to_file(MENU_SCENE)
	if error != OK:
		push_error("Could not open the start menu: %s" % error_string(error))
		_returning = false
		disabled = false
		return
	await tree.scene_changed
	# This button belongs to the old scene and is usually freed by now.
	if not is_instance_valid(self) or not is_inside_tree():
		return
	_returning = false
	disabled = false
	release_focus()
	self_modulate = Color.WHITE
