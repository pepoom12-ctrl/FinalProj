extends CharacterBody3D
## Summon Golem stratagem ally (3D). Walks toward the nearest enemy,
## taunts nearby enemies to draw aggro off the player, and melee-attacks.

@export var max_health: int = 220
@export var move_speed: float = 2.2
@export var attack_damage: int = 18
@export var attack_range: float = 1.8
@export var attack_cooldown: float = 1.0
@export var lifetime: float = 25.0

var current_health: int
var _model: Node3D
const Chibi := preload("res://scripts/model_utils.gd")
var _attack_timer: float = 0.0
var _age: float = 0.0

signal died


func _ready() -> void:
	current_health = max_health
	add_to_group("taunt_targets")
	add_to_group("player_allies")
	var old := get_node_or_null("Visual")
	if old:
		old.queue_free()
	_model = Chibi.build_golem()
	add_child(_model)
	_model.position.y = -1.1


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		_expire()
		return

	_attack_timer -= delta
	var target := _find_nearest_enemy()
	if target:
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
				if target.has_method("take_damage"):
					target.take_damage(attack_damage)
				_attack_timer = attack_cooldown
	else:
		velocity = Vector3.ZERO

	move_and_slide()
	Chibi.animate(_model, _age, clampf(Vector2(velocity.x, velocity.z).length() / maxf(move_speed, 0.1), 0.0, 1.0), -1.1)


func _find_nearest_enemy() -> Node3D:
	var nearest: Node3D = null
	var nearest_dist := INF
	for body in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(body):
			continue
		var d: float = global_position.distance_to(body.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = body
	return nearest


func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health <= 0:
		_expire()


func _expire() -> void:
	died.emit()
	queue_free()
