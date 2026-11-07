extends CanvasLayer
@export_multiline var passages: Array[String] = []
@export var voice: AudioStream
var _page := 0
var _active := true
var _waiting := false
var _tree: SceneTree
func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_tree = get_tree()
	_tree.paused = true
func _ready() -> void:
	$Control.show()
	$Control/Fade.hide()
	if passages.is_empty():
		_finish()
		return
	$Voice.stream = voice
	_show_page()
func _show_page() -> void:
	$Control/Panel/Label.text = passages[_page]
	$Control/Panel/ContinueHint.hide()
	if _page == 0 and voice:
		$Voice.play()
	await _tree.process_frame
	while Input.is_action_pressed("ui_accept"):
		await _tree.process_frame
	$Control/Panel/ContinueHint.show()
	_waiting = true
func _input(event: InputEvent) -> void:
	if not _active:
		return
	get_viewport().set_input_as_handled()
	if _waiting and event.is_action_pressed("ui_accept"):
		_waiting = false
		$Voice.stop()
		_page += 1
		if _page < passages.size():
			_show_page()
		else:
			_finish()
func _finish() -> void:
	_active = false
	$Control.hide()
	set_process_input(false)
	_tree.paused = false
func _exit_tree() -> void:
	if _active:
		_tree.paused = false
