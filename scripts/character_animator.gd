extends Node3D
## Drives the 3D character model's animations from the parent CharacterBody3D.
## Loads the Open Animation Libraries (Melee / Shooter) retargeted via Mixamo_BoneMap.

@export var libraries := {
	"MeleeLib": "res://animations/MeleeLib.res",
	"ShooterLib": "res://animations/ShooterLib.res",
}
@export var run_speed_threshold := 0.3

var anim: AnimationPlayer
var body: CharacterBody3D
var _idle := ""
var _run := ""
var _attacks: Array[String] = []
var _hurt := ""
var _one_shot_busy := false
var _last_health := -1


func _ready() -> void:
	body = get_parent() as CharacterBody3D
	anim = _find_anim_player(self)
	if anim == null:
		push_warning("character_animator: no AnimationPlayer found in model")
		return
	for lib_name in libraries:
		var path: String = libraries[lib_name]
		if ResourceLoader.exists(path) and not anim.has_animation_library(lib_name):
			anim.add_animation_library(lib_name, load(path))
	_idle = _pick(["LightIdle", "Idle"])
	_run = _pick(["LightRunning", "Running", "Run", "Walk"])
	_hurt = _pick(["Hurt1", "Hurt"])
	for key in ["Slash1", "Slash2", "Slash3", "Stab1"]:
		var a := _pick([key])
		if a != "":
			_attacks.append(a)
	for a in [_idle, _run]:
		if a != "":
			anim.get_animation(a).loop_mode = Animation.LOOP_LINEAR
	anim.animation_finished.connect(func(_n): _one_shot_busy = false)
	if body and body.has_signal("health_changed"):
		body.health_changed.connect(_on_health_changed)
	print("character_animator: idle=%s run=%s attacks=%s" % [_idle, _run, _attacks])


func _process(_delta: float) -> void:
	if anim == null or body == null:
		return
	if Input.is_action_just_pressed("shoot") and not _attacks.is_empty():
		_play_once(_attacks.pick_random(), 1.6)
	if _one_shot_busy:
		return
	var speed := Vector2(body.velocity.x, body.velocity.z).length()
	var target := _run if speed > run_speed_threshold else _idle
	if target != "" and anim.current_animation != target:
		anim.play(target, 0.2)


func _play_once(a: String, speed := 1.0) -> void:
	_one_shot_busy = true
	anim.play(a, 0.1, speed)


func _on_health_changed(current: int, _max: int) -> void:
	if _last_health >= 0 and current < _last_health and _hurt != "":
		_play_once(_hurt, 1.5)
	_last_health = current


## Returns the first animation whose name contains one of the keys (library-aware).
func _pick(keys: Array) -> String:
	var names := anim.get_animation_list()
	for key in keys:
		for n in names:
			if n.get_file() == key or n.ends_with("/" + key) or n.ends_with("/" + key + "-loop"):
				return n
	for key in keys:
		for n in names:
			if key in n:
				return n
	return ""


func _find_anim_player(n: Node) -> AnimationPlayer:
	for c in n.get_children():
		if c is AnimationPlayer:
			return c
		var r := _find_anim_player(c)
		if r:
			return r
	return null
