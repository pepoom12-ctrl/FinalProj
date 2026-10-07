extends Control
## Main menu: PLAY -> choose 1 of 3 staves -> start Level 1.

const FIRST_LEVEL := "res://scenes/l1_graveyard.tscn"

const STAVES := [
	{
		"name": "Inferno Staff",
		"role": "Burst Damage & AOE",
		"desc": "Heavy fireballs that explode on impact and burn nearby enemies. Slow fire rate, huge damage.",
		"color": Color(1.0, 0.5, 0.2),
	},
	{
		"name": "Glacier Staff",
		"role": "Crowd Control",
		"desc": "Fast frost bolts that slow every enemy they hit. Low damage, perfect for kiting the horde.",
		"color": Color(0.5, 0.85, 1.0),
	},
	{
		"name": "Tempest Staff",
		"role": "Fast DPS & Chain Damage",
		"desc": "Rapid lightning that arcs between nearby enemies. Low damage per hit, extreme fire rate.",
		"color": Color(1.0, 0.9, 0.3),
	},
]

var _main_page: Control
var _weapon_page: Control


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.08)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_main_page = _build_main_page()
	_weapon_page = _build_weapon_page()
	add_child(_main_page)
	add_child(_weapon_page)
	_show_page(_main_page)


func _show_page(page: Control) -> void:
	_main_page.visible = page == _main_page
	_weapon_page.visible = page == _weapon_page


func _center_page() -> CenterContainer:
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	return c


func _label(text: String, font_size: int, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _button(text: String, font_size: int = 24) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(260, 56)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", font_size)
	return b


func _build_main_page() -> Control:
	var page := _center_page()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	box.add_child(_label("MAGIC MAYHEM", 72, Color(1.0, 0.75, 0.3)))
	box.add_child(_label("Hardcore PvE Swarm Survival | Arcane Action Shooter", 20, Color(0.6, 0.85, 1.0)))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	box.add_child(spacer)
	var play := _button("PLAY")
	play.pressed.connect(func(): _show_page(_weapon_page))
	box.add_child(play)
	var quit := _button("QUIT")
	quit.pressed.connect(func(): get_tree().quit())
	box.add_child(quit)
	page.add_child(box)
	return page


func _build_weapon_page() -> Control:
	var page := _center_page()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	box.add_child(_label("CHOOSE YOUR STAFF", 44, Color(1.0, 0.85, 0.4)))
	box.add_child(_label("Your staff is locked in for the whole run.", 18, Color(0.8, 0.8, 0.8)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in STAVES.size():
		row.add_child(_build_staff_card(i))
	box.add_child(row)
	var back := _button("BACK")
	back.pressed.connect(func(): _show_page(_main_page))
	box.add_child(back)
	page.add_child(box)
	return page


func _build_staff_card(i: int) -> Control:
	var s: Dictionary = STAVES[i]
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.13, 0.95)
	style.border_color = s["color"]
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(300, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.add_child(_label(s["name"], 28, s["color"]))
	v.add_child(_label(s["role"], 18, Color(0.9, 0.9, 0.9)))
	var d := _label(s["desc"], 16, Color(0.75, 0.75, 0.8))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(260, 90)
	v.add_child(d)
	var b := _button("SELECT", 22)
	b.custom_minimum_size = Vector2(200, 50)
	b.pressed.connect(_on_staff_selected.bind(i))
	v.add_child(b)
	panel.add_child(v)
	return panel


func _on_staff_selected(index: int) -> void:
	ProjectSettings.set_setting("magic_mayhem/selected_staff", index)
	get_tree().change_scene_to_file(FIRST_LEVEL)
