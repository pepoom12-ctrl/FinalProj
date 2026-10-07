extends Area3D
## Side objective: stand inside for `required_time` seconds, uninterrupted.
## Uses a distance poll (not just enter/exit signals) for reliability.

signal purified

@export var required_time: float = 15.0
@export var trigger_radius: float = 2.5

var _timer := 0.0
var _done := false


func _process(delta: float) -> void:
	if _done:
		return
	var inside := false
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p):
			var d := Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z).length()
			if d <= trigger_radius:
				inside = true
	if inside:
		_timer += delta
		if _timer >= required_time:
			_complete()
	else:
		_timer = 0.0


func _complete() -> void:
	_done = true
	purified.emit()
	var p := get_tree().get_nodes_in_group("player")
	if p.size() > 0 and p[0].has_method("heal"):
		p[0].heal(40)
	for om in get_tree().get_nodes_in_group("objective_manager"):
		om.report_side("fountain")
