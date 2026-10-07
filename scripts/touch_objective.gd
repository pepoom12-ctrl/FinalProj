extends Area3D
## Walk-up objective (alarms, valves, lanterns). Triggers once when the player
## gets close and applies an `effect`.

const C := preload("res://scripts/model_utils.gd")
const PB := preload("res://scripts/model_utils.gd")

@export var objective_id: String = "alarms"
@export var kind: String = "alarm"            # alarm | valve | lantern
@export var effect: String = "none"            # slow_spawns | heal | none
@export var hud_name: String = "Elven Alarm"
@export var hud_main: bool = false
@export var trigger_radius: float = 2.8

var finished := false
var needs_carry := false
var _model: Node3D
var _label: Label3D
var _beam: MeshInstance3D


func _ready() -> void:
	add_to_group("objective_prop")
	_model = PB.make(kind)
	add_child(_model)
	_beam = C.beacon(self, Color(1.0, 0.85, 0.3) if hud_main else Color(0.4, 0.9, 1.0), 16.0)
	_label = C.label(self, hud_name, Vector3(0, 4.2, 0), Color(0.8, 1.0, 1.0))


func _process(_delta: float) -> void:
	if finished:
		return
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p):
			var d := Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z).length()
			if d <= trigger_radius:
				_trigger(p)
				return


func _trigger(p: Node) -> void:
	finished = true
	match effect:
		"slow_spawns":
			for lm in get_tree().get_nodes_in_group("level_manager"):
				lm.spawn_interval *= 1.2
			PB.activate(_model, Color(0.4, 0.4, 0.45), 0.0)
		"heal":
			if p.has_method("heal"):
				p.heal(25)
			PB.activate(_model, Color(1.0, 0.85, 0.4), 4.0)
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.8, 0.4)
			l.omni_range = 9.0
			l.light_energy = 1.5
			l.position = Vector3(0.8, 2.0, 0)
			add_child(l)
		_:
			PB.activate(_model, Color(0.3, 0.7, 1.0), 3.0)
	if kind == "valve":
		var t := create_tween()
		t.tween_property(_model, "rotation:y", 0.0, 0.01)
	for om in get_tree().get_nodes_in_group("objective_manager"):
		om.report(objective_id)
	_label.text = hud_name + "\n(done)"
	_beam.visible = false
