extends Node2D
@onready var popup_text: Label = $CanvasLayer/PopupText
var popup_time_left: float = 0.0
# ดึงโหนด TileMap จากในฉากมาใช้งานอัตโนมัติ 
@onready var target_tilemap: TileMap = $TileMap 

# fence location
@export var fence_coords: Array[Vector2i] = [
	Vector2i(9, 15),
	Vector2i(10, 15),
	Vector2i(11, 15),
	Vector2i(12, 15),
	Vector2i(13, 15),
	Vector2i(14, 15)
]

func _ready() -> void:
	popup_text.hide()
	show_popup("Correct!")
	# call function remove fences
	# remove_fences()

func remove_fences() -> void:
	if target_tilemap:
		# วนลูปพิกัดรั้วทั้งหมด แล้วสั่งลบออกด้วยค่า -1
		for coord in fence_coords:
			target_tilemap.set_cell(3, coord, -1) # เลข 0 คือ Layer ของ TileMap
			
		print("The barrier has fallen! The way down to the 4th floor is now open.")

func show_popup(message: String) -> void:
	popup_text.text = message
	popup_text.show()
	popup_time_left = 2.0
	
func _process(delta: float) -> void:
	if popup_time_left > 0.0:
		popup_time_left -= delta
		if popup_time_left <= 0.0:
			popup_text.hide()
