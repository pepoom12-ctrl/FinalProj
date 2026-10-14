extends Control
## Main menu: START -> choose a staff -> story -> level 1.  OPTION -> BGM / SFX volume.
##
## The menu is just a picture: put your art at res://ui/menu_bg.png (or .jpg /
## .webp). It is stretched to cover the screen and the START / OPTION buttons
## are placed on top. When a picture exists, the title and subtitle are NOT drawn
## (draw them in the picture). Without a picture you get a plain dark screen with
## the title text.
## Optional: res://ui/logo.png is shown as the title instead of the title text.

const Audio := preload("res://scripts/audio_manager.gd")

const FIRST_LEVEL := "res://scenes/story_intro.tscn"  # story text, then it starts level 1

## false = START / OPTION become invisible click areas (use this when your picture
## already has the START / OPTION buttons drawn on it).
const DRAW_BUTTON_BOX := true

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
var _options_page: Control


func _ready() -> void:
	Audio.bgm("menu")
	var has_bg := _build_background()
	_main_page = _build_main_page(has_bg)
	_weapon_page = _build_weapon_page()
	_options_page = _build_options_page()
	add_child(_main_page)
	add_child(_weapon_page)
	add_child(_options_page)
	_show_page(_main_page)


func _show_page(page: Control) -> void:
	_main_page.visible = page == _main_page
	_weapon_page.visible = page == _weapon_page
	_options_page.visible = page == _options_page


# ---------------------------------------------------------------- helpers

func _first_existing(paths: Array) -> String:
	for p in paths:
		if ResourceLoader.exists(p):
			return p
	return ""


func _label(text: String, font_size: int, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _box_style(color: Color, border: Color = Color(0, 0, 0, 0), border_w: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_content_margin_all(10)
	return s


func _button(text: String, font_size: int = 30) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(280, 60)
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.55))
	b.add_theme_stylebox_override("normal", _box_style(Color(0.04, 0.06, 0.09, 0.55)))
	b.add_theme_stylebox_override("hover", _box_style(Color(0.08, 0.1, 0.16, 0.78), Color(1.0, 0.85, 0.4, 0.8), 2))
	b.add_theme_stylebox_override("pressed", _box_style(Color(0.02, 0.03, 0.05, 0.85), Color(1.0, 0.85, 0.4, 0.8), 2))
	b.add_theme_stylebox_override("focus", _box_style(Color(0, 0, 0, 0)))
	b.mouse_entered.connect(func(): Audio.sfx("ui_hover"))
	return b


## START / OPTION on the main page (optionally invisible click areas).
func _menu_button(text: String) -> Button:
	var b := _button(text, 34)
	if not DRAW_BUTTON_BOX:
		var clear := Color(0, 0, 0, 0)
		b.add_theme_color_override("font_color", clear)
		b.add_theme_color_override("font_hover_color", clear)
		b.add_theme_stylebox_override("normal", _box_style(clear))
		b.add_theme_stylebox_override("hover", _box_style(Color(1, 1, 1, 0.08)))
		b.add_theme_stylebox_override("pressed", _box_style(Color(1, 1, 1, 0.14)))
	return b


func _place(c: Control, ax: float, ay: float, w: float, h: float) -> void:
	c.anchor_left = ax
	c.anchor_right = ax
	c.anchor_top = ay
	c.anchor_bottom = ay
	c.offset_left = -w * 0.5
	c.offset_right = w * 0.5
	c.offset_top = -h * 0.5
	c.offset_bottom = h * 0.5


func _center_page() -> CenterContainer:
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	return c


# ------------------------------------------------------------- background

## Returns true when a picture was found.
func _build_background() -> bool:
	var bg := _first_existing(["res://ui/menu_bg.png", "res://ui/menu_bg.jpg", "res://ui/menu_bg.webp"])
	if bg != "":
		var tr := TextureRect.new()
		tr.texture = load(bg)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tr)
		return true
	var plain := ColorRect.new()
	plain.color = Color(0.03, 0.04, 0.09)
	plain.set_anchors_preset(Control.PRESET_FULL_RECT)
	plain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(plain)
	return false


# -------------------------------------------------------------- main page

