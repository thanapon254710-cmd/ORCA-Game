extends Control

@export_file("*.tscn") var first_scene: String = "res://scenes/ui/how_to_play.tscn"
const ART_SIZE := Vector2(1152, 648)
@onready var start_button: TextureButton = $Artwork/StartButton
@onready var exit_button: TextureButton = $Artwork/ExitButton
var _inventory_hud: CanvasLayer
var _starting: bool = false

func _ready() -> void:
	get_tree().paused = false
	_inventory_hud = Inventory.get_node("InventoryHUD")
	_inventory_hud.hide()
	_inventory_hud.set_process_unhandled_key_input(false)
	_inventory_hud.get_node("Root/Panel").hide()
	start_button.pressed.connect(_start_game)
	exit_button.pressed.connect(_exit_game)
	for button in [start_button, exit_button]:
		button.mouse_entered.connect(_refresh_highlights, CONNECT_DEFERRED)
		button.mouse_exited.connect(_refresh_highlights, CONNECT_DEFERRED)
		button.focus_entered.connect(_refresh_highlights, CONNECT_DEFERRED)
		button.focus_exited.connect(_refresh_highlights, CONNECT_DEFERRED)
	resized.connect(_fit_artwork)
	_fit_artwork()
	_refresh_highlights()

func _fit_artwork() -> void:
	var factor: float = minf(size.x / ART_SIZE.x, size.y / ART_SIZE.y)
	$Artwork.scale = Vector2.ONE * factor
	$Artwork.position = (size - ART_SIZE * factor) * 0.5

func _refresh_highlights() -> void:
	# Mouse hover takes priority over keyboard focus: only one button glows.
	var start_hover: bool = start_button.is_hovered()
	var exit_hover: bool = exit_button.is_hovered()
	var start_active: bool = start_hover or (not exit_hover and start_button.has_focus())
	var exit_active: bool = exit_hover or (not start_hover and exit_button.has_focus())
	$Artwork/StartBlood.visible = start_active
	$Artwork/StartGlow.visible = start_active
	$Artwork/ExitBlood.visible = exit_active
	$Artwork/ExitGlow.visible = exit_active

func _start_game() -> void:
	if _starting:
		return
	_starting = true
	start_button.disabled = true
	exit_button.disabled = true
	var error: Error = get_tree().change_scene_to_file(first_scene)
	if error != OK:
		$Artwork/ErrorMessage.text = "Could not start the game. Check First Scene in the Inspector."
		$Artwork/ErrorMessage.show()
		_starting = false
		start_button.disabled = false
		exit_button.disabled = false

func _exit_game() -> void:
	get_tree().quit()

func _exit_tree() -> void:
	if is_instance_valid(_inventory_hud):
		_inventory_hud.show()
		_inventory_hud.set_process_unhandled_key_input(true)
