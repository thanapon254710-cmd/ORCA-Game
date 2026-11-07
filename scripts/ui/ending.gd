extends Control

@export_file("*.tscn") var next_scene: String = "res://scenes/ui/the_end.tscn"
@export_multiline var passages: Array[String] = []
var _page := 0
var _busy := true
var _switching := false
var _tree: SceneTree
var _hud: CanvasLayer
var _hud_was_visible := false

func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_tree = get_tree()
	_tree.paused = true

func _ready() -> void:
	_hud = Inventory.get_node("InventoryHUD")
	_hud_was_visible = _hud.visible
	_hud.hide()
	if passages.is_empty():
		_open_room()
		return
	$Text.modulate.a = 0.0
	_show_page()

func _fade(alpha: float) -> void:
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property($Text, "modulate:a", alpha, 0.35)
	await tween.finished

func _show_page() -> void:
	$Hint.hide()
	$Text.text = passages[_page]
	$Text.add_theme_font_size_override("font_size", 28)
	await _fade(1.0)
	while Input.is_action_pressed("ui_accept"):
		await _tree.process_frame
	$Hint.show()
	_busy = false

func _input(event: InputEvent) -> void:
	get_viewport().set_input_as_handled()
	if not _busy and event.is_action_pressed("ui_accept"):
		_busy = true
		_advance()

func _advance() -> void:
	$Hint.hide()
	await _fade(0.0)
	if _page + 1 < passages.size():
		_page += 1
		_show_page()
	else:
		_open_room()

func _open_room() -> void:
	_switching = true
	var error := _tree.change_scene_to_file(next_scene)
	if error != OK:
		_switching = false
		$Text.modulate.a = 1.0
		$Hint.text = "Could not open next scene. Press Enter to retry."
		$Hint.show()
		_busy = false
		push_error("Could not open next scene: " + error_string(error))

func _exit_tree() -> void:
	if is_instance_valid(_hud):
		_hud.visible = _hud_was_visible
	if not _switching:
		_tree.paused = false
