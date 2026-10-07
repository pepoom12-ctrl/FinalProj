extends CanvasLayer
## HUD: health, wave, objectives list, nearest-objective pointer, extraction,
## stratagem cooldowns/cheat-sheet, boss bar, intro banner and death screen.
## Arrows are drawn icons (arrow_icon.gd), not font glyphs, so they also work
## in web exports.

const ArrowIcon := preload("res://scripts/arrow_icon.gd")

const DIR_ANGLE := {"ui_up": 0.0, "ui_right": 90.0, "ui_down": 180.0, "ui_left": 270.0}

@onready var health_bar: ProgressBar = $Margin/VBox/HealthBar
@onready var health_label: Label = $Margin/VBox/HealthBar/HealthLabel
@onready var wave_label: Label = $Margin/VBox/WaveLabel
@onready var level_label: Label = $Margin/VBox/LevelLabel
@onready var stratagem_label: Label = $Margin/VBox/StratagemLabel
@onready var objective_label: Label = $Margin/VBox/ObjectiveLabel
@onready var extraction_label: Label = $Margin/VBox/ExtractionLabel
@onready var stratagem_help: PanelContainer = $StratagemHelp
@onready var stratagem_help_label: Label = $StratagemHelp/Label
@onready var input_echo: Label = $InputEcho
@onready var confirm_prompt: Label = $ConfirmPrompt

var _player: Node = null
var _level_manager: Node = null
var _om: Node = null
var _boss: Node = null
var _pointer: HBoxContainer
var _pointer_icon: Control
var _pointer_label: Label
var _echo_row: HBoxContainer
var _codes_box: VBoxContainer
var _boss_box: VBoxContainer
var _boss_bar: ProgressBar
var _dead := false


func _ready() -> void:
	for l in [objective_label, extraction_label]:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(430, 0)
	_build_pointer()
	_build_echo()
	_build_boss_bar()
	call_deferred("_connect_signals")


func _arrow_row(codes: Array, icon: float, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	for d in codes:
		var a: Control = ArrowIcon.new()
		a.icon_size = icon
		a.angle_deg = DIR_ANGLE.get(d, 0.0)
		a.color = color
		row.add_child(a)
	return row


func _build_pointer() -> void:
	_pointer = HBoxContainer.new()
	_pointer.anchor_left = 0.5
	_pointer.anchor_right = 0.5
	_pointer.offset_left = -300
	_pointer.offset_right = 300
	_pointer.offset_top = 70
	_pointer.alignment = BoxContainer.ALIGNMENT_CENTER
	_pointer.add_theme_constant_override("separation", 8)
	_pointer_icon = ArrowIcon.new()
	_pointer_icon.icon_size = 26.0
	_pointer_icon.color = Color(1.0, 0.9, 0.4)
	_pointer.add_child(_pointer_icon)
	_pointer_label = Label.new()
	_pointer_label.add_theme_font_size_override("font_size", 20)
	_pointer.add_child(_pointer_label)
	_pointer.visible = false
	add_child(_pointer)


func _build_echo() -> void:
	input_echo.visible = false
	_echo_row = HBoxContainer.new()
	_echo_row.anchor_left = 0.5
	_echo_row.anchor_right = 0.5
	_echo_row.anchor_top = 1.0
	_echo_row.anchor_bottom = 1.0
	_echo_row.offset_left = -150
	_echo_row.offset_right = 150
	_echo_row.offset_top = -125
	_echo_row.offset_bottom = -85
	_echo_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_echo_row.add_theme_constant_override("separation", 6)
	add_child(_echo_row)


func _build_boss_bar() -> void:
	_boss_box = VBoxContainer.new()
	_boss_box.anchor_left = 0.5
	_boss_box.anchor_right = 0.5
	_boss_box.offset_left = -260
	_boss_box.offset_right = 260
	_boss_box.offset_top = 12
	_boss_box.visible = false
	var nm := Label.new()
	nm.text = "ORCISH WARLORD"
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_color_override("font_color", Color(1.0, 0.45, 0.3))
	_boss_box.add_child(nm)
	_boss_bar = ProgressBar.new()
	_boss_bar.custom_minimum_size = Vector2(520, 20)
	_boss_bar.show_percentage = false
	_boss_box.add_child(_boss_bar)
	add_child(_boss_box)


func _connect_signals() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]
		_player.health_changed.connect(_on_health_changed)
		_player.stratagem_called.connect(_on_stratagem_called)
		_player.input_buffer_changed.connect(_on_input_buffer_changed)
		_player.stratagem_targeting_started.connect(_on_targeting_started)
		_player.stratagem_targeting_ended.connect(_on_targeting_ended)
		_player.notice.connect(_on_notice)
		_player.died.connect(_on_player_died)
		_on_health_changed(_player.current_health, _player.max_health)
		_build_stratagem_help()
		var weapon_label := Label.new()
		weapon_label.text = "Weapon: %s" % _player.STAFF_CONFIG[_player.current_staff]["name"]
		$Margin/VBox.add_child(weapon_label)

	var managers := get_tree().get_nodes_in_group("level_manager")
	if managers.size() > 0:
		_level_manager = managers[0]
		_level_manager.wave_started.connect(_on_wave_started)
		_level_manager.wave_cleared.connect(_on_wave_cleared)
		if "level_name" in _level_manager:
			level_label.text = _level_manager.level_name

	for om in get_tree().get_nodes_in_group("objective_manager"):
		_om = om
		om.objective_changed.connect(func(_id): _refresh_objectives())
	_refresh_objectives()
	_show_intro_banner()

	for ez in get_tree().get_nodes_in_group("extraction_zone"):
		ez.armed.connect(_on_extraction_armed)
		ez.opened.connect(_on_extraction_opened)
		ez.countdown_tick.connect(_on_extraction_tick)

	for b in get_tree().get_nodes_in_group("boss"):
		_boss = b
		b.health_changed.connect(_on_boss_hp)


