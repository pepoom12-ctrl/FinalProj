extends RefCounted
## Procedural props: themed scenery + objective models. No external assets.

const C := preload("res://scripts/chibi_builder.gd")

const DECOR := {
	0: [["grave", 34], ["cross", 12], ["dead_tree", 30], ["bones", 14], ["lamp", 10], ["coffin", 5], ["crypt", 3], ["fog", 8], ["dead_bush", 22]],
	1: [["tree", 40], ["pine", 22], ["mushroom", 26], ["flower", 40], ["rock_moss", 16], ["stump", 12], ["fern", 26], ["firefly", 24]],
	2: [["spire", 30], ["lava_pool", 14], ["obsidian", 14], ["tent", 5], ["skull_pile", 12], ["banner", 10], ["bone_spike", 24], ["boulder", 20], ["smoke", 6]],
}


static func activate(model: Node3D, color: Color, glow: float = 2.0) -> void:
	var ind = model.get_meta("indicator", null)
	if ind is MeshInstance3D:
		var m: StandardMaterial3D = ind.material_override
		m.albedo_color = color
		m.emission_enabled = glow > 0.0
		m.emission = color
		m.emission_energy_multiplier = glow


# ------------------------------------------------------------ objective models

static func make(kind: String, p: float = 1.0) -> Node3D:
	var r := Node3D.new()
	r.name = "Prop"
	match kind:
		"gravestone": _gravestone(r)
		"totem": _totem(r)
		"drum": _drum(r)
		"soul": _soul(r)
		"fountain": _fountain(r, p)
		"altar": _altar(r, p)
		"alarm": _alarm(r)
		"valve": _valve(r)
		"lantern": _lantern(r)
		"core": _core(r)
		"platform": _platform(r)
	return r


static func _gravestone(r: Node3D) -> void:
	var stone := Color(0.4, 0.42, 0.47)
	C.part(r, r, C.bx(Vector3(1.9, 0.3, 1.0)), Vector3(0, 0.15, 0), Color(0.3, 0.3, 0.34))
	C.part(r, r, C.bx(Vector3(1.3, 1.7, 0.42)), Vector3(0, 1.15, 0), stone)
	C.part(r, r, C.cy(0.65, 0.65, 0.42, 16), Vector3(0, 2.0, 0), stone, 0.0, Vector3(90, 0, 0))
	C.part(r, r, C.bx(Vector3(0.12, 0.8, 0.05)), Vector3(0, 1.5, -0.23), Color(0.75, 0.3, 1.0), 2.2)
	C.part(r, r, C.bx(Vector3(0.55, 0.12, 0.05)), Vector3(0, 1.7, -0.23), Color(0.75, 0.3, 1.0), 2.2)
	C.part(r, r, C.sph(0.3), Vector3(0, 3.0, 0), Color(0.95, 0.93, 0.8))
	for sx in [-1.0, 1.0]:
		C.part(r, r, C.sph(0.07), Vector3(sx * 0.1, 3.02, -0.25), Color(0.6, 0.2, 1.0), 2.5)
	for i in 3:
		C.part(r, r, C.sph(0.13), Vector3(cos(i * 2.1) * 1.1, 1.2 + i * 0.35, sin(i * 2.1) * 0.6), Color(0.6, 0.3, 1.0), 2.5)
	C.part(r, r, C.sph(0.4), Vector3(0.5, 0.35, -0.3), Color(0.25, 0.4, 0.2), 0.0, Vector3.ZERO, Vector3(1, 0.4, 1))


