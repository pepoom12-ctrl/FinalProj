extends Control
## Story text shown after the staff is chosen. The text types in slowly; a click
## (or key press) finishes it instantly, and once it is fully shown another
## click starts the first level.

const NEXT_SCENE := "res://scenes/l1_graveyard.tscn"
const CHARS_PER_SECOND := 32.0
const STORY := "The Arcane Vanguard's Extermination Mission: In this world, magical power is not merely for show; it is the deadliest weapon of war. When the continent's Arcane Cores destabilized and exploded, the leaking energy warped local lifeforms into frenzied monsters, raised undead hordes from abandoned graveyards, corrupted Elven warriors, and incited savage Orc armies to revolt. The High Council of Magic had no choice but to deploy the Battle-Magi—an elite frontline combat unit (the player)—dropping them into the heart of enemy territory to salvage the situation."

const Audio := preload("res://scripts/audio_manager.gd")

var _label: Label
var _prompt: Label
var _last_chars := 0
var _tween: Tween
var _done := false
var _age := 0.0
var _done_age := 0.0


func _ready() -> void:
	Audio.bgm("menu")
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_label = Label.new()
	_label.text = STORY
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(940, 0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 26)
	_label.visible_ratio = 0.0
	center.add_child(_label)
	_prompt = Label.new()
	_prompt.text = "Press anywhere to start"
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_prompt.add_theme_font_size_override("font_size", 22)
	_prompt.add_theme_color_override("font_color", Color(0.93, 0.88, 0.7))
	_prompt.anchor_left = 1.0
	_prompt.anchor_right = 1.0
	_prompt.anchor_top = 1.0
	_prompt.anchor_bottom = 1.0
	_prompt.offset_left = -380
	_prompt.offset_right = -36
	_prompt.offset_top = -64
	_prompt.offset_bottom = -28
	_prompt.modulate.a = 0.0
	add_child(_prompt)
	_tween = create_tween()
	_tween.tween_interval(0.8)
	_tween.tween_property(_label, "visible_ratio", 1.0, STORY.length() / CHARS_PER_SECOND)
	_tween.tween_callback(_finish)


func _process(delta: float) -> void:
	_age += delta
	if not _done:
		var chars := int(_label.visible_ratio * STORY.length())
		if chars - _last_chars >= 3:
			_last_chars = chars
			Audio.sfx("type_tick")
	if _done:
		_done_age += delta


func _finish() -> void:
	if _done:
		return
	_done = true
	if _tween:
		_tween.kill()
	_label.visible_ratio = 1.0
	var t := create_tween()
	t.tween_property(_prompt, "modulate:a", 1.0, 0.6)


func _input(event: InputEvent) -> void:
	if _age < 0.4:
		return
	var pressed := false
	if event is InputEventMouseButton:
		pressed = (event as InputEventMouseButton).pressed
	elif event is InputEventKey:
		var k := event as InputEventKey
		pressed = k.pressed and not k.echo
	elif event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	if not _done:
		Audio.sfx("ui_click")
		_finish()
	elif _done_age > 0.3:
		Audio.sfx("ui_click")
		set_process_input(false)
		get_tree().change_scene_to_file(NEXT_SCENE)
