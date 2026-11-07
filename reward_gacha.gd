extends CanvasLayer

signal reward_claimed(item_data: Dictionary)
signal gacha_closed
var _reward_claimed := false

@onready var title_label: Label = $BackgroundDim/RewardCard/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $BackgroundDim/RewardCard/VBoxContainer/SubtitleLabel
@onready var item_image_box: CenterContainer = $BackgroundDim/RewardCard/VBoxContainer/ItemImageBox
@onready var item_texture: TextureRect = $BackgroundDim/RewardCard/VBoxContainer/ItemImageBox/ItemTexture
@onready var item_name_label: Label = $BackgroundDim/RewardCard/VBoxContainer/ItemNameLabel
@onready var item_rarity_label: Label = $BackgroundDim/RewardCard/VBoxContainer/ItemRarityLabel
@onready var item_desc_label: Label = $BackgroundDim/RewardCard/VBoxContainer/ItemDescLabel
@onready var roll_button: Button = $BackgroundDim/RewardCard/VBoxContainer/RollButton
@onready var claim_button: Button = $BackgroundDim/RewardCard/VBoxContainer/ClaimButton

# สีประจำระดับความหายาก (ใช้แต่งตัวหนังสือและกรอบรูป)
const RARITY_COLORS = {
	"Common": Color(0.75, 0.75, 0.75),       # สีเทาเงิน
	"Rare": Color(0.25, 0.65, 1.0),          # สีฟ้าประกาย
	"Epic": Color(0.85, 0.35, 1.0)           # สีม่วงทอง
}

# Loot Pool พร้อมคำแปลสองภาษา (TH/EN) และการระบุช่วงสุ่ม Stat แบบ PCG
const LOOT_POOL = {
	"Common": [
		{
			"id": "hello_honors",
			"name_th": "เกียรตินิยมอันดับฮัลโหล",
			"name_en": "First-Class 'Hello' Honors",
			"stat_min": 5, "stat_max": 20,
			"desc_th": "คุณจะติดคำสาปให้พูดฮัลโหลใส่โทรศัพท์ จำนวน %d ครั้ง",
			"desc_en": "Cursed to say 'Hello' into the phone %d times.",
			"icon": "res://data/picture/gacha1.png" # ใส่ Path รูปภาพตรงนี้ เช่น "res://data/picture/hello.png"
		},
		{
			"id": "bangkadi_black_cat",
			"name_th": "แมวดำบางกะดี",
			"name_en": "Bangkadi Black Cat",
			"stat_min": 1, "stat_max": 10,
			"desc_th": "ความโชคดีที่ทำให้ได้เจอข้าวร้าน 2 เปิด: %d%%",
			"desc_en": "Luck bonus to find Stall 2 open: %d%%",
			"icon": "res://data/picture/gacha2.png"
		},
		{
			"id": "old_elevator",
			"name_th": "ลิฟต์เก่าๆบางกะดี",
			"name_en": "Old Bangkadi Elevator",
			"stat_min": 30, "stat_max": 70,
			"desc_th": "ความโชคร้ายในการโดนประตูลิฟต์หนีบ: %d%%",
			"desc_en": "Misfortune rate of getting clamped by doors: %d%%",
			"icon": "res://data/picture/gacha3.png"
		},
		{
			"id": "starbucks_card",
			"name_th": "บัตรเติมเงินสตาร์บัค",
			"name_en": "Starbucks Card",
			"stat_min": 10, "stat_max": 500,
			"desc_th": "ยอดเงินคงเหลือในบัตร: %d บาท",
			"desc_en": "Remaining card balance: %d THB",
			"icon": "res://data/picture/gacha4.png"
		}
	],
	"Rare": [
		{
			"id": "wheeled_desk",
			"name_th": "โต๊ะเลคเชอร์มีล้อ (แบร่ๆ)",
			"name_en": "Wheeled Lecture Desk (Bleh!)",
			"stat_min": 20, "stat_max": 50,
			"desc_th": "อัตราการสร้างความวุ่นวายในห้องเรียน: %d%%",
			"desc_en": "Classroom chaos creation rate: %d%%",
			"icon": "res://data/picture/gacha5.png"
		},
		{
			"id": "unsealed_iot_box",
			"name_th": "IoT Box ที่ปิดฝาไม่สนิท",
			"name_en": "Unsealed IoT Project Box",
			"stat_min": 15, "stat_max": 40,
			"desc_th": "โอกาสทำอุปกรณ์ข้างในเทกระจาด: %d%%",
			"desc_en": "Chance of components spilling out: %d%%",
			"icon": "res://data/picture/gacha6.png"
		},
		{
			"id": "free_taxi_rangsit",
			"name_th": "แท็กซี่ฟรีกลับรังสิต",
			"name_en": "Free Taxi to Rangsit",
			"stat_min": 20, "stat_max": 120,
			"desc_th": "ความเร็วเฉลี่ยในการขับซิ่ง: %d กม./ชม.",
			"desc_en": "Cruising speed back to campus: %d km/h",
			"icon": "res://data/picture/gacha7.png"
		}
	],
	"Epic": [
		{
			"id": "cyber_shirt",
			"name_th": "เสื้อไซเบอร์ที่เปลี่ยนลวดลายทุกวีค",
			"name_en": "Weekly Pattern-Shifting Cyber Jersey",
			"stat_min": 5, "stat_max": 50,
			"desc_th": "โชคดีในการเดาช้อยส์ข้อสอบ: +%d%%",
			"desc_en": "Exam guess accuracy bonus: +%d%%",
			"icon": "res://data/picture/gacha8.png"
		},
		{
			"id": "infinite_projects",
			"name_th": "โปรเจกต์ 6 ตัวที่ทำไม่จบไม่สิ้น",
			"name_en": "The Endless 6 Projects",
			"stat_min": 10, "stat_max": 90,
			"desc_th": "ระดับความยากของโปรเจกต์: %d%%",
			"desc_en": "Project despair/difficulty rating: %d%%",
			"icon": "res://data/picture/gacha9.png"
		}
	]
}

