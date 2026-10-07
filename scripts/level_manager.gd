extends Node3D
## Ambient wave spawner (3D). Enemies spawn in a ring around the player so
## pressure stays constant on a large map. Objectives live elsewhere.

signal wave_started(wave_index: int, total_waves: int)
signal wave_cleared(wave_index: int)

@export var enemy_scene: PackedScene
@export var faction: int = 0
@export var waves: Array = [5, 8, 12]
@export var spawn_interval: float = 0.8
@export var next_level_path: String = ""
@export var level_name: String = "Level"
@export var map_half_size: float = 65.0

@onready var spawn_points: Node = get_node_or_null("SpawnPoints")

var _current_wave := 0
var _enemies_remaining := 0
var _enemies_to_spawn := 0
var _spawn_timer := 0.0


func _ready() -> void:
	add_to_group("level_manager")
	call_deferred("_start_next_wave")


func _process(delta: float) -> void:
	if _enemies_to_spawn > 0:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_one_enemy()
			_spawn_timer = spawn_interval


func _start_next_wave() -> void:
	var idx: int = mini(_current_wave, waves.size() - 1)
	_enemies_to_spawn = int(waves[idx])
	_enemies_remaining = _enemies_to_spawn
	_spawn_timer = 0.0
	wave_started.emit(_current_wave, waves.size())


func _spawn_one_enemy() -> void:
	if enemy_scene == null:
		return
	var point := _get_spawn_point()
	var enemy := enemy_scene.instantiate()
	if "faction" in enemy:
		enemy.faction = faction
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = point + Vector3(0, 0.75, 0)
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)
	_enemies_to_spawn -= 1


func _get_spawn_point() -> Vector3:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and is_instance_valid(players[0]):
		var c: Vector3 = players[0].global_position
		var lim := map_half_size - 3.0
		for i in 10:
			var a := randf() * TAU
			var d := randf_range(26.0, 36.0)
			var p := Vector3(c.x + cos(a) * d, 0.0, c.z + sin(a) * d)
			if absf(p.x) <= lim and absf(p.z) <= lim:
				return p
	if spawn_points and spawn_points.get_child_count() > 0:
		var children := spawn_points.get_children()
		var chosen: Node3D = children[randi() % children.size()]
		return chosen.global_position
	return Vector3(randf_range(-20, 20), 0, randf_range(-20, 20))


func _on_enemy_died(_enemy: Node) -> void:
	for om in get_tree().get_nodes_in_group("objective_manager"):
		if om.has_objective("kills"):
			om.report("kills")
	_enemies_remaining -= 1
	if _enemies_remaining <= 0 and _enemies_to_spawn <= 0:
		wave_cleared.emit(_current_wave)
		_current_wave += 1
		call_deferred("_start_next_wave")


func go_to_next_level() -> void:
	if next_level_path != "":
		call_deferred("_deferred_change_scene", next_level_path)


func _deferred_change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)
