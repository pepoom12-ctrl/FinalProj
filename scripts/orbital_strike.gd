extends Node3D
## Meteor Strike stratagem effect (3D). Shows a warning ring on the ground,
## then deals AOE damage to enemies in radius and disappears.

@export var radius: float = 4.5
@export var damage: int = 70
@export var telegraph_time: float = 0.8

@onready var ring: MeshInstance3D = $WarningRing
@onready var blast: MeshInstance3D = $Blast

var _elapsed: float = 0.0
var _has_exploded: bool = false
var _ring_mat: StandardMaterial3D
var _blast_mat: StandardMaterial3D


func _ready() -> void:
	ring.mesh.top_radius = radius
	ring.mesh.bottom_radius = radius
	blast.mesh.top_radius = radius
	blast.mesh.bottom_radius = radius
	blast.visible = false
	blast.scale = Vector3.ZERO

	_ring_mat = StandardMaterial3D.new()
	_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_mat.albedo_color = Color(1.0, 0.2, 0.2, 0.55)
	ring.material_override = _ring_mat

	_blast_mat = StandardMaterial3D.new()
	_blast_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_blast_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_blast_mat.albedo_color = Color(1.0, 0.8, 0.25, 0.9)
	_blast_mat.emission_enabled = true
	_blast_mat.emission = Color(1.0, 0.6, 0.15)
	blast.material_override = _blast_mat


func _process(delta: float) -> void:
	_elapsed += delta
	if not _has_exploded:
		var t := _elapsed / telegraph_time
		_ring_mat.albedo_color.a = 0.35 + 0.35 * sin(t * TAU * 3.0)
		if _elapsed >= telegraph_time:
			_explode()
	else:
		var fade_t: float = clamp((_elapsed - telegraph_time) / 0.35, 0.0, 1.0)
		_blast_mat.albedo_color.a = (1.0 - fade_t) * 0.9
		blast.scale = Vector3.ONE * (0.6 + 0.4 * fade_t)
		if fade_t >= 1.0:
			queue_free()


func _explode() -> void:
	_has_exploded = true
	ring.visible = false
	blast.visible = true
	blast.scale = Vector3.ONE
	for body in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(body) and body.global_position.distance_to(global_position) <= radius:
			if body.has_method("take_damage"):
				body.take_damage(damage)
