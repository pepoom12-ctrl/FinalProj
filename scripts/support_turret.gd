extends Node2D
## Support Turret stratagem. Auto-targets the nearest enemy in range and
## fires bullets periodically. Self-destructs after its lifetime.

@export var bullet_scene: PackedScene = preload("res://prefabs/bullet.tscn")
@export var fire_range: float = 320.0
@export var fire_cooldown: float = 0.5
@export var damage: int = 10
@export var lifetime: float = 12.0

var _fire_timer: float = 0.0
var _age: float = 0.0


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return

	_fire_timer -= delta
	var target := _find_nearest_enemy()
	if target:
		look_at(target.global_position)
		if _fire_timer <= 0.0:
			_fire_at(target)
			_fire_timer = fire_cooldown


func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_dist := fire_range
	for body in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(body):
			continue
		var d: float = global_position.distance_to(body.global_position)
		if d <= nearest_dist:
			nearest_dist = d
			nearest = body
	return nearest


func _fire_at(target: Node2D) -> void:
	if bullet_scene == null:
		return
	var bullet := bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position
	bullet.rotation = (target.global_position - global_position).angle()
	if bullet.has_method("setup"):
		bullet.setup(bullet.rotation, damage, self)
