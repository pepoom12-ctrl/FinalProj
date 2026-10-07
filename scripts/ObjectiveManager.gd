extends Node
## Tracks every objective of a level. Group: "objective_manager".
## `objectives` = [{"id": String, "main": bool, "text": String, "total": int}, ...]

signal main_progress(done: int, total: int)
signal main_complete
signal side_progress(done: int, total: int)
signal side_complete(id: String)
signal objective_changed(id: String)
signal objective_completed(id: String)

@export var objectives: Array = []

var main_done: int = 0
var main_total: int = 0
var side_done: int = 0
var side_total: int = 0
var _state := {}
var _order: Array[String] = []
var _main_finished := false


func _ready() -> void:
	add_to_group("objective_manager")
	for o in objectives:
		var id: String = o["id"]
		_order.append(id)
		_state[id] = {"text": o["text"], "total": int(o["total"]), "done": 0, "main": bool(o["main"])}
	_recount()
	main_progress.emit(main_done, main_total)
	side_progress.emit(side_done, side_total)


func has_objective(id: String) -> bool:
	return _state.has(id)


func main_finished() -> bool:
	return _main_finished


func get_lines() -> Array:
	var out: Array = []
	for id in _order:
		var s: Dictionary = _state[id]
		out.append({"id": id, "text": s["text"], "done": s["done"], "total": s["total"], "main": s["main"]})
	return out


func _recount() -> void:
	main_done = 0
	main_total = 0
	side_done = 0
	side_total = 0
	for id in _order:
		var s: Dictionary = _state[id]
		if s["main"]:
			main_done += s["done"]
			main_total += s["total"]
		else:
			side_done += s["done"]
			side_total += s["total"]


func report(id: String, amount: int = 1) -> void:
	if not _state.has(id):
		return
	var s: Dictionary = _state[id]
	if s["done"] >= s["total"]:
		return
	s["done"] = mini(s["total"], s["done"] + amount)
	_recount()
	objective_changed.emit(id)
	if s["main"]:
		main_progress.emit(main_done, main_total)
	else:
		side_progress.emit(side_done, side_total)
	if s["done"] >= s["total"]:
		objective_completed.emit(id)
		if not s["main"]:
			side_complete.emit(id)
		if s["main"] and not _main_finished and main_done >= main_total:
			_main_finished = true
			main_complete.emit()