static func _totem(r: Node3D) -> void:
	var wood := Color(0.45, 0.3, 0.18)
	C.part(r, r, C.cy(0.7, 0.8, 0.3), Vector3(0, 0.15, 0), Color(0.4, 0.4, 0.38))
	C.part(r, r, C.cy(0.5, 0.6, 3.2, 10), Vector3(0, 1.8, 0), wood)
	C.part(r, r, C.bx(Vector3(1.3, 0.8, 1.1)), Vector3(0, 1.4, 0), Color(0.5, 0.33, 0.2))
	for sx in [-1.0, 1.0]:
		C.part(r, r, C.sph(0.14), Vector3(sx * 0.3, 1.5, -0.56), Color(0.3, 1.0, 0.9), 3.0, Vector3.ZERO, Vector3(1.3, 0.8, 0.5))
		C.part(r, r, C.bx(Vector3(1.4, 0.22, 0.3)), Vector3(sx * 0.95, 2.6, 0), wood, 0.0, Vector3(0, 0, sx * -18.0))
		C.part(r, r, C.cy(0.0, 0.12, 0.7, 6), Vector3(sx * 0.6, 3.0, 0), Color(0.3, 0.75, 0.45), 0.5, Vector3(0, 0, -sx * 30.0))
	C.part(r, r, C.bx(Vector3(0.5, 0.12, 0.1)), Vector3(0, 1.15, -0.56), Color(0.15, 0.08, 0.05))
	C.part(r, r, C.sph(0.4), Vector3(0, 3.7, 0), Color(0.3, 1.0, 0.8), 2.5)
	C.part(r, r, C.cy(0.04, 0.04, 2.0, 5), Vector3(0.45, 1.6, 0.4), Color(0.2, 0.55, 0.25), 0.0, Vector3(5, 0, 8))


static func _drum(r: Node3D) -> void:
	C.part(r, r, C.cy(0.95, 0.8, 1.1), Vector3(0, 0.9, 0), Color(0.45, 0.28, 0.15))
	C.part(r, r, C.cy(0.97, 0.97, 0.06), Vector3(0, 1.46, 0), Color(0.9, 0.82, 0.65))
	C.part(r, r, C.cy(0.92, 0.92, 0.09), Vector3(0, 0.9, 0), Color(0.75, 0.12, 0.1), 0.3)
	for i in 3:
		var a := i * 2.094
		C.part(r, r, C.cy(0.0, 0.09, 1.2, 6), Vector3(cos(a) * 0.9, 0.5, sin(a) * 0.9), Color(0.85, 0.8, 0.65), 0.0, Vector3(sin(a) * 15.0, 0, -cos(a) * 15.0))
	C.part(r, r, C.cy(0.0, 0.5, 0.9, 6), Vector3(0, 2.0, 0), Color(0.75, 0.12, 0.1), 0.8)
	C.part(r, r, C.sph(0.22), Vector3(0, 1.7, -0.4), Color(0.93, 0.9, 0.78))


static func _soul(r: Node3D) -> void:
	C.part(r, r, C.sph(0.34), Vector3.ZERO, Color(0.6, 0.9, 1.0), 3.0)
	C.part(r, r, C.tor(0.45, 0.55), Vector3.ZERO, Color(0.5, 0.8, 1.0), 2.0, Vector3(70, 0, 20))
	for i in 3:
		C.part(r, r, C.sph(0.08), Vector3(cos(i * 2.1) * 0.7, sin(i * 2.1) * 0.3, sin(i * 2.1) * 0.7), Color(0.8, 1.0, 1.0), 3.0)


static func _fountain(r: Node3D, rad: float) -> void:
	C.part(r, r, C.cy(rad, rad + 0.2, 0.45, 24), Vector3(0, 0.22, 0), Color(0.55, 0.57, 0.62))
	C.part(r, r, C.cy(rad - 0.3, rad - 0.3, 0.1, 24), Vector3(0, 0.42, 0), Color(0.3, 0.8, 1.0), 1.3)
	C.part(r, r, C.cy(0.35, 0.5, 1.4), Vector3(0, 1.0, 0), Color(0.6, 0.62, 0.68))
	C.part(r, r, C.sph(0.4), Vector3(0, 1.9, 0), Color(0.5, 0.9, 1.0), 2.0)
	for i in 4:
		C.part(r, r, C.sph(0.15), Vector3(cos(i * 1.57) * 1.0, 1.0, sin(i * 1.57) * 1.0), Color(0.5, 0.9, 1.0), 1.5)
	C.part(r, r, C.bx(Vector3(0.12, 0.8, 0.12)), Vector3(0, 2.7, 0), Color(1.0, 0.95, 0.7), 1.2)
	C.part(r, r, C.bx(Vector3(0.5, 0.12, 0.12)), Vector3(0, 2.8, 0), Color(1.0, 0.95, 0.7), 1.2)


