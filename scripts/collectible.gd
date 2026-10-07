extends Area3D
## Collectible objective (soul fragments, etc). Walk close to collect.

const C := preload("res://scripts/model_utils.gd")
const PB := preload("res://scripts/model_utils.gd")

@export var objective_id: String = "souls"
@export var kind: String = "soul"
@export var hud_name: String = "Soul Fragment"
@export var hud_main: bool = true
@export var trigger_radius: float = 2.6

var finished := false
var needs_carry := false
var _model: Node3D
var _label: Label3D
var _beam: MeshInstance3D
var _t := 0.0


func _ready() -> void:
	_t = randf() * 6.0
	add_to_group("objective_prop")
	_model = PB.make(kind)
	_model.position.y = 1.3
	add_child(_model)
	_beam = C.beacon(self, Color(1.0, 0.85, 0.3) if hud_main else Color(0.4, 0.9, 1.0), 14.0)
	_label = C.label(self, hud_name, Vector3(0, 2.9, 0), Color(0.7, 0.95, 1.0))


func _process(delta: float) -> void:
	if finished:
		return
	_t += delta
	_model.position.y = 1.3 + sin(_t * 2.2) * 0.25
	_model.rotation.y += delta * 1.5
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p):
			var d := Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z).length()
			if d <= trigger_radius:
				_collect()
				return


func _collect() -> void:
	finished = true
	for om in get_tree().get_nodes_in_group("objective_manager"):
		om.report(objective_id)
	_label.visible = false
	_beam.visible = false
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(_model, "scale", Vector3.ONE * 2.5, 0.25)
	t.tween_property(_model, "position:y", 3.2, 0.25)
	t.chain().tween_callback(queue_free)
