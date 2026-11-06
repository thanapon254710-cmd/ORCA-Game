extends CanvasLayer

@onready var inventory = get_parent()
@onready var slots: HBoxContainer = $Root/Panel/Margin/Content/Slots
@onready var notice: Label = $Root/Notice
@onready var notice_timer: Timer = $NoticeTimer

func _ready() -> void:
    inventory.changed.connect(_refresh)
    inventory.item_collected.connect(_on_collected)
    notice_timer.timeout.connect(notice.hide)
    notice.hide()
    _refresh()

func _refresh() -> void:
    for slot in slots.get_children():
        var count: int = inventory.get_count(str(slot.name))
        slot.get_node("Content/Count").text = "x%d" % count
        slot.get_node("Content/Icon").modulate = Color.WHITE if count > 0 else Color(1, 1, 1, 0.25)

func _on_collected(item_id: String) -> void:
    notice.text = "Collected: " + str(inventory.ITEM_NAMES[item_id])
    notice.show()
    notice_timer.start()

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_I:
        $Root/Panel.visible = not $Root/Panel.visible
        get_viewport().set_input_as_handled()