static func _altar(r: Node3D, rad: float) -> void:
	C.part(r, r, C.cy(rad, rad + 0.2, 0.4, 24), Vector3(0, 0.2, 0), Color(0.15, 0.1, 0.12))
	C.part(r, r, C.tor(rad - 0.5, rad - 0.3), Vector3(0, 0.45, 0), Color(1.0, 0.4, 0.08), 2.0)
	C.part(r, r, C.cy(0.0, 0.7, 2.2, 5), Vector3(0, 1.5, 0), Color(0.13, 0.08, 0.2), 0.3)
	C.part(r, r, C.sph(0.3), Vector3(0, 2.8, 0), Color(1.0, 0.5, 0.1), 2.5)
	for i in 4:
		C.part(r, r, C.cy(0.0, 0.2, 1.2, 5), Vector3(cos(i * 1.57) * (rad - 0.9), 0.9, sin(i * 1.57) * (rad - 0.9)), Color(0.13, 0.08, 0.2))


static func _alarm(r: Node3D) -> void:
	C.part(r, r, C.cy(0.5, 0.6, 0.2), Vector3(0, 0.1, 0), Color(0.4, 0.4, 0.38))
	C.part(r, r, C.cy(0.12, 0.16, 3.0, 8), Vector3(0, 1.5, 0), Color(0.45, 0.3, 0.18))
	C.part(r, r, C.bx(Vector3(1.0, 0.12, 0.12)), Vector3(0.3, 2.95, 0), Color(0.45, 0.3, 0.18))
	C.part(r, r, C.cy(0.0, 0.5, 0.7, 10), Vector3(0.7, 2.55, 0), Color(0.8, 0.6, 0.2))
	var ind := C.part(r, r, C.sph(0.25), Vector3(0, 3.25, 0), Color(1.0, 0.1, 0.1), 3.0)
	ind.material_override = C.mat(Color(1.0, 0.1, 0.1), 3.0)
	r.set_meta("indicator", ind)


static func _valve(r: Node3D) -> void:
	var metal := Color(0.35, 0.35, 0.4)
	C.part(r, r, C.cy(0.4, 0.4, 2.6, 10), Vector3(0, 0.9, 0), metal, 0.0, Vector3(0, 0, 90))
	C.part(r, r, C.cy(0.35, 0.35, 1.8, 10), Vector3(-0.5, 1.4, 0), metal)
	C.part(r, r, C.tor(0.42, 0.62), Vector3(-0.5, 2.4, 0), Color(0.8, 0.15, 0.1), 0.3)
	C.part(r, r, C.bx(Vector3(1.1, 0.08, 0.1)), Vector3(-0.5, 2.4, 0), Color(0.8, 0.15, 0.1))
	C.part(r, r, C.bx(Vector3(0.1, 0.08, 1.1)), Vector3(-0.5, 2.4, 0), Color(0.8, 0.15, 0.1))
	C.part(r, r, C.sph(0.3), Vector3(1.4, 0.9, 0), Color(1.0, 0.4, 0.05), 2.0)
	var ind := C.part(r, r, C.sph(0.28), Vector3(0.6, 2.0, 0), Color(1.0, 0.4, 0.05), 3.0)
	r.set_meta("indicator", ind)


static func _lantern(r: Node3D) -> void:
	C.part(r, r, C.cy(0.08, 0.12, 2.6, 8), Vector3(0, 1.3, 0), Color(0.3, 0.22, 0.15))
	C.part(r, r, C.bx(Vector3(0.9, 0.08, 0.08)), Vector3(0.4, 2.55, 0), Color(0.3, 0.22, 0.15))
	C.part(r, r, C.cy(0.0, 0.3, 0.2, 6), Vector3(0.8, 2.3, 0), Color(0.3, 0.22, 0.15))
	var ind := C.part(r, r, C.bx(Vector3(0.4, 0.55, 0.4)), Vector3(0.8, 1.95, 0), Color(0.35, 0.35, 0.4))
	r.set_meta("indicator", ind)


static func _core(r: Node3D) -> void:
	C.part(r, r, C.cy(0.0, 0.5, 0.9, 6), Vector3(0, 0.45, 0), Color(0.3, 1.0, 0.6), 3.0)
	C.part(r, r, C.cy(0.5, 0.0, 0.9, 6), Vector3(0, -0.45, 0), Color(0.3, 1.0, 0.6), 3.0)
	C.part(r, r, C.tor(0.75, 0.85), Vector3.ZERO, Color(0.5, 1.0, 0.8), 2.0)


