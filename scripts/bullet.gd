extends Area3D
## Elemental magic projectile (3D).
## Hit detection (all redundant, first one to fire wins):
##  1. Height-independent XZ proximity sweep against hostile characters
##     (bullets can never fly over/under a monster because of Y mismatch).
##  2. Swept physics raycast (objectives, walls, anything with take_damage).
##  3. Area3D enter signals + a deferred spawn-overlap check (point-blank).

@export var speed: float = 34.0
@export var lifetime: float = 2.2

const HIT_RADIUS: float = 0.95  # generous XZ radius (capsule 0.45 + bullet)

var damage: int = 10
var direction: Vector3 = Vector3.FORWARD
var _shooter: Node = null
var _age: float = 0.0
var _resolved := false

var _splash_radius: float = 0.0
var _slow_factor: float = 0.0
var _slow_duration: float = 0.0
var _chain_count: int = 0
var _chain_range: float = 7.0
var _already_hit: Array = []


const C := preload("res://scripts/model_utils.gd")


## Turns this projectile into the arrow model (res://models/arrow.tscn).
func make_arrow() -> void:
	var v := get_node_or_null("Visual")
	if v:
		v.visible = false
	var a: Node3D = C.load_scene("res://models/arrow.tscn")
	if a:
		add_child(a)


func setup(dir: Vector3, dmg: int, shooter: Node) -> void:
	direction = dir.normalized()
	damage = dmg
	_shooter = shooter
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)


func setup_elemental(dir: Vector3, dmg: int, shooter: Node, elemental: Dictionary) -> void:
	setup(dir, dmg, shooter)
	_splash_radius = elemental.get("splash_radius", 0.0)
	_slow_factor = elemental.get("slow_factor", 0.0)
	_slow_duration = elemental.get("slow_duration", 0.0)
	_chain_count = elemental.get("chain_count", 0)
	var visual := get_node_or_null("Visual")
	if visual and elemental.has("color"):
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = elemental["color"]
		mat.emission_enabled = true
		mat.emission = elemental["color"]
		visual.material_override = mat


func _ready() -> void:
	body_entered.connect(_on_hit_node)
	area_entered.connect(_on_hit_node)
	call_deferred("_check_spawn_overlap")


func _check_spawn_overlap() -> void:
	if _resolved or not is_instance_valid(self):
		return
	_sweep_characters(global_position, global_position)
	for body in get_overlapping_bodies():
		_try_hit(body)
	for area in get_overlapping_areas():
		_try_hit(area)


func _physics_process(delta: float) -> void:
	if _resolved:
		return
	var from := global_position
	var to := from + direction * speed * delta
	_sweep_characters(from, to)
	if not _resolved:
		_sweep_ray(from, to)
	if not _resolved:
		global_position = to
	_age += delta
	if _age >= lifetime:
		queue_free()


func _hostile_groups() -> Array[String]:
	if is_instance_valid(_shooter) and _shooter.is_in_group("enemies"):
		return ["player", "taunt_targets"]
	return ["enemies"]


# Height-independent check: distance from the bullet's XZ path to each
# hostile character's XZ position. Ignores Y completely.
func _sweep_characters(from: Vector3, to: Vector3) -> void:
	var seg := Vector2(to.x - from.x, to.z - from.z)
	var seg_len_sq := seg.length_squared()
	var best: Node = null
	var best_t := 2.0
	for group in _hostile_groups():
		for c in get_tree().get_nodes_in_group(group):
			if not is_instance_valid(c) or c == _shooter or c in _already_hit:
				continue
			if not c is Node3D:
				continue
			var rel := Vector2(c.global_position.x - from.x, c.global_position.z - from.z)
			var t := 0.0
			if seg_len_sq > 0.0001:
				t = clampf(rel.dot(seg) / seg_len_sq, 0.0, 1.0)
			var closest := seg * t
			var radius := HIT_RADIUS * maxf(c.scale.x, 1.0)
			var hr = c.get("hit_radius")
			if hr != null:
				radius = maxf(radius, float(hr))
			if closest.distance_to(rel) <= radius and t < best_t:
				best_t = t
				best = c
	if best:
		_try_hit(best)


func _sweep_ray(from: Vector3, to: Vector3) -> void:
	if from.distance_to(to) < 0.001:
		return
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_bodies = true
	query.collide_with_areas = true
	query.collision_mask = 0xFFFFFFFF
	query.exclude = [get_rid()]
	var result := space_state.intersect_ray(query)
	if result:
		_try_hit(result.get("collider"))


func _on_hit_node(node: Node) -> void:
	_try_hit(node)


func _is_friendly(target: Node) -> bool:
	if not is_instance_valid(_shooter):
		return false
	if _shooter.is_in_group("enemies"):
		return target.is_in_group("enemies")
	return target.is_in_group("player") or target.is_in_group("player_allies")


func _try_hit(target: Node) -> void:
	if _resolved or target == null or not is_instance_valid(target):
		return
	if target == self or target == _shooter or target in _already_hit:
		return
	if not target.has_method("take_damage") or _is_friendly(target):
		return

	target.take_damage(damage)
	_already_hit.append(target)

	if _slow_factor > 0.0 and is_instance_valid(target) and target.has_method("apply_slow"):
		target.apply_slow(_slow_duration, _slow_factor)

	if _splash_radius > 0.0:
		_resolved = true
		if is_instance_valid(target):
			global_position = target.global_position
		_apply_splash(target)
	elif _chain_count > 0 and is_instance_valid(target):
		global_position = target.global_position
		_chain_to_next(target)
	else:
		_resolved = true
		queue_free()


func _apply_splash(origin: Node) -> void:
	for body in get_tree().get_nodes_in_group("enemies"):
		if body == origin or not is_instance_valid(body):
			continue
		var d := Vector2(body.global_position.x - global_position.x, body.global_position.z - global_position.z).length()
		if d <= _splash_radius:
			if body.has_method("take_damage"):
				body.take_damage(int(damage * 0.6))
	queue_free()


func _chain_to_next(from: Node) -> void:
	var next_target: Node = null
	var next_dist := _chain_range
	for body in get_tree().get_nodes_in_group("enemies"):
		if body in _already_hit or not is_instance_valid(body):
			continue
		var d: float = body.global_position.distance_to(from.global_position)
		if d <= next_dist:
			next_dist = d
			next_target = body

	_chain_count -= 1
	if next_target:
		direction = (next_target.global_position - global_position).normalized()
		direction.y = 0.0
		direction = direction.normalized()
		look_at(global_position + direction, Vector3.UP)
	else:
		_resolved = true
		queue_free()
