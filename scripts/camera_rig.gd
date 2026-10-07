extends Node3D
## Top-down follow camera rig (Helldivers 1 / Magicka style).
## Stays at a fixed height + angle above the player, tracking X/Z position
## only — it never rotates with the player's aim direction.

@export var height: float = 13.0
@export var back_offset: float = 9.0
@export var follow_speed: float = 6.0
@export var tilt_degrees: float = -58.0

@onready var camera: Camera3D = $Camera3D

var _target: Node3D = null


func _ready() -> void:
	camera.rotation_degrees.x = tilt_degrees
	call_deferred("_find_target")


func _find_target() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_target = players[0]
		var desired := _target.global_position + Vector3(0, height, back_offset)
		global_position = desired


func _process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		call_deferred("_find_target")
		return
	var desired := _target.global_position + Vector3(0, height, back_offset)
	global_position = global_position.lerp(desired, clamp(follow_speed * delta, 0.0, 1.0))