static func _platform(r: Node3D) -> void:
	C.part(r, r, C.cy(2.4, 2.6, 0.25, 20), Vector3(0, 0.12, 0), Color(0.3, 0.35, 0.5))
	C.part(r, r, C.tor(1.6, 1.9), Vector3(0, 0.3, 0), Color(0.3, 0.7, 1.0), 2.0)
	for i in 4:
		var a := i * 1.571 + 0.785
		C.part(r, r, C.cy(0.18, 0.22, 1.2, 8), Vector3(cos(a) * 2.1, 0.7, sin(a) * 2.1), Color(0.4, 0.45, 0.6))
		C.part(r, r, C.sph(0.2), Vector3(cos(a) * 2.1, 1.45, sin(a) * 2.1), Color(0.3, 0.7, 1.0), 2.5)


# ------------------------------------------------------------------- scenery

static func decor(kind: String) -> Node3D:
	var r := Node3D.new()
	match kind:
		"grave": _grave(r)
		"cross": _cross(r)
		"dead_tree": _dead_tree(r)
		"bones": _bones(r)
		"lamp": _lamp(r)
		"coffin": _coffin(r)
		"crypt": _crypt(r)
		"fog": _fog(r)
		"dead_bush": _dead_bush(r)
		"fence": _fence(r)
		"tree": _tree(r)
		"pine": _pine(r)
		"mushroom": _mushroom(r)
		"flower": _flower(r)
		"rock_moss": _rock(r, true)
		"stump": _stump(r)
		"fern": _fern(r)
		"firefly": _firefly(r)
		"spire": _spire(r)
		"lava_pool": _lava(r)
		"obsidian": _obsidian(r)
		"tent": _tent(r)
		"skull_pile": _skulls(r)
		"banner": _banner(r)
		"bone_spike": _bone_spike(r)
		"boulder": _rock(r, false)
		"smoke": _smoke(r)
	return r


static func _grave(r: Node3D) -> void:
	var g := randf_range(0.75, 1.05)
	var stone := Color(0.42 * g, 0.44 * g, 0.48 * g)
	var h := randf_range(0.8, 1.4)
	C.part(r, r, C.bx(Vector3(0.9, h, 0.25)), Vector3(0, h * 0.5, 0), stone)
	C.part(r, r, C.cy(0.45, 0.45, 0.25, 12), Vector3(0, h, 0), stone, 0.0, Vector3(90, 0, 0))
	C.part(r, r, C.bx(Vector3(1.2, 0.12, 0.7)), Vector3(0, 0.06, 0.1), Color(0.3, 0.27, 0.22))
	if randf() < 0.5:
		C.part(r, r, C.sph(0.22), Vector3(randf_range(-0.3, 0.3), 0.15, -0.3), Color(0.25, 0.4, 0.2), 0.0, Vector3.ZERO, Vector3(1, 0.4, 1))
	r.rotation_degrees.z = randf_range(-7, 7)


static func _cross(r: Node3D) -> void:
	var stone := Color(0.45, 0.45, 0.5)
	C.part(r, r, C.bx(Vector3(0.18, 1.5, 0.18)), Vector3(0, 0.75, 0), stone)
	C.part(r, r, C.bx(Vector3(0.7, 0.18, 0.18)), Vector3(0, 1.1, 0), stone)
	C.part(r, r, C.bx(Vector3(0.8, 0.12, 0.6)), Vector3(0, 0.06, 0), Color(0.3, 0.27, 0.22))
	r.rotation_degrees.z = randf_range(-10, 10)


static func _dead_tree(r: Node3D) -> void:
	var wood := Color(0.24, 0.17, 0.13)
	var h := randf_range(2.6, 4.2)
	C.part(r, r, C.cy(0.1, 0.3, h, 8), Vector3(0, h * 0.5, 0), wood, 0.0, Vector3(randf_range(-6, 6), 0, randf_range(-6, 6)))
	for i in 4:
		var holder := Node3D.new()
		holder.position = Vector3(0, h * randf_range(0.45, 0.95), 0)
		holder.rotation_degrees.y = randf() * 360.0
		r.add_child(holder)
		C.part(r, holder, C.cy(0.02, 0.08, 1.3, 5), Vector3(0.45, 0.35, 0), wood, 0.0, Vector3(0, 0, -50))
		C.part(r, holder, C.cy(0.01, 0.04, 0.7, 5), Vector3(0.95, 0.9, 0), wood, 0.0, Vector3(0, 0, 25))


