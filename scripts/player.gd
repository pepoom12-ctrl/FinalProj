extends CharacterBody3D
## Magic Mayhem player controller — 3D top-down (Helldivers 1 / Magicka style).
## Movement: WASD (world XZ plane). Aim/Shoot: Mouse (raycast to ground).
## Staff is chosen once in the main menu and locked for the run.
## Rune Stratagems: arrow-key combos, then aim + click to confirm (or instant).

signal health_changed(current: int, max: int)
signal died
signal staff_changed(staff_name: String)
signal input_buffer_changed(buffer: Array)
signal stratagem_targeting_started(key: String)
signal stratagem_targeting_ended
signal notice(text: String)

@export var move_speed: float = 7.0
@export var max_health: int = 100
@export var bullet_scene: PackedScene

var current_health: int
var carrying_item: bool = false
var pending_stratagem: String = ""
var _fire_timer: float = 0.0
var _aim_direction: Vector3 = Vector3.FORWARD
var _aim_ground_point: Vector3 = Vector3.ZERO

# Guards against a "shoot" held BEFORE targeting started: the confirm click
# must be a fresh press, so we wait for a release first if it was already
# down, and we auto-cancel if the player never confirms at all.
var _confirm_armed := false
var _targeting_timer := 0.0
const TARGETING_TIMEOUT: float = 8.0

enum Staff { FIRE, ICE, LIGHTNING }
var current_staff: Staff = Staff.FIRE

const STAFF_CONFIG := {
	Staff.FIRE: {
		"name": "Inferno Staff", "cooldown": 0.55, "damage": 22,
		"splash_radius": 2.0, "slow_factor": 0.0, "slow_duration": 0.0,
		"chain_count": 0, "color": Color(1.0, 0.45, 0.15),
	},
	Staff.ICE: {
		"name": "Glacier Staff", "cooldown": 0.3, "damage": 8,
		"splash_radius": 0.0, "slow_factor": 0.45, "slow_duration": 1.6,
		"chain_count": 0, "color": Color(0.55, 0.85, 1.0),
	},
	Staff.LIGHTNING: {
		"name": "Tempest Staff", "cooldown": 0.12, "damage": 7,
		"splash_radius": 0.0, "slow_factor": 0.0, "slow_duration": 0.0,
		"chain_count": 3, "color": Color(1.0, 0.9, 0.3),
	},
}

# Generous window: real players need time to enter a 4-key combo.
const STRATAGEM_INPUT_TIMEOUT: float = 3.0
var _input_buffer: Array[String] = []
var _input_buffer_timer: float = 0.0

var stratagems: Dictionary = {
	"meteor_strike": {"code": ["ui_up", "ui_up", "ui_down", "ui_right"], "cooldown": 8.0},
	"summon_golem": {"code": ["ui_down", "ui_up", "ui_left", "ui_left"], "cooldown": 18.0},
	"open_extraction": {"code": ["ui_right", "ui_down", "ui_left", "ui_up"], "cooldown": 0.0, "instant": true},
}
var _stratagem_cooldowns: Dictionary = {}

signal stratagem_called(stratagem_name: String)
signal stratagem_ready(stratagem_name: String)

@export var meteor_strike_scene: PackedScene
@export var golem_scene: PackedScene

@onready var target_reticle: MeshInstance3D = get_node_or_null("TargetReticle")

const Chibi := preload("res://scripts/model_utils.gd")
var _model: Node3D
var _carry_node: Node3D
var _anim_t := 0.0


func _ready() -> void:
	var chosen: int = ProjectSettings.get_setting("magic_mayhem/selected_staff", 0)
	current_staff = chosen as Staff
	current_health = max_health
	add_to_group("player")
	_build_model()
	health_changed.emit(current_health, max_health)
	for key in stratagems.keys():
		_stratagem_cooldowns[key] = 0.0
	staff_changed.emit(STAFF_CONFIG[current_staff]["name"])
	if target_reticle:
		target_reticle.visible = false


func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_aim()
	_handle_shooting(delta)
	_update_stratagem_cooldowns(delta)
	_update_input_buffer(delta)
	_update_reticle()
	_animate_model(delta)


