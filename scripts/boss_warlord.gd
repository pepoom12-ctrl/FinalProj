extends CharacterBody3D
## Orcish Warlord mini-boss. Telegraphed attacks:
##  - Ground Slam (red circle)   - Charge (red lane)
##  - Fireball Volley            - Spin Attack (yellow circle, enraged)
## At 50% HP it roars, summons orcs and becomes enraged (faster, more spins).

const C := preload("res://scripts/model_utils.gd")

signal died
signal health_changed(current: int, max: int)

@export var max_health: int = 800
@export var move_speed: float = 3.2
@export var activate_range: float = 34.0
@export var map_half_size: float = 65.0

enum S { IDLE, CHASE, SLAM_WIND, SLAM, CHARGE_WIND, CHARGE, VOLLEY_WIND, VOLLEY, SPIN_WIND, SPIN, ROAR, RECOVER }

var hud_name := "Orcish Warlord"
var hit_radius := 1.9
var hud_main := true
var needs_carry := false
var finished := false

var state: S = S.IDLE
var current_health: int
var _t := 0.0
var _cd := 2.0
var _melee_cd := 0.0
var _player: Node3D
var _model: Node3D
var _arm: Node3D
var _tele: MeshInstance3D
var _charge_dir := Vector3.ZERO
var _enraged := false
var _roared := false
var _hit_done := false
var _spin_tick := 0.0
var _recover_time := 0.8
var _anim_t := 0.0
var _arm_target := 30.0
var _arm_speed := 400.0


func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")
	add_to_group("boss")
	add_to_group("objective_prop")
	var old := get_node_or_null("Visual")
	if old:
		old.queue_free()
	_model = C.build_boss()
	add_child(_model)
	_model.position.y = -1.3
	_arm = _model.get_meta("arm_r")
	C.label(self, "ORCISH WARLORD", Vector3(0, 4.6, 0), Color(1.0, 0.4, 0.3), 0.014)
	call_deferred("_find_player")


func _find_player() -> void:
	var p := get_tree().get_nodes_in_group("player")
	if p.size() > 0:
		_player = p[0]


func _valid_player() -> bool:
	return _player != null and is_instance_valid(_player)


func _flat_to_player() -> Vector3:
	var v := _player.global_position - global_position
	v.y = 0.0
	return v


func _face_player() -> void:
	var v := _flat_to_player()
	if v.length() > 0.05:
		look_at(global_position + v, Vector3.UP)


func _set_state(s: S) -> void:
	state = s
	_t = 0.0
	_hit_done = false


