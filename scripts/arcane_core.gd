extends Area3D
## Level 2 main objective, part 1: pick up the Arcane Core (slows the carrier
## by 20% until delivered to the Charging Pad).

const C := preload("res://scripts/model_utils.gd")
const PB := preload("res://scripts/model_utils.gd")

signal picked_up

@export var trigger_radius: float = 2.6
@export var hud_name: String = "Arcane Core"

var hud_main := true
var finished := false
var needs_carry := false
var _model: Node3D
var _label: Label3D
var _beam: MeshInstance3D
var _t := 0.0


func _ready() -> void:
	add_to_group("objective_prop")
	_model = PB.make("core")
	_model.position.y = 1.4
	add_child(_model)
	_beam = C.beacon(self, Color(0.3, 1.0, 0.6), 18.0)
	_label = C.label(self, "Arcane Core\n(steal me!)", Vector3(0, 3.2, 0), Color(0.5, 1.0, 0.7))


func _process(delta: float) -> void:
	if finished:
		return
	_t += delta
	_model.position.y = 1.4 + sin(_t * 2.0) * 0.25
	_model.rotation.y += delta * 1.2
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p):
			var d := Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z).length()
			if d <= trigger_radius:
				_pickup(p)
				return


func _pickup(body: Node) -> void:
	finished = true
	if body.has_method("set_carrying"):
		body.set_carrying(true)
	picked_up.emit()
	visible = false
