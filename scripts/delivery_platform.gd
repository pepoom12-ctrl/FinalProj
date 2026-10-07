extends Area3D
## Level 2 main objective, part 2: deliver the carried Arcane Core here.

const C := preload("res://scripts/model_utils.gd")
const PB := preload("res://scripts/model_utils.gd")

signal delivered

@export var trigger_radius: float = 3.0
@export var objective_id: String = "core"
@export var hud_name: String = "Charging Pad"

var hud_main := true
var needs_carry := true
var finished := false
var _label: Label3D
var _beam: MeshInstance3D


func _ready() -> void:
	add_to_group("objective_prop")
	add_child(PB.make("platform"))
	_beam = C.beacon(self, Color(0.3, 0.6, 1.0), 18.0)
	_label = C.label(self, "Charging Pad\n(bring the Arcane Core)", Vector3(0, 3.2, 0), Color(0.6, 0.8, 1.0))


func _process(_delta: float) -> void:
	if finished:
		return
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p) and p.get("carrying_item") == true:
			var d := Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z).length()
			if d <= trigger_radius:
				_deliver(p)
				return


func _deliver(body: Node) -> void:
	finished = true
	body.set_carrying(false)
	delivered.emit()
	for om in get_tree().get_nodes_in_group("objective_manager"):
		om.report(objective_id)
	_label.text = "Charging Pad\n(charged!)"
	_beam.visible = false
