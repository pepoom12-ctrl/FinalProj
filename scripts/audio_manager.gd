extends Node
## Audio manager. No autoload needed: call the static functions from anywhere
##   const Audio := preload("res://scripts/audio_manager.gd")
##   Audio.sfx("ui_click")   Audio.bgm("menu")   Audio.loop_start("portal_hum")
## A persistent node is created under the scene-tree root on first use, so music
## keeps playing across scene changes. Sounds live in res://audio/ (replace any
## .wav with your own, same file name). Volumes are saved in user://settings.cfg.

const SFX_DIR := "res://audio/sfx/"
const MUSIC_DIR := "res://audio/music/"
const SETTINGS_PATH := "user://settings.cfg"
const POOL_SIZE := 16
const MUSIC_BASE_DB := -3.0

## Per-sound volume trim (dB) and minimum seconds between plays.
const TRIM := {
	"ui_hover": -10.0, "ui_click": -3.0, "ui_back": -3.0, "type_tick": -14.0,
	"fire_cast": -6.0, "ice_cast": -8.0, "lightning_cast": -9.0, "arrow_shoot": -7.0,
	"hit_enemy": -9.0, "enemy_die": -6.0, "strat_input": -10.0, "stone_hit": -6.0,
	"objective_tick": -6.0, "portal_hum": -9.0, "player_hurt": -3.0, "fireball": -4.0,
}
const GAP := {
	"hit_enemy": 0.05, "enemy_die": 0.05, "ice_cast": 0.12, "lightning_cast": 0.06,
	"stone_hit": 0.06, "ui_hover": 0.04, "type_tick": 0.03, "arrow_shoot": 0.08,
	"objective_tick": 0.05, "fireball": 0.05,
}
## Sounds that get a small random pitch change so repeats don't sound identical.
const VARY := ["hit_enemy", "enemy_die", "fire_cast", "ice_cast", "lightning_cast", "arrow_shoot", "stone_hit", "player_hurt"]

var music_volume_lin := 0.6
var sfx_volume_lin := 0.9

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer
var _music_name := ""
var _music_tween: Tween
var _loops := {}
var _last := {}
var _pending: Array = []


# ------------------------------------------------------------- static API

static func mgr() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	if tree.root.has_meta("audio_mgr"):
		var existing = tree.root.get_meta("audio_mgr")
		if is_instance_valid(existing):
			return existing
	var n: Node = (load("res://scripts/audio_manager.gd") as GDScript).new()
	n.name = "AudioManager"
	tree.root.set_meta("audio_mgr", n)
	tree.root.add_child.call_deferred(n)
	return n


static func sfx(sfx_name: String, pitch: float = 1.0, vol_db: float = 0.0) -> void:
	var m := mgr()
	if m:
		m._queue_or_run("_play_sfx", [sfx_name, pitch, vol_db])


static func bgm(track: String) -> void:
	var m := mgr()
	if m:
		m._queue_or_run("_play_bgm", [track])


static func bgm_stop() -> void:
	var m := mgr()
	if m:
		m._queue_or_run("_stop_bgm", [])


static func loop_start(loop_name: String) -> void:
	var m := mgr()
	if m:
		m._queue_or_run("_loop_start", [loop_name])


static func loop_stop(loop_name: String) -> void:
	var m := mgr()
	if m:
		m._queue_or_run("_loop_stop", [loop_name])


static func get_music_volume() -> float:
	var m := mgr()
	return m.music_volume_lin if m else 0.6


static func get_sfx_volume() -> float:
	var m := mgr()
	return m.sfx_volume_lin if m else 0.9


static func set_music_volume(v: float) -> void:
	var m := mgr()
	if m:
		m.music_volume_lin = clampf(v, 0.0, 1.0)
		m._apply_volumes()
		m._save_settings()


static func set_sfx_volume(v: float) -> void:
	var m := mgr()
	if m:
		m.sfx_volume_lin = clampf(v, 0.0, 1.0)
		m._apply_volumes()
		m._save_settings()