func _on_boss_hp(cur: int, mx: int) -> void:
	_boss_box.visible = cur > 0
	_boss_bar.max_value = mx
	_boss_bar.value = cur


func _refresh_objectives() -> void:
	if _om == null:
		return
	var lines: Array[String] = []
	for ln in _om.get_lines():
		var tag := "MAIN" if ln["main"] else "SIDE"
		var mark := "[X]" if ln["done"] >= ln["total"] else "[ ]"
		lines.append("%s %s: %s (%d/%d)" % [mark, tag, ln["text"], ln["done"], ln["total"]])
	objective_label.text = "\n".join(lines)


func _show_intro_banner() -> void:
	if _om == null:
		return
	var mains: Array[String] = []
	var sides: Array[String] = []
	for ln in _om.get_lines():
		var s: String = "- %s (x%d)" % [ln["text"], ln["total"]]
		if ln["main"]:
			mains.append(s)
		else:
			sides.append(s)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.88)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.offset_left = -330
	panel.offset_right = 330
	panel.offset_top = 100
	var lbl := Label.new()
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size = Vector2(620, 0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.text = "%s\n\nMAIN OBJECTIVES (required)\n%s\n\nSIDE OBJECTIVES (optional)\n%s\n\nWhen all MAIN objectives are done, go to the glowing Extraction zone and enter the rune code RIGHT, DOWN, LEFT, UP (hold Q to view the codes), then survive for 30 seconds." % [level_label.text, "\n".join(mains), "\n".join(sides)]
	panel.add_child(lbl)
	add_child(panel)
	var tw := create_tween()
	tw.tween_interval(12.0)
	tw.tween_property(panel, "modulate:a", 0.0, 1.5)
	tw.tween_callback(panel.queue_free)


func _build_stratagem_help() -> void:
	stratagem_help_label.visible = false
	stratagem_help.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	stratagem_help.grow_vertical = Control.GROW_DIRECTION_BOTH
	_codes_box = VBoxContainer.new()
	_codes_box.add_theme_constant_override("separation", 6)
	stratagem_help.add_child(_codes_box)
	var title := Label.new()
	title.text = "RUNE CODES"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	_codes_box.add_child(title)
	for key in _player.stratagems.keys():
		var nm := Label.new()
		nm.text = key.capitalize().replace("_", " ")
		nm.add_theme_font_size_override("font_size", 14)
		_codes_box.add_child(nm)
		_codes_box.add_child(_arrow_row(_player.stratagems[key]["code"], 22.0, Color(1.0, 0.9, 0.5)))


func _on_input_buffer_changed(buffer: Array) -> void:
	for c in _echo_row.get_children():
		_echo_row.remove_child(c)
		c.queue_free()
	for d in buffer:
		var a: Control = ArrowIcon.new()
		a.icon_size = 34.0
		a.angle_deg = DIR_ANGLE.get(d, 0.0)
		a.color = Color(1.0, 0.95, 0.6)
		_echo_row.add_child(a)


func _on_targeting_started(key: String) -> void:
	confirm_prompt.text = "%s ready - aim and click to drop" % key.capitalize().replace("_", " ")
	confirm_prompt.visible = true


func _on_targeting_ended() -> void:
	confirm_prompt.visible = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("show_stratagems"):
		stratagem_help.visible = true
	elif event.is_action_released("show_stratagems"):
		stratagem_help.visible = false


func _on_health_changed(current: int, max_hp: int) -> void:
	health_bar.max_value = max_hp
	health_bar.value = current
	health_label.text = "%d / %d HP" % [current, max_hp]


func _on_wave_started(wave_index: int, _total_waves: int) -> void:
	wave_label.text = "Wave %d" % (wave_index + 1)


func _on_wave_cleared(wave_index: int) -> void:
	wave_label.text = "Wave %d cleared!" % (wave_index + 1)


func _on_stratagem_called(stratagem_name: String) -> void:
	stratagem_label.text = "Called: %s" % stratagem_name.capitalize()


func _on_extraction_armed() -> void:
	extraction_label.text = "EXTRACTION READY - stand at the zone and enter the Open Extraction code (Hold Q)"


func _on_extraction_opened() -> void:
	extraction_label.text = "Extraction opened! Survive..."


func _on_notice(text: String) -> void:
	extraction_label.text = text


func _on_extraction_tick(seconds_left: float) -> void:
	extraction_label.text = "Extracting... %.0fs" % seconds_left


func _on_player_died() -> void:
	if _dead:
		return
	_dead = true
	get_tree().paused = true
	var layer := Control.new()
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0.25, 0.0, 0.0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	var title := Label.new()
	title.text = "YOU DIED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 80)
	title.add_theme_color_override("font_color", Color(1.0, 0.25, 0.2))
	box.add_child(title)
	var sub := Label.new()
	sub.text = level_label.text
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)
	var restart := Button.new()
	restart.text = "RESTART THIS LEVEL"
	restart.custom_minimum_size = Vector2(300, 56)
	restart.add_theme_font_size_override("font_size", 24)
	restart.pressed.connect(func():
		get_tree().paused = false
		get_tree().call_deferred("reload_current_scene"))
	box.add_child(restart)
	var menu := Button.new()
	menu.text = "MAIN MENU"
	menu.custom_minimum_size = Vector2(300, 56)
	menu.add_theme_font_size_override("font_size", 24)
	menu.pressed.connect(func():
		get_tree().paused = false
		get_tree().call_deferred("change_scene_to_file", "res://scenes/main_menu.tscn"))
	box.add_child(menu)