func _physics_process(delta: float) -> void:
	_anim_t += delta
	_t += delta
	_melee_cd -= delta
	if not _valid_player():
		_find_player()
		return
	var speed_mul := 1.4 if _enraged else 1.0
	velocity = Vector3.ZERO

	match state:
		S.IDLE:
			if _flat_to_player().length() <= activate_range:
				_set_state(S.CHASE)
				health_changed.emit(current_health, max_health)
		S.CHASE:
			_face_player()
			var to := _flat_to_player()
			if to.length() > 2.3:
				velocity = to.normalized() * move_speed * speed_mul
			elif _melee_cd <= 0.0:
				_melee_cd = 1.7
				C.punch(_model)
				_hurt_player(14)
			_cd -= delta
			if _cd <= 0.0:
				_choose_attack(to.length())
		S.SLAM_WIND:
			_face_player()
			_arm_target = -165.0
			_arm_speed = 300.0
			_pulse_tele(_t / 0.9)
			if _t >= 0.9:
				_do_slam()
		S.SLAM:
			_arm_target = 70.0
			_arm_speed = 1600.0
			if _t >= 0.2:
				_recover_time = 0.9
				_set_state(S.RECOVER)
		S.CHARGE_WIND:
			_arm_target = -20.0
			if _t < 0.6:
				_face_player()
				_charge_dir = _flat_to_player().normalized()
				_update_lane()
			_pulse_tele(_t / 0.9)
			if _t >= 0.9:
				_clear_tele()
				_set_state(S.CHARGE)
		S.CHARGE:
			velocity = _charge_dir * 20.0 * speed_mul
			if not _hit_done and _flat_to_player().length() < 2.0:
				_hit_done = true
				_hurt_player(28)
			if _t >= 0.75:
				_recover_time = 1.3
				_set_state(S.RECOVER)
		S.VOLLEY_WIND:
			_face_player()
			_arm_target = -90.0
			if _t >= 0.7:
				_do_volley()
				_recover_time = 0.7
				_set_state(S.RECOVER)
		S.SPIN_WIND:
			_arm_target = -90.0
			_pulse_tele(_t / 0.7)
			if _t >= 0.7:
				_set_state(S.SPIN)
				_spin_tick = 0.0
		S.SPIN:
			_model.rotation.y += delta * 16.0
			_arm_target = 0.0
			var to := _flat_to_player()
			velocity = to.normalized() * 4.0
			if _tele:
				_tele.global_position = Vector3(global_position.x, 0.07, global_position.z)
			_spin_tick -= delta
			if _spin_tick <= 0.0:
				_spin_tick = 0.4
				if to.length() <= 4.6:
					_hurt_player(11)
			if _t >= 1.4:
				_model.rotation.y = 0.0
				_clear_tele()
				_recover_time = 1.0
				_set_state(S.RECOVER)
		S.ROAR:
			_arm_target = -150.0
			_model.scale = Vector3.ONE * (1.8 + sin(_t * 18.0) * 0.06)
			if _t >= 1.4:
				_model.scale = Vector3.ONE * 1.8
				_recover_time = 0.5
				_set_state(S.RECOVER)
		S.RECOVER:
			_arm_target = 30.0
			if _t >= _recover_time:
				_cd = randf_range(1.6, 2.6) * (0.65 if _enraged else 1.0)
				_set_state(S.CHASE)

	if state != S.SPIN:
		_model.rotation.y = 0.0
	if state in [S.CHASE, S.CHARGE, S.SPIN]:
		pass
	move_and_slide()
	global_position.x = clampf(global_position.x, -map_half_size + 2.0, map_half_size - 2.0)
	global_position.z = clampf(global_position.z, -map_half_size + 2.0, map_half_size - 2.0)
	var moving := clampf(Vector2(velocity.x, velocity.z).length() / 4.0, 0.0, 1.0)
	C.animate(_model, _anim_t, moving, -1.3)
	_arm.rotation_degrees.x = move_toward(_arm.rotation_degrees.x, _arm_target if state != S.CHASE and state != S.IDLE else 30.0, _arm_speed * delta)
	if state == S.CHASE or state == S.IDLE:
		_arm_speed = 400.0


func _choose_attack(dist: float) -> void:
	if _enraged and not _roared:
		_start_roar()
		return
	var r := randf()
	if dist <= 7.5:
		if _enraged and r < 0.45:
			_start_spin()
		else:
			_start_slam()
	elif dist > 10.0:
		if r < 0.5:
			_start_charge()
		else:
			_start_volley()
	else:
		_start_volley()


func _start_slam() -> void:
	_make_tele(5.8, Color(1.0, 0.15, 0.1, 0.45))
	_tele.global_position = Vector3(global_position.x, 0.07, global_position.z)
	_set_state(S.SLAM_WIND)


func _do_slam() -> void:
	_clear_tele()
	if _flat_to_player().length() <= 5.8:
		_hurt_player(30)
	_shockwave(5.8)
	_set_state(S.SLAM)


func _start_charge() -> void:
	_charge_dir = _flat_to_player().normalized()
	_make_lane()
	_set_state(S.CHARGE_WIND)


func _start_volley() -> void:
	_set_state(S.VOLLEY_WIND)


func _start_spin() -> void:
	_make_tele(4.6, Color(1.0, 0.85, 0.1, 0.45))
	_tele.global_position = Vector3(global_position.x, 0.07, global_position.z)
	_set_state(S.SPIN_WIND)


