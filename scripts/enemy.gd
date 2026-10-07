extends CharacterBody3D
## Enemy (chibi model per faction). UNDEAD = horde melee, ELF = ranged/fast,
## ORC = slow tank. Flashes white on hit, hops while walking, pops on death.

const Chibi := preload("res://scripts/model_utils.gd")

enum Faction { UNDEAD, ELF, ORC }

@export var faction: Faction = Faction.UNDEAD
@export var enemy_name: String = "Skeleton"
@export var bullet_scene: PackedScene

var max_health: int = 30
var current_health: int
var base_move_speed: float = 3.0
var move_speed: float = 3.0
var attack_damage: int = 8
var attack_range: float = 1.6
var attack_cooldown: float = 1.0
var is_ranged: bool = false
var xp_value: int = 5

var _attack_timer: float = 0.0
var _player: Node3D = null
var _slow_timer: float = 0.0
var _model: Node3D
var _anim_t := 0.0
var _dead := false

const TAUNT_RANGE: float = 12.0

signal died(enemy: Node)

const FACTION_STATS := {
	Faction.UNDEAD: {
		"max_health": 25, "move_speed": 3.4, "attack_damage": 6,
		"attack_range": 1.4, "attack_cooldown": 0.8, "is_ranged": false, "xp_value": 4,
	},
	Faction.ELF: {
		"max_health": 22, "move_speed": 4.6, "attack_damage": 9,
		"attack_range": 9.0, "attack_cooldown": 1.4, "is_ranged": true, "xp_value": 7,
	},
	Faction.ORC: {
		"max_health": 90, "move_speed": 1.8, "attack_damage": 22,
		"attack_range": 2.0, "attack_cooldown": 1.6, "is_ranged": false, "xp_value": 15,
	},
}


func _ready() -> void:
	_apply_faction_stats()
	current_health = max_health
	_anim_t = randf() * 10.0
	add_to_group("enemies")
	add_to_group(_faction_group_name())
	_build_model()
	call_deferred("_find_player")


func _apply_faction_stats() -> void:
	var stats: Dictionary = FACTION_STATS.get(faction, FACTION_STATS[Faction.UNDEAD])
	max_health = stats["max_health"]
	base_move_speed = stats["move_speed"]
	move_speed = base_move_speed
	attack_damage = stats["attack_damage"]
	attack_range = stats["attack_range"]
	attack_cooldown = stats["attack_cooldown"]
	is_ranged = stats["is_ranged"]
	xp_value = stats["xp_value"]


func _build_model() -> void:
	var old := get_node_or_null("Visual")
	if old:
		old.queue_free()
	match faction:
		Faction.UNDEAD:
			_model = Chibi.build_undead(randi() % 2)
		Faction.ELF:
			_model = Chibi.build_elf()
		_:
			_model = Chibi.build_orc()
			scale = Vector3(1.3, 1.3, 1.3)
	add_child(_model)
	_model.position.y = -0.7


func _faction_group_name() -> String:
	match faction:
		Faction.UNDEAD: return "faction_undead"
		Faction.ELF: return "faction_elf"
		Faction.ORC: return "faction_orc"
	return "faction_unknown"


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]


func _get_current_target() -> Node3D:
	var best_taunt: Node3D = null
	var best_dist := TAUNT_RANGE
	for taunt in get_tree().get_nodes_in_group("taunt_targets"):
		if not is_instance_valid(taunt):
			continue
		var d: float = global_position.distance_to(taunt.global_position)
		if d <= best_dist:
			best_dist = d
			best_taunt = taunt
	if best_taunt:
		return best_taunt
	return _player


func apply_slow(duration: float, factor: float) -> void:
	move_speed = base_move_speed * (1.0 - clamp(factor, 0.0, 0.9))
	_slow_timer = max(_slow_timer, duration)


func _physics_process(delta: float) -> void:
	_anim_t += delta
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			move_speed = base_move_speed

	if _player == null or not is_instance_valid(_player):
		call_deferred("_find_player")
		Chibi.animate(_model, _anim_t, 0.0, -0.7)
		return

	var target := _get_current_target()
	if target == null or not is_instance_valid(target):
		velocity = Vector3.ZERO
		return

	_attack_timer -= delta
	var flat_target := target.global_position
	flat_target.y = global_position.y
	var to_target: Vector3 = flat_target - global_position
	var distance: float = to_target.length()

	if distance > attack_range:
		var dir := to_target.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		velocity.y = 0.0
		if distance > 0.05:
			look_at(flat_target, Vector3.UP)
	else:
		velocity = Vector3.ZERO
		if distance > 0.05:
			look_at(flat_target, Vector3.UP)
		if _attack_timer <= 0.0:
			_attack(target)
			_attack_timer = attack_cooldown

	move_and_slide()
	Chibi.animate(_model, _anim_t, clampf(Vector2(velocity.x, velocity.z).length() / maxf(base_move_speed, 0.1), 0.0, 1.0), -0.7)


func _attack(target: Node3D) -> void:
	Chibi.punch(_model)
	if is_ranged and bullet_scene:
		var bullet := bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = global_position + Vector3(0, 0.2, 0)
		var dir := (target.global_position - global_position)
		dir.y = 0.0
		dir = dir.normalized()
		if bullet.has_method("make_arrow"):
			bullet.make_arrow()
			bullet.speed = 22.0
		if bullet.has_method("setup"):
			bullet.setup(dir, attack_damage, self)
	else:
		if target and is_instance_valid(target) and target.has_method("take_damage"):
			if global_position.distance_to(target.global_position) <= attack_range + 0.5:
				target.take_damage(attack_damage)


func take_damage(amount: int) -> void:
	if _dead:
		return
	current_health -= amount
	Chibi.flash(_model)
	if current_health <= 0:
		die()


func die() -> void:
	if _dead:
		return
	_dead = true
	died.emit(self)
	remove_from_group("enemies")
	set_physics_process(false)
	var cs := get_node_or_null("CollisionShape3D")
	if cs:
		cs.set_deferred("disabled", true)
	var t := create_tween()
	t.tween_property(self, "scale", scale * 0.05, 0.25)
	t.tween_callback(queue_free)