func _handle_movement(_delta: float) -> void:
	var input_dir := Vector3.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.z = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()
	var speed := move_speed * (0.8 if carrying_item else 1.0)
	velocity.x = input_dir.x * speed
	velocity.z = input_dir.z * speed
	velocity.y = 0.0
	move_and_slide()
	var half := 40.0
	for lm in get_tree().get_nodes_in_group("level_manager"):
		if "map_half_size" in lm:
			half = lm.map_half_size
	global_position.x = clampf(global_position.x, -half + 1.0, half - 1.0)
	global_position.z = clampf(global_position.z, -half + 1.0, half - 1.0)


func _handle_aim() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var mouse_pos := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var dir := camera.project_ray_normal(mouse_pos)
	if absf(dir.y) < 0.0001:
		return
	var t := (global_position.y - from.y) / dir.y
	if t < 0.0:
		return
	var target := from + dir * t
	target.y = global_position.y
	_aim_ground_point = target
	if target.distance_to(global_position) > 0.01:
		_aim_direction = (target - global_position).normalized()
		# Don't spin the body to face the cursor while lining up a stratagem drop.
		if pending_stratagem == "":
			look_at(target, Vector3.UP)


func _update_reticle() -> void:
	if target_reticle == null:
		return
	target_reticle.visible = pending_stratagem != ""
	if pending_stratagem != "":
		target_reticle.global_position = _aim_ground_point + Vector3(0, 0.05, 0)


func _handle_shooting(delta: float) -> void:
	_fire_timer -= delta

	if pending_stratagem != "":
		_targeting_timer -= delta
		if not Input.is_action_pressed("shoot"):
			_confirm_armed = true
		elif _confirm_armed and Input.is_action_just_pressed("shoot"):
			_confirm_stratagem()
			return
		if _targeting_timer <= 0.0:
			# Safety valve: never leave the player stuck unable to fire.
			_cancel_stratagem_targeting()
		return

	var cooldown: float = STAFF_CONFIG[current_staff]["cooldown"]
	if Input.is_action_pressed("shoot") and _fire_timer <= 0.0:
		_fire_bullet()
		_fire_timer = cooldown


func _cancel_stratagem_targeting() -> void:
	pending_stratagem = ""
	stratagem_targeting_ended.emit()


func _confirm_stratagem() -> void:
	var key := pending_stratagem
	pending_stratagem = ""
	stratagem_targeting_ended.emit()
	_try_call_stratagem(key)


## Aim assist: if a hostile is near the cursor's ground point, aim straight
## at it. Compensates for perspective/parallax so clicking a monster's body
## always sends the shot at that monster.
func _assisted_direction() -> Vector3:
	var best: Node3D = null
	var best_d := 2.2
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not e is Node3D:
			continue
		var d := Vector2(e.global_position.x - _aim_ground_point.x, e.global_position.z - _aim_ground_point.z).length()
		if d < best_d:
			best_d = d
			best = e
	if best:
		var to_e := best.global_position - global_position
		to_e.y = 0.0
		if to_e.length() > 0.05:
			return to_e.normalized()
	return _aim_direction


func _fire_bullet() -> void:
	if bullet_scene == null:
		return
	var cfg: Dictionary = STAFF_CONFIG[current_staff]
	var bullet := bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position + Vector3(0, 0.2, 0)
	var aim := _assisted_direction()
	if bullet.has_method("setup_elemental"):
		bullet.setup_elemental(aim, cfg["damage"], self, {
			"splash_radius": cfg["splash_radius"],
			"slow_factor": cfg["slow_factor"],
			"slow_duration": cfg["slow_duration"],
			"chain_count": cfg["chain_count"],
			"color": cfg["color"],
		})
	elif bullet.has_method("setup"):
		bullet.setup(aim, cfg["damage"], self)


func _update_input_buffer(delta: float) -> void:
	var pressed_dir := ""
	if Input.is_action_just_pressed("ui_up"):
		pressed_dir = "ui_up"
	elif Input.is_action_just_pressed("ui_down"):
		pressed_dir = "ui_down"
	elif Input.is_action_just_pressed("ui_left"):
		pressed_dir = "ui_left"
	elif Input.is_action_just_pressed("ui_right"):
		pressed_dir = "ui_right"

	if pressed_dir != "":
		_input_buffer.append(pressed_dir)
		_input_buffer_timer = STRATAGEM_INPUT_TIMEOUT
		_check_stratagem_match()
		var max_len := 0
		for key in stratagems.keys():
			max_len = max(max_len, stratagems[key]["code"].size())
		while _input_buffer.size() > max_len:
			_input_buffer.pop_front()
		input_buffer_changed.emit(_input_buffer.duplicate())
	else:
		if _input_buffer_timer > 0.0:
			_input_buffer_timer -= delta
			if _input_buffer_timer <= 0.0:
				_input_buffer.clear()
				input_buffer_changed.emit([])