func _start_roar() -> void:
	_roared = true
	_set_state(S.ROAR)
	var scn: PackedScene = load("res://prefabs/enemy.tscn")
	for i in 2:
		var e = scn.instantiate()
		e.faction = 2
		get_tree().current_scene.add_child(e)
		var a := randf() * TAU
		e.global_position = global_position + Vector3(cos(a) * 5.0, 0.75, sin(a) * 5.0)


func _do_volley() -> void:
	var scn: PackedScene = load("res://prefabs/bullet.tscn")
	var base := _flat_to_player().normalized()
	var n := 7 if _enraged else 5
	for i in n:
		var ang := deg_to_rad((i - (n - 1) * 0.5) * 14.0)
		var dir := base.rotated(Vector3.UP, ang)
		var b = scn.instantiate()
		get_tree().current_scene.add_child(b)
		b.global_position = global_position + Vector3(0, 0.4, 0) + dir * 1.5
		b.speed = 13.0
		b.lifetime = 3.2
		b.scale = Vector3.ONE * 2.2
		b.setup_elemental(dir, 14, self, {"color": Color(1.0, 0.3, 0.05)})


func _hurt_player(amount: int) -> void:
	if _valid_player() and _player.has_method("take_damage"):
		_player.take_damage(amount)


func _make_tele(radius: float, color: Color) -> void:
	_clear_tele()
	_tele = MeshInstance3D.new()
	_tele.mesh = C.cy(radius, radius, 0.03, 28)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = color
	_tele.material_override = m
	get_tree().current_scene.add_child(_tele)


func _make_lane() -> void:
	_clear_tele()
	_tele = MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(3.2, 0.03, 18.0)
	_tele.mesh = b
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1.0, 0.15, 0.1, 0.45)
	_tele.material_override = m
	get_tree().current_scene.add_child(_tele)
	_update_lane()


func _update_lane() -> void:
	if _tele == null or not is_instance_valid(_tele):
		return
	var c := global_position + _charge_dir * 9.0
	_tele.global_position = Vector3(c.x, 0.07, c.z)
	if _charge_dir.length() > 0.01:
		_tele.look_at(_tele.global_position + _charge_dir, Vector3.UP)


func _pulse_tele(k: float) -> void:
	if _tele and is_instance_valid(_tele):
		var m: StandardMaterial3D = _tele.material_override
		m.albedo_color.a = 0.25 + 0.3 * clampf(k, 0.0, 1.0) + sin(_t * 18.0) * 0.08


func _clear_tele() -> void:
	if _tele and is_instance_valid(_tele):
		_tele.queue_free()
	_tele = null


func _shockwave(radius: float) -> void:
	var fx := MeshInstance3D.new()
	fx.mesh = C.tor(radius * 0.9, radius)
	fx.material_override = C.mat(Color(1.0, 0.6, 0.2), 2.0, 0.8)
	get_tree().current_scene.add_child(fx)
	fx.global_position = Vector3(global_position.x, 0.2, global_position.z)
	fx.scale = Vector3(0.2, 0.2, 0.2)
	var t := fx.create_tween()
	t.tween_property(fx, "scale", Vector3(1.2, 1.0, 1.2), 0.3)
	t.tween_callback(fx.queue_free)


func take_damage(amount: int) -> void:
	if finished:
		return
	if state == S.IDLE:
		_set_state(S.CHASE)
	current_health -= amount
	C.flash(_model)
	health_changed.emit(maxi(current_health, 0), max_health)
	if not _enraged and current_health <= max_health / 2:
		_enraged = true
	if current_health <= 0:
		_die()


func _die() -> void:
	finished = true
	died.emit()
	for om in get_tree().get_nodes_in_group("objective_manager"):
		om.report("warlord")
	remove_from_group("enemies")
	remove_from_group("boss")
	set_physics_process(false)
	_clear_tele()
	var cs := get_node_or_null("CollisionShape3D")
	if cs:
		cs.set_deferred("disabled", true)
	var t := create_tween()
	t.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.6)
	t.tween_callback(queue_free)
