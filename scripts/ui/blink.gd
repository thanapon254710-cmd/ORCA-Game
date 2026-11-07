extends Control

@export var hold_seconds: float = 2.0
var _switching := false
var _busy := true
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
    $Title.modulate.a = 0.0
    var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    tween.tween_property($Title, "modulate:a", 1.0, 0.5)
    tween.tween_interval(hold_seconds)
    tween.tween_property($Title, "modulate:a", 0.0, 0.5)
    await tween.finished
    _open_floor()

func _open_floor() -> void:
    _switching = true
    var error := _tree.change_scene_to_file("res://scenes/floors/floor5.tscn")
    if error != OK:
        _switching = false
        _busy = false
        $Title.modulate.a = 1.0
        $Retry.show()
        push_error("Could not open floor5: " + error_string(error))

func _input(event: InputEvent) -> void:
    get_viewport().set_input_as_handled()
    if not _busy and event.is_action_pressed("ui_accept"):
        _busy = true
        _open_floor()

func _exit_tree() -> void:
    if is_instance_valid(_hud):
        _hud.visible = _hud_was_visible
    if not _switching:
        _tree.paused = false
