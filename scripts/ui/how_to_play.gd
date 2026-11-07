extends Control

@export_file("*.tscn") var gameplay_scene: String = "res://scenes/room/room407cutscene.tscn"
const MENU_SCENE = "res://scenes/ui/start_menu.tscn"
const DESIGN_SIZE := Vector2(1152, 648)
var _changing: bool = false
var _hud: CanvasLayer

func _ready() -> void:
    get_tree().paused = false
    _hud = Inventory.get_node("InventoryHUD")
    _hud.hide()
    _hud.set_process_unhandled_key_input(false)
    _hud.get_node("Root/Panel").hide()
    _hud.get_node("Root/Notice").hide()
    _hud.get_node("NoticeTimer").stop()
    $Artwork/BeginButton.pressed.connect(_begin)
    $Artwork/BackButton.pressed.connect(_back)
    resized.connect(_fit)
    _fit()

func _fit() -> void:
    var factor: float = minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
    $Artwork.scale = Vector2.ONE * factor
    $Artwork.position = (size - DESIGN_SIZE * factor) * 0.5

func _begin() -> void:
    if _changing:
        return
    GameState.reset_game()
    _change_to(gameplay_scene)

func _back() -> void:
    _change_to(MENU_SCENE)

func _change_to(path: String) -> void:
    if _changing:
        return
    _changing = true
    $Artwork/BeginButton.disabled = true
    $Artwork/BackButton.disabled = true
    var error: Error = get_tree().change_scene_to_file(path)
    if error != OK:
        $Artwork/ErrorMessage.text = "Could not open the next scene. Please try again."
        $Artwork/ErrorMessage.show()
        _changing = false
        $Artwork/BeginButton.disabled = false
        $Artwork/BackButton.disabled = false

func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        get_viewport().set_input_as_handled()
        _back()

func _exit_tree() -> void:
    if is_instance_valid(_hud):
        _hud.show()
        _hud.set_process_unhandled_key_input(true)