func _nearest_target() -> Dictionary:
	var want_main: bool = _om != null and not _om.main_finished()
	var carrying: bool = _player != null and is_instance_valid(_player) and _player.carrying_item
	var best: Node3D = null
	var best_d := 1e9
	var best_name := ""
	if want_main:
		for n in get_tree().get_nodes_in_group("objective_prop"):
			if not is_instance_valid(n) or n.get("finished") == true:
				continue
			if n.get("hud_main") != true:
				continue
			if n.get("needs_carry") == true and not carrying:
				continue
			var d: float = Vector2(n.global_position.x - _player.global_position.x, n.global_position.z - _player.global_position.z).length()
			if d < best_d:
				best_d = d
				best = n
				best_name = str(n.get("hud_name"))
	else:
		for ez in get_tree().get_nodes_in_group("extraction_zone"):
			if ez.get("_unlocked") == true and ez.get("_started") != true:
				best = ez
				best_name = "Extraction Zone"
				best_d = Vector2(ez.global_position.x - _player.global_position.x, ez.global_position.z - _player.global_position.z).length()
	if best == null:
		return {}
	return {"node": best, "name": best_name, "dist": best_d}


func _update_pointer() -> void:
	if _player == null or not is_instance_valid(_player) or _dead:
		_pointer.visible = false
		return
	var t := _nearest_target()
	if t.is_empty():
		_pointer.visible = false
		return
	var n: Node3D = t["node"]
	var dx: float = n.global_position.x - _player.global_position.x
	var dz: float = n.global_position.z - _player.global_position.z
	_pointer.visible = true
	_pointer_icon.set_angle(rad_to_deg(atan2(dx, -dz)))
	_pointer_label.text = "%s  %d m" % [t["name"], int(t["dist"])]


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var parts: Array[String] = []
	for key in _player.stratagems.keys():
		var cd: float = _player._stratagem_cooldowns.get(key, 0.0)
		if cd > 0.0:
			parts.append("%s: %.1fs" % [key.capitalize(), cd])
		else:
			parts.append("%s: READY" % key.capitalize())
	stratagem_label.text = "  |  ".join(parts)
	_update_pointer()