static func _bones(r: Node3D) -> void:
	var bone := Color(0.9, 0.87, 0.75)
	C.part(r, r, C.sph(0.2), Vector3(0, 0.18, 0), bone)
	C.part(r, r, C.sph(0.05), Vector3(-0.07, 0.2, -0.17), Color(0.05, 0.04, 0.05))
	C.part(r, r, C.sph(0.05), Vector3(0.07, 0.2, -0.17), Color(0.05, 0.04, 0.05))
	for i in 4:
		C.part(r, r, C.cap(0.04, 0.6), Vector3(randf_range(-0.6, 0.6), 0.06, randf_range(-0.6, 0.6)), bone, 0.0, Vector3(90, randf() * 180.0, 0))


static func _lamp(r: Node3D) -> void:
	C.part(r, r, C.cy(0.06, 0.1, 2.2, 6), Vector3(0, 1.1, 0), Color(0.15, 0.15, 0.18))
	C.part(r, r, C.bx(Vector3(0.3, 0.3, 0.3)), Vector3(0, 2.3, 0), Color(0.15, 0.15, 0.18))
	C.part(r, r, C.sph(0.16), Vector3(0, 2.3, 0), Color(0.5, 1.0, 0.6), 3.0)


static func _coffin(r: Node3D) -> void:
	C.part(r, r, C.bx(Vector3(0.8, 0.45, 1.8)), Vector3(0, 0.22, 0), Color(0.3, 0.2, 0.13))
	C.part(r, r, C.bx(Vector3(0.85, 0.08, 1.85)), Vector3(0.15, 0.5, 0.1), Color(0.35, 0.24, 0.15), 0.0, Vector3(0, 12, 6))
	r.rotation_degrees.z = randf_range(-6, 6)


static func _crypt(r: Node3D) -> void:
	C.part(r, r, C.bx(Vector3(3.2, 2.4, 2.8)), Vector3(0, 1.2, 0), Color(0.33, 0.34, 0.38))
	C.part(r, r, C.prism(Vector3(3.6, 1.0, 3.2)), Vector3(0, 2.9, 0), Color(0.22, 0.22, 0.27))
	C.part(r, r, C.bx(Vector3(1.15, 1.75, 0.06)), Vector3(0, 0.88, -1.41), Color(0.3, 1.0, 0.5), 2.0)
	C.part(r, r, C.bx(Vector3(1.0, 1.6, 0.1)), Vector3(0, 0.8, -1.44), Color(0.04, 0.04, 0.05))
	for sx in [-1.0, 1.0]:
		C.part(r, r, C.cy(0.2, 0.25, 2.6, 8), Vector3(sx * 1.9, 1.3, -1.3), Color(0.4, 0.4, 0.45))


static func _fog(r: Node3D) -> void:
	C.part(r, r, C.sph(5.0), Vector3(0, 0.4, 0), Color(0.75, 0.8, 0.9), 0.0, Vector3.ZERO, Vector3(1, 0.07, 1), 0.14)


static func _dead_bush(r: Node3D) -> void:
	var wood := Color(0.28, 0.2, 0.14)
	for i in 5:
		var a := randf() * 360.0
		C.part(r, r, C.cy(0.0, 0.05, randf_range(0.6, 1.1), 5), Vector3(cos(deg_to_rad(a)) * 0.2, 0.4, sin(deg_to_rad(a)) * 0.2), wood, 0.0, Vector3(sin(deg_to_rad(a)) * 35.0, 0, -cos(deg_to_rad(a)) * 35.0))


