extends Area3D
## Destructible objective (gravestone / totem / war drum). Damaged by bullets.

const C := preload("res://scripts/model_utils.gd")
const PB := preload("res://scripts/model_utils.gd")

signal destroyed

@export var objective_id: String = "graves"
@export var kind: String = "gravestone"
@export var hud_name: String = "Necromancer Gravestone"
@export var max_health: int = 120
@export var hud_main: bool = true

var current_health: int
var finished := false
var needs_carry := false
var _model: Node3D
var _label: Label3D
var _beam: MeshInstance3D


func _ready() -> void:
	current_health = max_health
	add_to_group("objective_prop")
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 1.3
	sh.height = 3.2
	cs.shape = sh
	cs.position = Vector3(0, 1.6, 0)
	add_child(cs)
	_model = PB.make(kind)
	add_child(_model)
	_beam = C.beacon(self, Color(1.0, 0.85, 0.3) if hud_main else Color(0.4, 0.9, 1.0), 18.0)
	_label = C.label(self, "", Vector3(0, 4.6, 0), Color(1.0, 0.9, 0.5))
	_update_label()


func _update_label() -> void:
	_label.text = "%s\nHP %d/%d" % [hud_name, maxi(current_health, 0), max_health]


func take_damage(amount: int) -> void:
	if finished:
		return
	current_health -= amount
	C.flash(_model)
	_update_label()
	var t := create_tween()
	t.tween_property(_model, "position:x", 0.12, 0.04)
	t.tween_property(_model, "position:x", -0.12, 0.05)
	t.tween_property(_model, "position:x", 0.0, 0.04)
	if current_health <= 0:
		_destroy()


func _destroy() -> void:
	finished = true
	destroyed.emit()
	for om in get_tree().get_nodes_in_group("objective_manager"):
		om.report(objective_id)
	_label.visible = false
	_beam.visible = false
	var t := create_tween()
	t.tween_property(_model, "scale", Vector3(1.3, 0.05, 1.3), 0.35)
	t.tween_callback(queue_free)
