extends RefCounted
## Loads models from res://models/**.tscn and animates them. No procedural modelling:
## every character / prop / effect shape you see is a scene file you can edit.
## Node names the game relies on are listed in res://models/README.md

## How many scenery props to scatter per theme: [model file name, count]
const DECOR := {
	0: [["grave", 34], ["cross", 12], ["dead_tree", 30], ["bones", 14], ["lamp", 10], ["coffin", 5], ["crypt", 3], ["fog", 8], ["dead_bush", 22]],
	1: [["tree", 40], ["pine", 22], ["mushroom", 26], ["flower", 40], ["rock_moss", 16], ["stump", 12], ["fern", 26], ["firefly", 24]],
	2: [["spire", 30], ["lava_pool", 14], ["obsidian", 14], ["tent", 5], ["skull_pile", 12], ["banner", 10], ["bone_spike", 24], ["boulder", 20], ["smoke", 6]],
}


# ------------------------------------------------ tiny helpers for run-time effects

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


# ------------------------------------------------------------------ loading

static func _placeholder() -> Node3D:
	var n := Node3D.new()
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.8, 1.6, 0.8)
	mi.mesh = b
	mi.material_override = mat(Color(1.0, 0.0, 1.0))
	mi.position.y = 0.8
	n.add_child(mi)
	return n


## Returns the instanced scene, or null when the file does not exist.
static func load_scene(path: String) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var scn := load(path) as PackedScene
	if scn == null:
		return null
	return scn.instantiate() as Node3D


## Character model from res://models/<name>.tscn (magenta box if missing).
static func load_model(model_name: String) -> Node3D:
	var m := load_scene("res://models/%s.tscn" % model_name)
	if m == null:
		push_warning("Missing model: res://models/%s.tscn" % model_name)
		m = _placeholder()
	m.name = "Model"
	setup_from_scene(m)
	return m


## Gives every mesh its own material copy so a hit flash only affects one body.
static func unique_materials(root: Node) -> void:
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		if mi.material_override != null:
			mi.material_override = mi.material_override.duplicate()


## Finds the LegL/LegR/ArmL/ArmR/Weapon nodes by name for the walk animation.
static func setup_from_scene(m: Node3D) -> void:
	unique_materials(m)
	var ll = m.find_child("LegL", true, false)
	var lr = m.find_child("LegR", true, false)
	if ll != null and lr != null:
		m.set_meta("legs", [ll, lr])
	var al = m.find_child("ArmL", true, false)
	var ar = m.find_child("ArmR", true, false)
	if al != null and ar != null:
		m.set_meta("arms", [al, ar])
		m.set_meta("arm_l", al)
		m.set_meta("arm_r", ar)
		al.set_meta("rest_x", al.rotation.x)
		ar.set_meta("rest_x", ar.rotation.x)
		for a in [al, ar]:
			if a.find_child("Weapon", false, false) != null:
				m.set_meta("held", a)


static func build_player(staff_color: Color) -> Node3D:
	var m := load_model("player")
	for nm in ["StaffOrb", "StaffRing"]:
		var n = m.find_child(nm, true, false)
		if n != null and n.material_override is StandardMaterial3D:
			var mt: StandardMaterial3D = n.material_override
			mt.albedo_color = staff_color
			mt.emission = staff_color
	return m


static func build_undead(variant: int) -> Node3D:
	return load_model("skeleton" if variant == 0 else "zombie")


static func build_elf() -> Node3D:
	return load_model("elf")


static func build_orc() -> Node3D:
	return load_model("orc")


static func build_boss() -> Node3D:
	return load_model("boss")


static func build_golem() -> Node3D:
	return load_model("golem")


## Quest object from res://models/objectives/<kind>.tscn
static func make(kind: String, _p: float = 1.0) -> Node3D:
	var n := load_scene("res://models/objectives/%s.tscn" % kind)
	if n == null:
		push_warning("Missing model: res://models/objectives/%s.tscn" % kind)
		n = _placeholder()
	n.name = "Prop"
	unique_materials(n)
	return n


## Scenery from res://models/{graveyard,forest,volcano}/<kind>.tscn
static func decor(kind: String) -> Node3D:
	for g in ["graveyard", "forest", "volcano"]:
		var n := load_scene("res://models/%s/%s.tscn" % [g, kind])
		if n != null:
			return n
	push_warning("Missing scenery model: %s" % kind)
	return _placeholder()


## Recolours the node named "Indicator" (alarm light, valve gauge, lantern glass).
static func activate(model: Node3D, color: Color, glow: float = 2.0) -> void:
	var ind = model.find_child("Indicator", true, false)
	if ind is MeshInstance3D and ind.material_override is StandardMaterial3D:
		var m: StandardMaterial3D = ind.material_override
		m.albedo_color = color
		m.emission_enabled = glow > 0.0
		m.emission = color
		m.emission_energy_multiplier = glow


# ----------------------------------------------------------------- animation

static func flash(model: Node3D) -> void:
	if model == null or not is_instance_valid(model):
		return
	if model.has_meta("flashing"):
		return
	model.set_meta("flashing", true)
	var saved: Array = []
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m = mi.material_override
		if m is StandardMaterial3D:
			saved.append([m, m.emission_enabled, m.emission, m.emission_energy_multiplier])
			m.emission_enabled = true
			m.emission = Color(1, 1, 1)
			m.emission_energy_multiplier = 1.3
	var t := model.create_tween()
	t.tween_interval(0.1)
	t.tween_callback(func():
		for e in saved:
			var mm: StandardMaterial3D = e[0]
			mm.emission_enabled = e[1]
			mm.emission = e[2]
			mm.emission_energy_multiplier = e[3]
		model.remove_meta("flashing"))


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
