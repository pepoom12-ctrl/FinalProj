extends RefCounted
## Procedural chibi (cartoon) characters + small helpers. No external assets.
## Characters face -Z and stand with their feet at y = 0.
## Legs/arms are pivots, so animate() can swing them while walking.

static func mat(color: Color, glow: float = 0.0, alpha: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color.r, color.g, color.b, alpha)
	m.roughness = 0.9
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
	return m


static func sph(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 14
	s.rings = 7
	return s


static func cap(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = maxf(h, r * 2.0 + 0.01)
	c.radial_segments = 10
	c.rings = 4
	return c


static func bx(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


static func cy(top: float, bottom: float, h: float, seg: int = 12) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return c


static func tor(inner: float, outer: float) -> TorusMesh:
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.rings = 16
	t.ring_segments = 8
	return t


static func prism(size: Vector3) -> PrismMesh:
	var p := PrismMesh.new()
	p.size = size
	return p


## Adds a mesh to `parent`. `root` collects the materials (for hit flashes).
static func part(root: Node3D, parent: Node3D, mesh: Mesh, pos: Vector3, color: Color, glow: float = 0.0, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE, alpha: float = 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var m := mat(color, glow, alpha)
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = rot
	mi.scale = scl
	parent.add_child(mi)
	if root != null:
		var list: Array = root.get_meta("mats", [])
		list.append([m, color, glow])
		root.set_meta("mats", list)
	return mi


static func label(parent: Node3D, text: String, pos: Vector3, color: Color = Color.WHITE, pixel: float = 0.01) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.pixel_size = pixel
	l.font_size = 48
	l.outline_size = 14
	l.modulate = color
	l.no_depth_test = true
	l.position = pos
	parent.add_child(l)
	return l


static func beacon(parent: Node3D, color: Color, height: float = 16.0) -> MeshInstance3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(color.r, color.g, color.b, 0.28)
	var mi := MeshInstance3D.new()
	mi.mesh = cy(0.14, 0.14, height, 8)
	mi.material_override = m
	mi.position = Vector3(0, height * 0.5, 0)
	parent.add_child(mi)
	return mi


# ---------------------------------------------------------------- animation

static func flash(model: Node3D) -> void:
	if model == null or not is_instance_valid(model):
		return
	var mats: Array = model.get_meta("mats", [])
	for e in mats:
		var m: StandardMaterial3D = e[0]
		m.emission_enabled = true
		m.emission = Color(1, 1, 1)
		m.emission_energy_multiplier = 1.3
	var t := model.create_tween()
	t.tween_interval(0.1)
	t.tween_callback(func():
		for e in mats:
			var m: StandardMaterial3D = e[0]
			var glow: float = e[2]
			m.emission_enabled = glow > 0.0
			m.emission = e[1]
			m.emission_energy_multiplier = maxf(glow, 1.0))


## Walk cycle: body hop + sway, legs swing, free arm swings opposite the legs.
static func animate(model: Node3D, t: float, move: float, base_y: float) -> void:
	if model == null or not is_instance_valid(model):
		return
	var s := sin(t * 12.0)
	model.position.y = base_y + absf(s) * 0.12 * move + sin(t * 2.6) * 0.012
	model.rotation.z = s * 0.06 * move
	var legs: Array = model.get_meta("legs", [])
	if legs.size() == 2:
		legs[0].rotation.x = s * 0.8 * move
		legs[1].rotation.x = -s * 0.8 * move
	var arms: Array = model.get_meta("arms", [])
	if arms.size() == 2:
		var amp: float = model.get_meta("arm_amp", 0.6)
		var held = model.get_meta("held") if model.has_meta("held") else null
		for i in 2:
			var a: Node3D = arms[i]
			if a == held:
				continue
			var dir := -1.0 if i == 0 else 1.0
			a.rotation.x = float(a.get_meta("rest_x", 0.0)) + dir * s * amp * move


## Attack lunge + weapon-arm swing.
static func punch(model: Node3D) -> void:
	if model == null or not is_instance_valid(model):
		return
	var t := model.create_tween()
	t.tween_property(model, "position:z", -0.35, 0.08)
	t.tween_property(model, "position:z", 0.0, 0.15)
	var held = model.get_meta("held") if model.has_meta("held") else null
	if held is Node3D and not model.get_meta("scripted_arm", false):
		var rest: float = float(held.get_meta("rest_x", held.rotation.x))
		var t2 := model.create_tween()
		t2.tween_property(held, "rotation:x", rest - 1.3, 0.08)
		t2.tween_property(held, "rotation:x", rest + 0.9, 0.08)
		t2.tween_property(held, "rotation:x", rest, 0.2)


## Records rest poses so animate()/punch() can restore them.
static func finalize(root: Node3D, held: Node3D = null, arm_amp: float = -1.0, scripted_arm: bool = false) -> Node3D:
	for a in root.get_meta("arms", []):
		a.set_meta("rest_x", a.rotation.x)
	if held != null:
		root.set_meta("held", held)
	if arm_amp >= 0.0:
		root.set_meta("arm_amp", arm_amp)
	if scripted_arm:
		root.set_meta("scripted_arm", true)
	return root


# ------------------------------------------------------------------ builders

static func _fz(r: float, x: float, y: float) -> float:
	return -sqrt(maxf(r * r - x * x - y * y, 0.01))


static func face(root: Node3D, head: Node3D, hr: float, eye_y: float = -0.02, eye_col: Color = Color(0.1, 0.07, 0.12), spread: float = 0.17, eye_r: float = 0.1, cheeks: bool = true, eye_glow: float = 0.0) -> void:
	for sx in [-1.0, 1.0]:
		var x: float = sx * spread
		var z: float = _fz(hr, x, eye_y)
		part(root, head, sph(eye_r), Vector3(x, eye_y, z), eye_col, eye_glow, Vector3.ZERO, Vector3(1, 1.3, 0.5))
		part(root, head, sph(eye_r * 0.3), Vector3(x + 0.03, eye_y + eye_r * 0.5, z - eye_r * 0.35), Color.WHITE, 0.8)
		if cheeks:
			var cx: float = sx * (spread + 0.14)
			part(root, head, sph(0.07), Vector3(cx, eye_y - 0.11, _fz(hr, cx, eye_y - 0.11) + 0.02), Color(1.0, 0.55, 0.6), 0.0, Vector3.ZERO, Vector3(1.2, 0.6, 0.4))
	part(root, head, sph(0.03), Vector3(0, eye_y - 0.15, _fz(hr, 0.0, eye_y - 0.15)), Color(0.35, 0.12, 0.12), 0.0, Vector3.ZERO, Vector3(1.8, 0.7, 0.5))


static func humanoid(root: Node3D, o: Dictionary) -> Dictionary:
	var skin: Color = o.get("skin", Color(1.0, 0.85, 0.7))
	var cloth: Color = o.get("cloth", Color(0.3, 0.4, 0.9))
	var boot: Color = o.get("boot", Color(0.35, 0.22, 0.12))
	var arm_col: Color = o.get("arm", cloth)
	var bw: float = o.get("body_w", 0.34)
	var bh: float = o.get("body_h", 0.5)
	var leg: float = o.get("leg_h", 0.22)
	var hr: float = o.get("head_r", 0.45)
	var res := {}
	var legs: Array = []
	for sx in [-1.0, 1.0]:
		var lp := Node3D.new()
		lp.position = Vector3(sx * bw * 0.5, leg, 0)
		root.add_child(lp)
		part(root, lp, cy(0.08, 0.09, leg), Vector3(0, -leg * 0.5, 0), boot)
		part(root, lp, sph(0.12), Vector3(0, 0.07 - leg, -0.05), boot, 0.0, Vector3.ZERO, Vector3(1, 0.7, 1.4))
		legs.append(lp)
	root.set_meta("legs", legs)
	var body := Node3D.new()
	body.position = Vector3(0, leg + bh * 0.5, 0)
	root.add_child(body)
	part(root, body, cy(bw * 0.7, bw, bh), Vector3.ZERO, cloth)
	var head := Node3D.new()
	head.position = Vector3(0, leg + bh + hr * 0.75, 0)
	root.add_child(head)
	part(root, head, sph(hr), Vector3.ZERO, skin)
	var arms: Array = [null, null]
	for sx in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.position = Vector3(sx * bw * 0.9, leg + bh * 0.85, 0)
		root.add_child(arm)
		part(root, arm, cap(0.08, 0.34), Vector3(0, -0.16, 0), arm_col)
		part(root, arm, sph(0.1), Vector3(0, -0.34, 0), skin)
		arm.rotation_degrees.z = sx * 12.0
		if sx < 0:
			res["arm_l"] = arm
			arms[0] = arm
		else:
			res["arm_r"] = arm
			arms[1] = arm
	root.set_meta("arms", arms)
	res["head"] = head
	res["body"] = body
	return res


static func build_player(staff_color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Model"
	var p := humanoid(root, {"skin": Color(1.0, 0.85, 0.72), "cloth": Color(0.25, 0.35, 0.85), "boot": Color(0.3, 0.2, 0.12), "body_w": 0.36, "body_h": 0.5, "head_r": 0.46})
	var head: Node3D = p["head"]
	var body: Node3D = p["body"]
	face(root, head, 0.46, -0.03)
	part(root, head, sph(0.48), Vector3(0, 0.05, 0.13), Color(0.45, 0.26, 0.12))
	part(root, head, cy(0.62, 0.62, 0.05, 20), Vector3(0, 0.3, 0), Color(0.16, 0.22, 0.62))
	part(root, head, cy(0.0, 0.38, 0.75, 14), Vector3(0, 0.7, 0), Color(0.2, 0.28, 0.75))
	part(root, head, cy(0.385, 0.395, 0.08, 14), Vector3(0, 0.4, 0), Color(1.0, 0.82, 0.3), 0.4)
	part(root, head, sph(0.08), Vector3(0, 1.1, 0), Color(1.0, 0.9, 0.4), 1.5)
	part(root, body, cy(0.37, 0.37, 0.07), Vector3(0, 0.0, 0), Color(1.0, 0.82, 0.3), 0.3)
	part(root, body, bx(Vector3(0.7, 0.5, 0.05)), Vector3(0, 0, 0.3), Color(0.15, 0.2, 0.6))
	var arm_r: Node3D = p["arm_r"]
	var st := Node3D.new()
	st.position = Vector3(0, -0.34, -0.04)
	arm_r.add_child(st)
	part(root, st, cy(0.03, 0.035, 1.4, 8), Vector3(0, 0.4, 0), Color(0.5, 0.33, 0.15))
	part(root, st, sph(0.13), Vector3(0, 1.15, 0), staff_color, 2.0)
	part(root, st, tor(0.16, 0.21), Vector3(0, 1.15, 0), staff_color, 1.2, Vector3(60, 0, 0))
	arm_r.rotation_degrees.x = 40
	st.rotation_degrees.x = -40
	return finalize(root, arm_r)


static func build_undead(variant: int) -> Node3D:
	var root := Node3D.new()
	root.name = "Model"
	var bone := Color(0.93, 0.9, 0.78)
	if variant == 0:
		var p := humanoid(root, {"skin": bone, "cloth": Color(0.3, 0.27, 0.25), "boot": bone, "body_w": 0.27, "body_h": 0.42, "head_r": 0.5, "arm": bone, "leg_h": 0.25})
		var head: Node3D = p["head"]
		var body: Node3D = p["body"]
		for sx in [-1.0, 1.0]:
			var x: float = sx * 0.19
			var z := _fz(0.5, x, 0.0)
			part(root, head, sph(0.14), Vector3(x, 0.0, z), Color(0.05, 0.04, 0.06), 0.0, Vector3.ZERO, Vector3(1, 1.2, 0.5))
			part(root, head, sph(0.05), Vector3(x, -0.01, z - 0.05), Color(0.4, 1.0, 0.5), 2.0)
		part(root, head, cy(0.0, 0.06, 0.12, 6), Vector3(0, -0.15, _fz(0.5, 0.0, -0.15)), Color(0.05, 0.04, 0.05), 0.0, Vector3(180, 0, 0))
		part(root, head, bx(Vector3(0.36, 0.1, 0.08)), Vector3(0, -0.3, _fz(0.5, 0.0, -0.3) + 0.02), Color(0.88, 0.85, 0.74))
		for i in 3:
			part(root, head, bx(Vector3(0.015, 0.1, 0.02)), Vector3(-0.1 + i * 0.1, -0.3, _fz(0.5, 0.0, -0.3) - 0.03), Color(0.1, 0.08, 0.08))
		for i in 3:
			part(root, body, bx(Vector3(0.34, 0.04, 0.08)), Vector3(0, 0.12 - i * 0.1, -0.2), bone)
		var arm_r: Node3D = p["arm_r"]
		var sw := Node3D.new()
		sw.position = Vector3(0, -0.34, -0.05)
		arm_r.add_child(sw)
		part(root, sw, bx(Vector3(0.07, 0.7, 0.02)), Vector3(0, 0.4, 0), Color(0.55, 0.5, 0.45))
		part(root, sw, bx(Vector3(0.22, 0.05, 0.05)), Vector3(0, 0.05, 0), Color(0.4, 0.28, 0.15))
		arm_r.rotation_degrees.x = 40
		sw.rotation_degrees.x = -40
		root.set_meta("held", arm_r)
	else:
		var skin := Color(0.55, 0.78, 0.45)
		var p := humanoid(root, {"skin": skin, "cloth": Color(0.42, 0.32, 0.22), "boot": Color(0.25, 0.2, 0.15), "body_w": 0.33, "body_h": 0.46, "head_r": 0.48, "arm": skin})
		var head: Node3D = p["head"]
		face(root, head, 0.48, 0.0, Color(0.95, 0.97, 0.8), 0.18, 0.12, false)
		for sx in [-1.0, 1.0]:
			var x: float = sx * 0.18
			part(root, head, sph(0.045), Vector3(x + sx * 0.01, 0.0, _fz(0.48, x, 0.0) - 0.05), Color(0.1, 0.05, 0.05))
		part(root, head, bx(Vector3(0.22, 0.07, 0.05)), Vector3(0, -0.2, _fz(0.48, 0.0, -0.2)), Color(0.25, 0.05, 0.05))
		part(root, head, sph(0.18), Vector3(0.15, 0.42, 0.05), Color(0.2, 0.25, 0.15))
		var arm_l: Node3D = p["arm_l"]
		var arm_r: Node3D = p["arm_r"]
		arm_l.rotation_degrees.x = 80
		arm_r.rotation_degrees.x = 80
		root.set_meta("arm_amp", 0.16)
	return finalize(root)


static func build_elf() -> Node3D:
	var root := Node3D.new()
	root.name = "Model"
	var p := humanoid(root, {"skin": Color(1.0, 0.88, 0.75), "cloth": Color(0.22, 0.6, 0.35), "boot": Color(0.4, 0.28, 0.15), "body_w": 0.3, "body_h": 0.46, "head_r": 0.45})
	var head: Node3D = p["head"]
	var body: Node3D = p["body"]
	face(root, head, 0.45, -0.03, Color(0.1, 0.5, 0.3))
	part(root, head, sph(0.47), Vector3(0, 0.07, 0.13), Color(0.98, 0.88, 0.4))
	part(root, head, sph(0.14), Vector3(0, -0.02, 0.55), Color(0.98, 0.88, 0.4))
	for sx in [-1.0, 1.0]:
		part(root, head, cy(0.0, 0.09, 0.42, 8), Vector3(sx * 0.55, 0.08, 0.0), Color(1.0, 0.88, 0.75), 0.0, Vector3(0, 0, -sx * 75.0))
	part(root, body, bx(Vector3(0.5, 0.5, 0.05)), Vector3(0, 0.0, 0.27), Color(0.12, 0.38, 0.22))
	part(root, body, cy(0.31, 0.31, 0.07), Vector3(0, -0.05, 0), Color(0.55, 0.4, 0.2))
	var arm_l: Node3D = p["arm_l"]
	var bow := Node3D.new()
	bow.position = Vector3(0, -0.34, -0.05)
	arm_l.add_child(bow)
	part(root, bow, cap(0.03, 0.55), Vector3(0, 0.27, 0.0), Color(0.5, 0.33, 0.15), 0.0, Vector3(14, 0, 0))
	part(root, bow, cap(0.03, 0.55), Vector3(0, -0.27, 0.0), Color(0.5, 0.33, 0.15), 0.0, Vector3(-14, 0, 0))
	part(root, bow, cy(0.008, 0.008, 1.0, 4), Vector3(0, 0, 0.1), Color(0.9, 0.9, 0.8))
	arm_l.rotation_degrees.x = 50
	bow.rotation_degrees.x = -50
	return finalize(root, arm_l)


static func build_orc() -> Node3D:
	var root := Node3D.new()
	root.name = "Model"
	var skin := Color(0.42, 0.62, 0.3)
	var p := humanoid(root, {"skin": skin, "cloth": Color(0.4, 0.27, 0.15), "boot": Color(0.2, 0.15, 0.12), "body_w": 0.42, "body_h": 0.5, "head_r": 0.5, "arm": skin})
	var head: Node3D = p["head"]
	var body: Node3D = p["body"]
	face(root, head, 0.5, 0.0, Color(0.95, 0.8, 0.1), 0.19, 0.11, false)
	part(root, head, sph(0.22), Vector3(0, -0.2, _fz(0.5, 0.0, -0.2) + 0.1), Color(0.38, 0.56, 0.27), 0.0, Vector3.ZERO, Vector3(1.3, 0.7, 1))
	for sx in [-1.0, 1.0]:
		part(root, head, cy(0.0, 0.05, 0.16, 6), Vector3(sx * 0.14, -0.27, _fz(0.5, sx * 0.14, -0.27) - 0.02), Color(0.95, 0.93, 0.8))
		part(root, head, bx(Vector3(0.22, 0.05, 0.06)), Vector3(sx * 0.17, 0.14, _fz(0.5, sx * 0.17, 0.14) - 0.01), Color(0.12, 0.1, 0.08), 0.0, Vector3(0, 0, sx * 22.0))
		part(root, root, sph(0.19), Vector3(sx * 0.5, 0.88, 0), Color(0.5, 0.5, 0.55))
		part(root, root, cy(0.0, 0.06, 0.2, 6), Vector3(sx * 0.5, 1.06, 0), Color(0.62, 0.62, 0.66))
	part(root, body, cy(0.4, 0.4, 0.07), Vector3(0, -0.05, 0), Color(0.25, 0.18, 0.1))
	var arm_r: Node3D = p["arm_r"]
	var axe := Node3D.new()
	axe.position = Vector3(0, -0.34, -0.05)
	arm_r.add_child(axe)
	part(root, axe, cy(0.04, 0.04, 0.9, 6), Vector3(0, 0.15, 0), Color(0.45, 0.3, 0.15))
	part(root, axe, bx(Vector3(0.34, 0.28, 0.04)), Vector3(0.17, 0.52, 0), Color(0.6, 0.6, 0.65))
	arm_r.rotation_degrees.x = 35
	axe.rotation_degrees.x = -35
	return finalize(root, arm_r)


static func build_boss() -> Node3D:
	var root := Node3D.new()
	root.name = "Model"
	var skin := Color(0.3, 0.5, 0.28)
	var iron := Color(0.26, 0.27, 0.32)
	var p := humanoid(root, {"skin": skin, "cloth": iron, "boot": Color(0.15, 0.12, 0.12), "body_w": 0.5, "body_h": 0.55, "head_r": 0.5, "arm": iron, "leg_h": 0.25})
	var head: Node3D = p["head"]
	var body: Node3D = p["body"]
	face(root, head, 0.5, 0.0, Color(1.0, 0.12, 0.05), 0.2, 0.11, false, 2.5)
	part(root, head, sph(0.54), Vector3(0, 0.26, 0.08), iron, 0.0, Vector3.ZERO, Vector3(1, 0.7, 1))
	part(root, head, sph(0.22), Vector3(0, -0.2, _fz(0.5, 0.0, -0.2) + 0.1), Color(0.27, 0.46, 0.25), 0.0, Vector3.ZERO, Vector3(1.3, 0.7, 1))
	for sx in [-1.0, 1.0]:
		part(root, head, cy(0.0, 0.1, 0.6, 8), Vector3(sx * 0.5, 0.55, 0.0), Color(0.92, 0.87, 0.72), 0.0, Vector3(0, 0, -sx * 40.0))
		part(root, head, cy(0.0, 0.05, 0.16, 6), Vector3(sx * 0.14, -0.27, _fz(0.5, sx * 0.14, -0.27) - 0.02), Color(0.95, 0.93, 0.8))
		part(root, root, sph(0.3), Vector3(sx * 0.62, 1.02, 0), Color(0.34, 0.34, 0.4))
		part(root, root, cy(0.0, 0.09, 0.34, 6), Vector3(sx * 0.62, 1.3, 0), Color(0.7, 0.7, 0.75))
	for i in 3:
		part(root, head, cy(0.0, 0.07, 0.25, 6), Vector3(-0.2 + i * 0.2, 0.62, 0.05), Color(0.8, 0.75, 0.6))
	part(root, body, sph(0.13), Vector3(0, 0.0, -0.46), Color(0.93, 0.9, 0.78))
	part(root, body, cy(0.52, 0.52, 0.09), Vector3(0, -0.08, 0), Color(0.2, 0.14, 0.1))
	var arm_r: Node3D = p["arm_r"]
	var hm := Node3D.new()
	hm.position = Vector3(0, -0.34, -0.05)
	arm_r.add_child(hm)
	part(root, hm, cy(0.06, 0.06, 1.4, 8), Vector3(0, 0.2, 0), Color(0.4, 0.28, 0.15))
	part(root, hm, bx(Vector3(0.75, 0.45, 0.45)), Vector3(0, 0.95, 0), Color(0.22, 0.22, 0.26))
	part(root, hm, bx(Vector3(0.55, 0.06, 0.47)), Vector3(0, 0.95, 0), Color(1.0, 0.2, 0.08), 2.0)
	for sx in [-1.0, 1.0]:
		part(root, hm, cy(0.0, 0.12, 0.3, 6), Vector3(sx * 0.5, 0.95, 0), Color(0.5, 0.5, 0.55), 0.0, Vector3(0, 0, -sx * 90.0))
	arm_r.rotation_degrees.x = 30
	hm.rotation_degrees.x = -30
	root.scale = Vector3.ONE * 1.8
	root.set_meta("arm_r", arm_r)
	return finalize(root, arm_r, -1.0, true)


static func build_golem() -> Node3D:
	var root := Node3D.new()
	root.name = "Model"
	var stone := Color(0.56, 0.55, 0.5)
	var dark := Color(0.4, 0.4, 0.37)
	var rune := Color(0.4, 1.0, 0.55)
	var legs: Array = []
	for sx in [-1.0, 1.0]:
		var lp := Node3D.new()
		lp.position = Vector3(sx * 0.27, 0.32, 0)
		root.add_child(lp)
		part(root, lp, bx(Vector3(0.32, 0.32, 0.34)), Vector3(0, -0.16, 0), dark)
		legs.append(lp)
	root.set_meta("legs", legs)
	part(root, root, bx(Vector3(0.95, 0.75, 0.6)), Vector3(0, 0.7, 0), stone)
	part(root, root, bx(Vector3(0.5, 0.07, 0.02)), Vector3(0, 0.82, -0.31), rune, 2.0)
	part(root, root, bx(Vector3(0.07, 0.35, 0.02)), Vector3(0, 0.66, -0.31), rune, 2.0)
	part(root, root, sph(0.25), Vector3(-0.35, 1.1, 0.0), Color(0.3, 0.55, 0.25), 0.0, Vector3.ZERO, Vector3(1, 0.4, 1))
	var head := Node3D.new()
	head.position = Vector3(0, 1.3, 0)
	root.add_child(head)
	part(root, head, sph(0.42), Vector3.ZERO, stone, 0.0, Vector3.ZERO, Vector3(1, 0.85, 0.95))
	for sx in [-1.0, 1.0]:
		part(root, head, sph(0.08), Vector3(sx * 0.17, 0.03, -0.36), rune, 3.0, Vector3.ZERO, Vector3(1.3, 0.6, 0.5))
	part(root, head, bx(Vector3(0.5, 0.08, 0.1)), Vector3(0, 0.14, -0.37), dark)
	var arms: Array = [null, null]
	for sx in [-1.0, 1.0]:
		var piv := Node3D.new()
		piv.position = Vector3(sx * 0.62, 1.0, 0)
		root.add_child(piv)
		part(root, piv, bx(Vector3(0.3, 0.6, 0.3)), Vector3(0, -0.32, 0), stone)
		part(root, piv, sph(0.24), Vector3(0, -0.72, 0), dark)
		if sx < 0:
			root.set_meta("arm_l", piv)
			arms[0] = piv
		else:
			root.set_meta("arm_r", piv)
			arms[1] = piv
	root.set_meta("arms", arms)
	root.scale = Vector3.ONE * 1.25
	return finalize(root, null, 0.5)