static func _fence(r: Node3D) -> void:
	var iron := Color(0.14, 0.14, 0.17)
	for sx in [-1.6, 1.6]:
		C.part(r, r, C.cy(0.06, 0.08, 1.6, 6), Vector3(sx, 0.8, 0), iron)
		C.part(r, r, C.cy(0.0, 0.09, 0.25, 6), Vector3(sx, 1.7, 0), iron)
	C.part(r, r, C.bx(Vector3(3.2, 0.06, 0.06)), Vector3(0, 1.3, 0), iron)
	C.part(r, r, C.bx(Vector3(3.2, 0.06, 0.06)), Vector3(0, 0.6, 0), iron)
	for i in 3:
		C.part(r, r, C.cy(0.0, 0.04, 1.3, 5), Vector3(-0.8 + i * 0.8, 0.75, 0), iron)


static func _tree(r: Node3D) -> void:
	var h := randf_range(2.2, 3.2)
	C.part(r, r, C.cy(0.22, 0.38, h, 8), Vector3(0, h * 0.5, 0), Color(0.42, 0.29, 0.18))
	var cols := [Color(0.18, 0.55, 0.35), Color(0.25, 0.65, 0.4), Color(0.3, 0.75, 0.5)]
	for i in 3:
		C.part(r, r, C.sph(1.9 - i * 0.45), Vector3(randf_range(-0.2, 0.2), h + 0.6 + i * 0.8, randf_range(-0.2, 0.2)), cols[i], 0.25)


static func _pine(r: Node3D) -> void:
	C.part(r, r, C.cy(0.15, 0.25, 1.2, 6), Vector3(0, 0.6, 0), Color(0.35, 0.24, 0.15))
	for i in 3:
		C.part(r, r, C.cy(0.0, 1.5 - i * 0.35, 1.7, 8), Vector3(0, 1.5 + i * 1.0, 0), Color(0.12, 0.42 + i * 0.07, 0.38), 0.2)


static func _mushroom(r: Node3D) -> void:
	var caps := [Color(0.85, 0.25, 0.5), Color(0.4, 0.4, 0.95), Color(0.7, 0.3, 0.9)]
	var c: Color = caps[randi() % 3]
	var s := randf_range(0.7, 1.5)
	C.part(r, r, C.cy(0.18 * s, 0.24 * s, 0.9 * s, 8), Vector3(0, 0.45 * s, 0), Color(0.95, 0.92, 0.8))
	C.part(r, r, C.sph(0.75 * s), Vector3(0, 1.0 * s, 0), c, 0.5, Vector3.ZERO, Vector3(1, 0.6, 1))
	for i in 4:
		var a := i * 1.57 + 0.5
		C.part(r, r, C.sph(0.1 * s), Vector3(cos(a) * 0.4 * s, 1.25 * s, sin(a) * 0.4 * s), Color.WHITE, 1.0)


static func _flower(r: Node3D) -> void:
	var pal := [Color(1.0, 0.5, 0.8), Color(0.5, 0.8, 1.0), Color(1.0, 0.9, 0.4)]
	C.part(r, r, C.cy(0.02, 0.03, 0.6, 5), Vector3(0, 0.3, 0), Color(0.2, 0.6, 0.3))
	C.part(r, r, C.sph(0.14), Vector3(0, 0.65, 0), pal[randi() % 3], 2.0)


static func _rock(r: Node3D, mossy: bool) -> void:
	var s := randf_range(0.8, 1.6)
	C.part(r, r, C.sph(s), Vector3(0, s * 0.5, 0), Color(0.4, 0.4, 0.42) if mossy else Color(0.3, 0.2, 0.17), 0.0, Vector3.ZERO, Vector3(1.1, 0.7, 1.0))
	if mossy:
		C.part(r, r, C.sph(s * 0.8), Vector3(0, s * 0.8, 0), Color(0.2, 0.55, 0.3), 0.2, Vector3.ZERO, Vector3(1, 0.3, 1))


static func _stump(r: Node3D) -> void:
	C.part(r, r, C.cy(0.45, 0.5, 0.6, 10), Vector3(0, 0.3, 0), Color(0.4, 0.28, 0.17))
	C.part(r, r, C.cy(0.4, 0.4, 0.04, 10), Vector3(0, 0.61, 0), Color(0.75, 0.6, 0.4))


static func _fern(r: Node3D) -> void:
	for i in 5:
		var a := i * 1.257
		C.part(r, r, C.cy(0.0, 0.1, 0.9, 4), Vector3(cos(a) * 0.3, 0.35, sin(a) * 0.3), Color(0.2, 0.65, 0.35), 0.2, Vector3(sin(a) * 40.0, 0, -cos(a) * 40.0))


