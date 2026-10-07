extends Area3D
## Extraction gate. Appears once the level's main objective is complete, but
## stays closed until the player enters the "Open Extraction" rune code
## while standing near it. Then a survive-countdown starts; success advances
## to the next level.

signal armed
signal opened
signal countdown_tick(seconds_left: float)
signal extraction_success

const C := preload("res://scripts/model_utils.gd")

@export var survive_time: float = 30.0
@export var open_radius: float = 7.0

var _unlocked := false
var _started := false
var _time_left := 0.0
var _level_manager: Node = null


func _ready() -> void:
	add_to_group("extraction_zone")
	C.beacon(self, Color(1.0, 0.9, 0.3), 34.0)
	C.label(self, "EXTRACTION", Vector3(0, 4.0, 0), Color(1.0, 0.95, 0.5), 0.014)
	monitoring = false
	visible = false
	_time_left = survive_time
	call_deferred("_find_manager")
	call_deferred("_connect_objectives")


func _find_manager() -> void:
	var mgrs := get_tree().get_nodes_in_group("level_manager")
	if mgrs.size() > 0:
		_level_manager = mgrs[0]


func _connect_objectives() -> void:
	for om in get_tree().get_nodes_in_group("objective_manager"):
		om.main_complete.connect(_arm)


func _arm() -> void:
	_unlocked = true
	visible = true
	armed.emit()


## Called by the player's "open_extraction" rune code.
## Returns "" on success, otherwise a message explaining why it failed.
func try_open(player_pos: Vector3) -> String:
	if not _unlocked:
		return "Complete the main objective first"
	if _started:
		return "Extraction already in progress"
	var d := Vector2(player_pos.x - global_position.x, player_pos.z - global_position.z).length()
	if d > open_radius:
		return "Get closer to the extraction zone"
	_started = true
	opened.emit()
	return ""


func _process(delta: float) -> void:
	if not _started or _time_left <= 0.0:
		return
	_time_left -= delta
	countdown_tick.emit(max(_time_left, 0.0))
	if _time_left <= 0.0:
		extraction_success.emit()
		if _level_manager and _level_manager.has_method("go_to_next_level"):
			_level_manager.go_to_next_level()
