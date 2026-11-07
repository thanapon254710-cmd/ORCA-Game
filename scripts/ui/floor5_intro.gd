extends CanvasLayer

var _active := false
var _waiting := false
var _switching := false
var _tree: SceneTree

func _enter_tree() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _tree = get_tree()
    _active = not GameState.floor5_intro_seen
    if _active:
        _tree.paused = true

func _input(event: InputEvent) -> void:
    if not _active:
        return
    # Consume inputs so inventory, doors and questions cannot activate underneath.
    get_viewport().set_input_as_handled()
    if _waiting and event.is_action_pressed("ui_accept"):
        _waiting = false
        _advance()

func _arm_continue() -> void:
    # A held Enter from the preceding screen must not dismiss this one.
    await _tree.process_frame
    while Input.is_action_pressed("ui_accept"):
        await _tree.process_frame
    $Control/Panel/ContinueHint.show()
    _waiting = true

func _fade_to(alpha: float, seconds: float) -> void:
    var tween := create_tween()
    tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tween.tween_property($Control/Fade, "color:a", alpha, seconds)
    await tween.finished

func _exit_tree() -> void:
    # Preserve the lock only during our deliberate room407 -> floor5 handoff.
    if _active and not _switching:
        _tree.paused = false

func _ready() -> void:
    if not _active:
        set_process_input(false)
        return
    $Control.show()
    $Control/Panel/ContinueHint.hide()
    $Control/Fade.color.a = 1.0
    $Control/Fade.show()
    await _fade_to(0.0, 0.6)
    $Control/Fade.hide()
    _arm_continue()

func _advance() -> void:
    GameState.floor5_intro_seen = true
    $Control.hide()
    _active = false
    set_process_input(false)
    _tree.paused = false