static func _firefly(r: Node3D) -> void:
	C.part(r, r, C.sph(0.09), Vector3(0, randf_range(1.5, 3.5), 0), Color(0.9, 1.0, 0.4), 3.0)


static func _spire(r: Node3D) -> void:
	for i in 3:
		C.part(r, r, C.cy(0.0, randf_range(0.7, 1.5), randf_range(3.0, 7.0), 6), Vector3(randf_range(-1.0, 1.0), 2.0, randf_range(-1.0, 1.0)), Color(0.17, 0.14, 0.15))
	if randf() < 0.4:
		C.part(r, r, C.sph(0.5), Vector3(0, 0.1, 0), Color(1.0, 0.35, 0.05), 1.5, Vector3.ZERO, Vector3(1.8, 0.3, 1.8))


static func _lava(r: Node3D) -> void:
	var rad := randf_range(2.0, 5.0)
	C.part(r, r, C.cy(rad + 0.3, rad + 0.3, 0.05, 20), Vector3(0, 0.03, 0), Color(0.12, 0.08, 0.08))
	C.part(r, r, C.cy(rad, rad, 0.05, 20), Vector3(0, 0.06, 0), Color(1.0, 0.4, 0.05), 1.6)


static func _obsidian(r: Node3D) -> void:
	C.part(r, r, C.cy(0.0, 0.5, 3.2, 5), Vector3(0, 1.6, 0), Color(0.12, 0.08, 0.18), 0.3)
	C.part(r, r, C.cy(0.0, 0.3, 2.0, 5), Vector3(0.6, 1.0, 0.3), Color(0.15, 0.1, 0.22), 0.3)


static func _tent(r: Node3D) -> void:
	C.part(r, r, C.cy(0.1, 2.0, 2.6, 8), Vector3(0, 1.3, 0), Color(0.5, 0.4, 0.28))
	C.part(r, r, C.bx(Vector3(0.9, 1.4, 0.1)), Vector3(0, 0.7, -1.75), Color(0.1, 0.07, 0.05))
	C.part(r, r, C.cy(0.04, 0.04, 1.2, 5), Vector3(0, 3.0, 0), Color(0.4, 0.28, 0.15))
	C.part(r, r, C.bx(Vector3(0.6, 0.4, 0.04)), Vector3(0.3, 3.3, 0), Color(0.75, 0.12, 0.1), 0.5)


static func _skulls(r: Node3D) -> void:
	var bone := Color(0.9, 0.87, 0.75)
	for i in 6:
		var p := Vector3(randf_range(-0.5, 0.5), 0.2 + (i / 3) * 0.3, randf_range(-0.5, 0.5))
		C.part(r, r, C.sph(0.22), p, bone)
		C.part(r, r, C.sph(0.05), p + Vector3(-0.07, 0.02, -0.19), Color(0.05, 0.04, 0.05))
		C.part(r, r, C.sph(0.05), p + Vector3(0.07, 0.02, -0.19), Color(0.05, 0.04, 0.05))


static func _banner(r: Node3D) -> void:
	C.part(r, r, C.cy(0.05, 0.07, 3.4, 6), Vector3(0, 1.7, 0), Color(0.4, 0.28, 0.15))
	C.part(r, r, C.bx(Vector3(0.9, 1.3, 0.05)), Vector3(0.5, 2.6, 0), Color(0.7, 0.1, 0.08), 0.5)
	C.part(r, r, C.sph(0.2), Vector3(0.5, 2.7, -0.04), Color(0.93, 0.9, 0.78))


static func _bone_spike(r: Node3D) -> void:
	C.part(r, r, C.cy(0.0, 0.15, randf_range(1.2, 2.2), 5), Vector3(0, 0.8, 0), Color(0.88, 0.84, 0.72), 0.0, Vector3(randf_range(-15, 15), 0, randf_range(-15, 15)))


static func _smoke(r: Node3D) -> void:
	for i in 3:
		C.part(r, r, C.sph(1.4 - i * 0.2), Vector3(randf_range(-0.3, 0.3), 2.0 + i * 1.8, 0), Color(0.3, 0.28, 0.3), 0.0, Vector3.ZERO, Vector3.ONE, 0.22)
