extends Node3D
## Periodic firestorm: telegraphed meteors fall near the player until the
## objective `stop_id` (the magma valves) is completed.

const C := preload("res://scripts/model_utils.gd")

@export var interval: float = 3.0
@export var radius: float = 3.6
@export var damage: int = 18
@export var stop_id: String = "valves"

var _timer := 4.0
var _stopped := false


func _ready() -> void:
	call_deferred("_connect")


func _connect() -> void:
	for om in get_tree().get_nodes_in_group("objective_manager"):
		om.objective_completed.connect(_on_done)


func _on_done(id: String) -> void:
	if id == stop_id:
		_stopped = true


func _process(delta: float) -> void:
	if _stopped:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = interval
		_strike()


func _strike() -> void:
	var ps := get_tree().get_nodes_in_group("player")
	if ps.is_empty() or not is_instance_valid(ps[0]):
		return
	var p: Node3D = ps[0]
	var off := Vector3(randf_range(-8, 8), 0, randf_range(-8, 8)) if randf() < 0.7 else Vector3.ZERO
	var c := Vector3(p.global_position.x + off.x, 0.07, p.global_position.z + off.z)
	var disc := MeshInstance3D.new()
	disc.mesh = C.cy(radius, radius, 0.03, 20)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1.0, 0.25, 0.05, 0.5)
	disc.material_override = m
	get_tree().current_scene.add_child(disc)
	disc.global_position = c
	get_tree().create_timer(1.1).timeout.connect(_explode.bind(disc, c))


func _explode(disc: MeshInstance3D, c: Vector3) -> void:
	if is_instance_valid(disc):
		disc.queue_free()
	var fx := MeshInstance3D.new()
	fx.mesh = C.sph(radius)
	fx.material_override = C.mat(Color(1.0, 0.45, 0.08), 2.5, 0.8)
	get_tree().current_scene.add_child(fx)
	fx.global_position = Vector3(c.x, 0.5, c.z)
	var t := fx.create_tween()
	t.tween_property(fx, "scale", Vector3(0.1, 0.1, 0.1), 0.35)
	t.tween_callback(fx.queue_free)
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p) and Vector2(p.global_position.x - c.x, p.global_position.z - c.z).length() <= radius and p.has_method("take_damage"):
			p.take_damage(damage)
