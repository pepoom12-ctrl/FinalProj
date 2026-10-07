extends Node3D
## Builds themed scenery for a level at runtime: environment/lighting, ground
## patches, scattered props, a border wall, and a boss arena.
## theme: 0 = Graveyard, 1 = Enchanted Forest, 2 = Volcano

const PB := preload("res://scripts/model_utils.gd")
const C := preload("res://scripts/model_utils.gd")

@export var theme: int = 0
@export var map_half_size: float = 65.0


func _ready() -> void:
	call_deferred("_build")


func _build() -> void:
	_make_environment()
	var keep: Array = _keep_clear_points()
	_ground_patches()
	var table: Array = PB.DECOR[theme]
	var lim := map_half_size - 4.0
	for entry in table:
		var kind: String = entry[0]
		var count: int = entry[1]
		for i in count:
			for attempt in 8:
				var pos := Vector3(randf_range(-lim, lim), 0, randf_range(-lim, lim))
				if _place_ok(pos, keep, 6.0):
					var node: Node3D = PB.decor(kind)
					if kind in ["grave", "cross", "coffin"]:
						node.rotation.z = deg_to_rad(randf_range(-7.0, 7.0))
					var s: float = 1.0
					if not (kind in ["crypt", "fog", "lava_pool", "tent", "fence"]):
						s = randf_range(0.85, 1.25)
					_add(node, pos, randf() * 360.0, s)
					break
	_border()
	if theme == 2:
		_boss_arena()


func _add(node: Node3D, pos: Vector3, rot_y: float, scl: float = 1.0) -> void:
	node.position = pos
	node.rotation.y = deg_to_rad(rot_y)
	node.scale = Vector3.ONE * scl
	add_child(node)


func _place_ok(p: Vector3, keep: Array, min_d: float) -> bool:
	for k in keep:
		if Vector2(p.x - k.x, p.z - k.z).length() < min_d:
			return false
	return true


func _keep_clear_points() -> Array:
	var pts: Array = [Vector3.ZERO]
	for g in ["objective_prop", "extraction_zone", "boss", "player"]:
		for n in get_tree().get_nodes_in_group(g):
			if n is Node3D:
				pts.append(n.global_position)
	return pts


func _make_environment() -> void:
	var bg: Color
	var amb: Color
	var amb_e: float
	var sun_col: Color
	var sun_e: float
	match theme:
		0:
			bg = Color(0.04, 0.05, 0.09)
			amb = Color(0.45, 0.5, 0.75)
			amb_e = 0.9
			sun_col = Color(0.7, 0.75, 1.0)
			sun_e = 0.8
		1:
			bg = Color(0.03, 0.09, 0.08)
			amb = Color(0.5, 0.8, 0.7)
			amb_e = 0.95
			sun_col = Color(0.85, 1.0, 0.9)
			sun_e = 0.9
		_:
			bg = Color(0.12, 0.03, 0.02)
			amb = Color(0.9, 0.55, 0.4)
			amb_e = 0.9
			sun_col = Color(1.0, 0.7, 0.5)
			sun_e = 1.0
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = bg
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = amb
	env.ambient_light_energy = amb_e
	env.fog_enabled = true
	env.fog_light_color = bg.lerp(amb, 0.25)
	env.fog_density = 0.005
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := get_parent().get_node_or_null("Sun")
	if sun is DirectionalLight3D:
		sun.light_color = sun_col
		sun.light_energy = sun_e


func _ground_patches() -> void:
	var cols: Array
	match theme:
		0:
			cols = [Color(0.16, 0.2, 0.16), Color(0.2, 0.17, 0.14), Color(0.12, 0.14, 0.18)]
		1:
			cols = [Color(0.1, 0.3, 0.2), Color(0.16, 0.38, 0.22), Color(0.08, 0.22, 0.28)]
		_:
			cols = [Color(0.22, 0.1, 0.07), Color(0.14, 0.07, 0.06), Color(0.3, 0.14, 0.08)]
	var lim := map_half_size - 6.0
	for i in 36:
		var rad := randf_range(4.0, 11.0)
		var mi := MeshInstance3D.new()
		mi.mesh = C.cy(rad, rad, 0.02, 20)
		mi.material_override = C.mat(cols[i % 3])
		mi.position = Vector3(randf_range(-lim, lim), 0.012 + i * 0.0004, randf_range(-lim, lim))
		add_child(mi)


func _border() -> void:
	var lim := map_half_size - 1.5
	var step := 4.6
	var n := int(lim * 2.0 / step)
	for i in n + 1:
		var t := -lim + i * step
		for side in 4:
			var pos: Vector3
			var rot: float = 0.0
			match side:
				0:
					pos = Vector3(t, 0, -lim)
				1:
					pos = Vector3(t, 0, lim)
				2:
					pos = Vector3(-lim, 0, t)
					rot = 90.0
				_:
					pos = Vector3(lim, 0, t)
					rot = 90.0
			match theme:
				0:
					_add(PB.decor("fence"), pos, rot)
					if i % 3 == 0:
						_add(PB.decor("dead_tree"), pos + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * 2.0, randf() * 360.0, 1.4)
				1:
					_add(PB.decor("tree" if i % 2 == 0 else "pine"), pos, randf() * 360.0, 1.4)
				_:
					_add(PB.decor("spire"), pos, randf() * 360.0, 1.5)


func _boss_arena() -> void:
	for b in get_tree().get_nodes_in_group("boss"):
		if not b is Node3D:
			continue
		var c: Vector3 = b.global_position
		var disc := MeshInstance3D.new()
		disc.mesh = C.cy(14.0, 14.0, 0.03, 32)
		disc.material_override = C.mat(Color(0.08, 0.05, 0.07), 0.0)
		disc.position = Vector3(c.x, 0.03, c.z)
		add_child(disc)
		var ring := MeshInstance3D.new()
		ring.mesh = C.tor(13.4, 13.9)
		ring.material_override = C.mat(Color(1.0, 0.3, 0.05), 1.2)
		ring.position = Vector3(c.x, 0.06, c.z)
		add_child(ring)
		for i in 10:
			var a := i * TAU / 10.0
			_add(PB.decor("obsidian"), Vector3(c.x + cos(a) * 15.5, 0, c.z + sin(a) * 15.5), randf() * 360.0, 1.5)
