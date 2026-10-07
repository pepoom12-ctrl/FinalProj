extends Area3D
## Hold-zone objective: stand inside for `required_time` seconds without leaving.

const C := preload("res://scripts/model_utils.gd")
const PB := preload("res://scripts/model_utils.gd")

@export var objective_id: String = "fountain"
@export var kind: String = "fountain"       # fountain | altar
@export var hud_name: String = "Holy Fountain"
@export var required_time: float = 15.0
@export var radius: float = 3.2
@export var heal_amount: int = 40
@export var hud_main: bool = false

var finished := false
var needs_carry := false
var _timer := 0.0
var _label: Label3D
var _beam: MeshInstance3D


func _ready() -> void:
	add_to_group("objective_prop")
	add_child(PB.make(kind, radius))
	_beam = C.beacon(self, Color(1.0, 0.85, 0.3) if hud_main else Color(0.4, 0.9, 1.0), 16.0)
	_label = C.label(self, hud_name, Vector3(0, 3.6, 0), Color(0.8, 1.0, 1.0))


func _process(delta: float) -> void:
	if finished:
		return
	var inside := false
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p):
			var d := Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z).length()
			if d <= radius:
				inside = true
	if inside:
		_timer += delta
		_label.text = "%s\n%.1f / %.0f s" % [hud_name, _timer, required_time]
		if _timer >= required_time:
			_complete()
	else:
		if _timer > 0.0:
			_label.text = hud_name
		_timer = 0.0


func _complete() -> void:
	finished = true
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("heal") and heal_amount > 0:
			p.heal(heal_amount)
	for om in get_tree().get_nodes_in_group("objective_manager"):
		om.report(objective_id)
	_label.text = hud_name + "\n(done)"
	_beam.visible = false