var current_reward: Dictionary = {}

func _ready():
	_setup_typography_and_ui()
	
	roll_button.text = "🎲 สุ่มของรางวัล / Roll Reward (PCG)"
	claim_button.text = "ตกลง / Claim Item"
	claim_button.visible = false
	
	# ซ่อนข้อมูลรางวัลก่อนกดสุ่ม
	item_image_box.visible = false
	item_name_label.text = ""
	item_rarity_label.text = ""
	item_desc_label.text = ""
	
	roll_button.pressed.connect(_on_roll_pressed)
	claim_button.pressed.connect(_on_claim_pressed)

func _setup_typography_and_ui():
	# ปรับหัวเรื่องให้เด่นสองภาษา
	title_label.text = "🎉 คุณได้รับรางวัลที่หลบหนีออกจากที่นี่ได้!\nYou escaped! Claim your escape reward."
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 17)
	
	subtitle_label.text = "กดปุ่มด้านล่างเพื่อเริ่มการสุ่มแบบตามขั้นตอน (PCG)\nPress button below to trigger procedural loot generation."
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 13)
	subtitle_label.modulate = Color(0.85, 0.85, 0.85)
	
	# ปรับชื่อไอเทมให้ตัวใหญ่ เด่น สะดุดตา
	item_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_name_label.add_theme_font_size_override("font_size", 24)
	
	# ระดับความหายาก
	item_rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_rarity_label.add_theme_font_size_override("font_size", 14)
	
	# คำอธิบาย
	item_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_desc_label.add_theme_font_size_override("font_size", 15)
	item_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	# ล็อกขนาดรูปภาพให้พอดี ไม่เบี้ยว
	# ปรับขนาดรูปภาพไอเทมให้ใหญ่ขึ้น
	item_texture.custom_minimum_size = Vector2(200, 200)
	item_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

# --- Procedural Content Generation Engine ---
func generate_pcg_loot() -> Dictionary:
	var roll = randf() * 100.0
	var rarity = "Common"
	
	if roll < 60.0:
		rarity = "Common" # 60%
	elif roll < 90.0:
		rarity = "Rare"   # 30%
	else:
		rarity = "Epic"   # 10%
		
	var pool: Array = LOOT_POOL[rarity]
	var base_item: Dictionary = pool.pick_random()
	
	# Procedural Attribute: สุ่มตัวเลขตามช่วงของแต่ละไอเทม
	var rolled_val = randi_range(base_item["stat_min"], base_item["stat_max"])
	
	var item: Dictionary = {}
	item["rarity"] = rarity
	item["name_th"] = base_item["name_th"]
	item["name_en"] = base_item["name_en"]
	item["stat_val"] = rolled_val
	item["desc_th"] = base_item["desc_th"] % rolled_val
	item["desc_en"] = base_item["desc_en"] % rolled_val
	item["icon"] = base_item["icon"]
	return item

func _on_roll_pressed():
	roll_button.disabled = true
	roll_button.visible = false
	
	current_reward = generate_pcg_loot()
	var rarity = current_reward["rarity"]
	var theme_color = RARITY_COLORS[rarity]
	
	# 1. แสดงชื่อไอเทม 2 ภาษา ตัวหนา ชัดเจน
	item_name_label.text = "★ %s ★\n[%s]" % [current_reward["name_th"], current_reward["name_en"]]
	item_name_label.modulate = theme_color
	
	# 2. ป้ายระดับ Rarity
	item_rarity_label.text = "— %s RARITY —" % rarity.to_upper()
	item_rarity_label.modulate = theme_color
	
	# 3. คำอธิบายพร้อมค่า Stat สองภาษา
	item_desc_label.text = "%s\n(%s)" % [current_reward["desc_th"], current_reward["desc_en"]]
	
	# 4. แสดงรูปภาพ (หากยังไม่มีไฟล์รูป จะสร้างกล่องไอคอนสัญลักษณ์ให้สวยงาม)
	item_image_box.visible = true
	var icon_path = current_reward.get("icon", "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		item_texture.texture = load(icon_path)
		item_texture.modulate = Color.WHITE
	else:
		# วาด Placeholder แทนรูปภาพ เพื่อให้เห็นกรอบสวยๆ ไม่โล่ง
		var img = Image.create(100, 100, false, Image.FORMAT_RGBA8)
		img.fill(Color(theme_color.r, theme_color.g, theme_color.b, 0.35))
		item_texture.texture = ImageTexture.create_from_image(img)
		item_texture.modulate = Color.WHITE
		
	subtitle_label.text = "ยินดีด้วย! คุณได้รับไอเทมพิเศษ / Item Obtained!"
	claim_button.visible = true

func _on_claim_pressed():
	if _reward_claimed or current_reward.is_empty():
		return
	_reward_claimed = true
	claim_button.disabled = true
	SaveManager.latest_reward_name = str(current_reward.get("name_th", current_reward.get("name_en", current_reward.get("name", "Unknown Item"))))
	reward_claimed.emit(current_reward)
	hide()
	gacha_closed.emit()