# --------------------------------------------------------------- instance

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus("Music")
	_ensure_bus("SFX")
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	_load_settings()
	_apply_volumes()
	for c in _pending:
		callv(c[0], c[1])
	_pending.clear()


func _queue_or_run(method: String, args: Array) -> void:
	if not is_inside_tree():
		_pending.append([method, args])
	else:
		callv(method, args)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")


func _apply_volumes() -> void:
	var mi := AudioServer.get_bus_index("Music")
	var si := AudioServer.get_bus_index("SFX")
	if mi != -1:
		AudioServer.set_bus_volume_db(mi, linear_to_db(maxf(music_volume_lin, 0.0001)))
		AudioServer.set_bus_mute(mi, music_volume_lin <= 0.001)
	if si != -1:
		AudioServer.set_bus_volume_db(si, linear_to_db(maxf(sfx_volume_lin, 0.0001)))
		AudioServer.set_bus_mute(si, sfx_volume_lin <= 0.001)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		music_volume_lin = float(cfg.get_value("audio", "music", music_volume_lin))
		sfx_volume_lin = float(cfg.get_value("audio", "sfx", sfx_volume_lin))


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "music", music_volume_lin)
	cfg.set_value("audio", "sfx", sfx_volume_lin)
	cfg.save(SETTINGS_PATH)


func _stream(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream


func _looped(path: String) -> AudioStream:
	var s := _stream(path)
	if s is AudioStreamWAV:
		var w := (s as AudioStreamWAV).duplicate() as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = int(w.get_length() * w.mix_rate)
		return w
	return s


func _free_player() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	_next = (_next + 1) % _players.size()
	return _players[_next]


func _play_sfx(sfx_name: String, pitch: float, vol_db: float) -> void:
	var now := Time.get_ticks_msec()
	var gap: float = GAP.get(sfx_name, 0.0)
	if now - int(_last.get(sfx_name, -100000)) < int(gap * 1000.0):
		return
	_last[sfx_name] = now
	var s := _stream(SFX_DIR + sfx_name + ".wav")
	if s == null:
		return
	var p := _free_player()
	p.stream = s
	p.pitch_scale = pitch * (randf_range(0.92, 1.08) if sfx_name in VARY else 1.0)
	p.volume_db = float(TRIM.get(sfx_name, 0.0)) + vol_db
	p.play()


func _play_bgm(track: String) -> void:
	if track == _music_name and _music.playing:
		return
	_music_name = track
	var s := _looped(MUSIC_DIR + track + ".wav")
	if s == null:
		return
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween()
	if _music.playing:
		_music_tween.tween_property(_music, "volume_db", -40.0, 0.5)
	_music_tween.tween_callback(func():
		_music.stream = s
		_music.volume_db = -40.0
		_music.play())
	_music_tween.tween_property(_music, "volume_db", MUSIC_BASE_DB, 1.2)


func _stop_bgm() -> void:
	_music_name = ""
	if _music_tween:
		_music_tween.kill()
	if _music.playing:
		_music_tween = create_tween()
		_music_tween.tween_property(_music, "volume_db", -40.0, 0.6)
		_music_tween.tween_callback(_music.stop)


func _loop_start(loop_name: String) -> void:
	if _loops.has(loop_name) and is_instance_valid(_loops[loop_name]) and _loops[loop_name].playing:
		return
	var s := _looped(SFX_DIR + loop_name + ".wav")
	if s == null:
		return
	var p := AudioStreamPlayer.new()
	p.bus = "SFX"
	p.stream = s
	p.volume_db = float(TRIM.get(loop_name, 0.0))
	add_child(p)
	p.play()
	_loops[loop_name] = p


func _loop_stop(loop_name: String) -> void:
	if _loops.has(loop_name):
		var p = _loops[loop_name]
		_loops.erase(loop_name)
		if is_instance_valid(p):
			var t := create_tween()
			t.tween_property(p, "volume_db", -40.0, 0.4)
			t.tween_callback(p.queue_free)