func _check_stratagem_match() -> void:
	if pending_stratagem != "":
		return
	for key in stratagems.keys():
		var code: Array = stratagems[key]["code"]
		if _input_buffer.size() < code.size():
			continue
		var tail := _input_buffer.slice(_input_buffer.size() - code.size(), _input_buffer.size())
		if tail == code and _stratagem_cooldowns.get(key, 0.0) <= 0.0:
			if stratagems[key].get("instant", false):
				_input_buffer.clear()
				input_buffer_changed.emit([])
				_use_instant_stratagem(key)
				return
			pending_stratagem = key
			_targeting_timer = TARGETING_TIMEOUT
			# If "shoot" is already held when the combo completes, require a
			# fresh press (a release first) before it can confirm the drop —
			# otherwise the held button would never register as "just pressed"
			# and the player would be stuck unable to fire.
			_confirm_armed = not Input.is_action_pressed("shoot")
			stratagem_targeting_started.emit(key)
			_input_buffer.clear()
			input_buffer_changed.emit([])
			return


func _use_instant_stratagem(key: String) -> void:
	match key:
		"open_extraction":
			var opened := false
			var msg := "No extraction zone on this map"
			for ez in get_tree().get_nodes_in_group("extraction_zone"):
				if ez.has_method("try_open"):
					msg = ez.try_open(global_position)
					if msg == "":
						opened = true
						break
			if opened:
				stratagem_called.emit(key)
			else:
				notice.emit(msg)


func _try_call_stratagem(stratagem_name: String) -> void:
	if _stratagem_cooldowns.get(stratagem_name, 0.0) > 0.0:
		return
	_stratagem_cooldowns[stratagem_name] = stratagems[stratagem_name]["cooldown"]
	stratagem_called.emit(stratagem_name)
	match stratagem_name:
		"meteor_strike":
			_call_meteor_strike()
		"summon_golem":
			_call_summon_golem()


func _update_stratagem_cooldowns(delta: float) -> void:
	for key in _stratagem_cooldowns.keys():
		if _stratagem_cooldowns[key] > 0.0:
			_stratagem_cooldowns[key] -= delta
			if _stratagem_cooldowns[key] <= 0.0:
				_stratagem_cooldowns[key] = 0.0
				stratagem_ready.emit(key)


func _call_meteor_strike() -> void:
	var target_pos := _aim_ground_point
	if meteor_strike_scene:
		var fx := meteor_strike_scene.instantiate()
		get_tree().current_scene.add_child(fx)
		fx.global_position = target_pos
	else:
		call_deferred("_fallback_area_damage", target_pos, 4.5, 70)


func _call_summon_golem() -> void:
	var spawn_pos := _aim_ground_point
	if golem_scene:
		var golem := golem_scene.instantiate()
		get_tree().current_scene.add_child(golem)
		golem.global_position = spawn_pos


func _fallback_area_damage(center: Vector3, radius: float, damage: int) -> void:
	for body in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(body) and body.global_position.distance_to(center) <= radius:
			if body.has_method("take_damage"):
				body.take_damage(damage)


func _build_model() -> void:
	for n in ["Visual", "Nose"]:
		var o := get_node_or_null(n)
		if o:
			o.visible = false
	var col: Color = STAFF_CONFIG[current_staff]["color"]
	_model = Chibi.build_player(col)
	add_child(_model)
	_model.position.y = -0.8
	_carry_node = Node3D.new()
	_carry_node.position = Vector3(0, 2.5, 0)
	_carry_node.visible = false
	add_child(_carry_node)
	var crystal: Node3D = Chibi.load_scene("res://models/carry_crystal.tscn")
	if crystal:
		_carry_node.add_child(crystal)


func _animate_model(delta: float) -> void:
	_anim_t += delta
	var moving := clampf(Vector2(velocity.x, velocity.z).length() / move_speed, 0.0, 1.0)
	Chibi.animate(_model, _anim_t, moving, -0.8)
	if _carry_node and _carry_node.visible:
		_carry_node.rotation.y += delta * 3.0


func set_carrying(v: bool) -> void:
	carrying_item = v
	if _carry_node:
		_carry_node.visible = v


func heal(amount: int) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)


func take_damage(amount: int) -> void:
	Chibi.flash(_model)
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		died.emit()
		queue_free()