func _build_main_page(has_bg: bool) -> Control:
	var page := Control.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var logo := _first_existing(["res://ui/logo.png", "res://ui/logo.webp"])
	if logo != "":
		var tr := TextureRect.new()
		tr.texture = load(logo)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place(tr, 0.5, 0.2, 560.0, 190.0)
		page.add_child(tr)
	elif not has_bg:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 18)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		_place(row, 0.5, 0.19, 900.0, 130.0)
		var magic := _label("MAGIC", 104, Color(0.62, 0.55, 1.0))
		magic.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.3))
		magic.add_theme_constant_override("outline_size", 14)
		var mayhem := _label("MAYHEM", 104, Color(1.0, 0.58, 0.18))
		mayhem.add_theme_color_override("font_outline_color", Color(0.4, 0.05, 0.0))
		mayhem.add_theme_constant_override("outline_size", 14)
		row.add_child(magic)
		row.add_child(mayhem)
		page.add_child(row)

	if not has_bg:
		var sub := _label("Hardcore PvE Swarm Survival \u2022 Arcane Action Shooter", 22, Color(0.95, 0.95, 1.0))
		_place(sub, 0.5, 0.41, 900.0, 36.0)
		page.add_child(sub)

	var start := _menu_button("START")
	_place(start, 0.29, 0.72, 280.0, 62.0)
	start.pressed.connect(func():
		Audio.sfx("ui_click")
		_show_page(_weapon_page))
	page.add_child(start)

	var option := _menu_button("OPTION")
	_place(option, 0.71, 0.72, 280.0, 62.0)
	option.pressed.connect(func():
		Audio.sfx("ui_click")
		_show_page(_options_page))
	page.add_child(option)
	return page


# ------------------------------------------------------------ weapon page

func _build_weapon_page() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	# darken the picture a bit so the cards are readable
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var page := _center_page()
	root.add_child(page)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	box.add_child(_label("CHOOSE YOUR STAFF", 46, Color(1.0, 0.85, 0.4)))
	box.add_child(_label("Your staff is locked in for the whole run.", 18, Color(0.85, 0.85, 0.9)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in STAVES.size():
		row.add_child(_build_staff_card(i))
	box.add_child(row)
	var back := _button("BACK", 26)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func():
		Audio.sfx("ui_back")
		_show_page(_main_page))
	box.add_child(back)
	page.add_child(box)
	root.visible = false
	return root


func _build_staff_card(i: int) -> Control:
	var s: Dictionary = STAVES[i]
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.add_child(_label(s["name"], 28, s["color"]))
	v.add_child(_label(s["role"], 18, Color(0.9, 0.9, 0.9)))
	var d := _label(s["desc"], 16, Color(0.78, 0.78, 0.85))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(260, 90)
	v.add_child(d)
	var b := _button("SELECT", 22)
	b.custom_minimum_size = Vector2(200, 50)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(_on_staff_selected.bind(i))
	v.add_child(b)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box_style(Color(0.04, 0.05, 0.09, 0.85), s["color"], 3))
	panel.custom_minimum_size = Vector2(300, 0)
	panel.add_child(v)
	return panel


func _on_staff_selected(index: int) -> void:
	ProjectSettings.set_setting("magic_mayhem/selected_staff", index)
	Audio.sfx("select_weapon")
	await get_tree().create_timer(0.4).timeout
	get_tree().change_scene_to_file(FIRST_LEVEL)


# ----------------------------------------------------------- options page

func _build_options_page() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var page := _center_page()
	root.add_child(page)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	box.custom_minimum_size = Vector2(520, 0)
	box.add_child(_label("OPTIONS", 44, Color(1.0, 0.85, 0.4)))
	box.add_child(_slider_row("Music (BGM)", Audio.get_music_volume(), func(v): Audio.set_music_volume(v), false))
	box.add_child(_slider_row("Sound Effects (SFX)", Audio.get_sfx_volume(), func(v): Audio.set_sfx_volume(v), true))
	var back := _button("BACK", 26)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func():
		Audio.sfx("ui_back")
		_show_page(_main_page))
	box.add_child(back)
	page.add_child(_panel_wrap(box))
	root.visible = false
	return root


func _panel_wrap(inner: Control) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _box_style(Color(0.03, 0.04, 0.08, 0.85), Color(0.5, 0.45, 0.3, 0.5), 2))
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 30)
	m.add_theme_constant_override("margin_right", 30)
	m.add_theme_constant_override("margin_top", 24)
	m.add_theme_constant_override("margin_bottom", 24)
	m.add_child(inner)
	p.add_child(m)
	return p


func _slider_row(title: String, start: float, on_change: Callable, preview_sfx: bool) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	var head := HBoxContainer.new()
	var name_l := Label.new()
	name_l.text = title
	name_l.add_theme_font_size_override("font_size", 22)
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_l)
	var val_l := Label.new()
	val_l.text = "%d%%" % int(round(start * 100.0))
	val_l.add_theme_font_size_override("font_size", 22)
	head.add_child(val_l)
	v.add_child(head)
	var sl := HSlider.new()
	sl.min_value = 0.0
	sl.max_value = 100.0
	sl.step = 1.0
	sl.value = start * 100.0
	sl.custom_minimum_size = Vector2(460, 30)
	sl.value_changed.connect(func(x):
		val_l.text = "%d%%" % int(x)
		on_change.call(x / 100.0))
	if preview_sfx:
		sl.drag_ended.connect(func(_changed): Audio.sfx("ui_click"))
	v.add_child(sl)
	return v
