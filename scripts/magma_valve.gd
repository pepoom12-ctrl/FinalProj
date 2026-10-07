extends Area3D
## Level 3 side objective: close a magma valve.
## Uses both the enter signal and a distance poll for reliability.

signal closed
@export var trigger_radius: float = 2.0
var _done := false


func _ready() -> void:
	body_entered.connect(_on_entered)


func _process(_delta: float) -> void:
	if _done:
		return
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p):
			var d := Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z).length()
			if d <= trigger_radius:
				_trigger()


func _on_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_trigger()


func _trigger() -> void:
	if _done:
		return
	_done = true
	closed.emit()
	for om in get_tree().get_nodes_in_group("objective_manager"):
		om.report_side("valve")
	set_deferred("monitoring", false)
	visible = false
