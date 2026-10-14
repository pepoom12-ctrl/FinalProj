extends Node
## Renders the main-menu picture (res://ui/menu_bg.png): the player hero in front of a
## graveyard horde, with the game title baked in. Run this scene once to
## (re)create the picture, or replace the png with your own art.

const MU := preload("res://scripts/model_utils.gd")
const W := 1920
const H := 1080

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.seed = 4242
	var vp := SubViewport.new()
	vp.size = Vector2i(W, H)
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	_build_world(vp)
	_build_ui(vp)
	for i in 10:
		await get_tree().process_frame
	var img := vp.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("res://ui")
	var err := img.save_png("res://ui/menu_bg.png")
	print("ART_DONE ", err, " ", img.get_size())
	for gy in 9:
		var row := ""
		for gx in 16:
			var c := _avg(img, gx / 16.0, gy / 9.0, (gx + 1) / 16.0, (gy + 1) / 9.0)
			row += "%3d " % int((c.r * 0.3 + c.g * 0.59 + c.b * 0.11) * 100.0)
		print("GRID ", row)
	for pt in [Vector2(0.05, 0.9), Vector2(0.5, 0.95), Vector2(0.95, 0.9), Vector2(0.3, 0.7), Vector2(0.7, 0.62), Vector2(0.5, 0.12), Vector2(0.7, 0.1), Vector2(0.5, 0.5)]:
		var pc := img.get_pixel(int(pt.x * W), int(pt.y * H))
		print("PIX ", pt, " ", Vector3(pc.r, pc.g, pc.b) * 255.0)
	get_tree().quit()


func _avg(img: Image, x0: float, y0: float, x1: float, y1: float) -> Color:
	var sum := Color(0, 0, 0, 0)
	var n := 0
	for ix in range(int(x0 * W), int(x1 * W), 8):
		for iy in range(int(y0 * H), int(y1 * H), 8):
			sum += img.get_pixel(ix, iy)
			n += 1
	return sum / float(maxi(n, 1))


func _add_light(parent: Node3D, color: Color, energy: float, range_m: float, pos: Vector3) -> void:
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.omni_range = range_m
	l.position = pos
	parent.add_child(l)


func _build_world(vp: SubViewport) -> void:
	var world := Node3D.new()
	vp.add_child(world)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.05, 0.13)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.38, 0.7)
	env.ambient_light_energy = 0.95
	env.fog_enabled = true
	env.fog_light_color = Color(0.09, 0.13, 0.3)
	env.fog_density = 0.012
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)

	var moon_light := DirectionalLight3D.new()
	moon_light.light_color = Color(0.65, 0.75, 1.0)
	moon_light.light_energy = 1.0
	moon_light.rotation_degrees = Vector3(-35, -25, 0)
	moon_light.shadow_enabled = true
	world.add_child(moon_light)

	var ground := MeshInstance3D.new()
	ground.mesh = MU.cy(90.0, 90.0, 1.0, 48)
	ground.material_override = MU.mat(Color(0.09, 0.12, 0.11))
	ground.position.y = -0.5
	world.add_child(ground)

	var moon := MeshInstance3D.new()
	moon.mesh = MU.sph(4.5)
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.albedo_color = Color(0.93, 0.96, 1.0)
	moon.material_override = mm
	moon.position = Vector3(-13.0, 12.5, -26.0)
	world.add_child(moon)
	var halo := MeshInstance3D.new()
	halo.mesh = MU.sph(8.0)
	halo.material_override = MU.mat(Color(0.6, 0.7, 1.0), 0.0, 0.14)
	halo.position = moon.position
	world.add_child(halo)

	# --- hero
	var hero: Node3D = MU.build_player(Color(1.0, 0.5, 0.15))
	hero.position = Vector3(0, 0, 5.5)
	world.add_child(hero)
	hero.rotation.y = PI - 0.3
	var orb = hero.find_child("StaffOrb", true, false)
	if orb != null:
		_add_light(orb, Color(1.0, 0.55, 0.2), 2.4, 7.0, Vector3.ZERO)
	_add_light(world, Color(1.0, 0.72, 0.45), 1.3, 6.0, Vector3(0.6, 2.3, 7.2))

	# --- the horde behind the hero
	var cast := [
		["skeleton", Vector3(-3.6, 0, 1.0), 1.0],
		["zombie", Vector3(-6.4, 0, -1.2), 1.0],
		["elf", Vector3(3.6, 0, 1.0), 1.0],
		["orc", Vector3(6.4, 0, -1.2), 1.3],
		["skeleton", Vector3(-1.7, 0, -3.2), 1.0],
		["zombie", Vector3(1.9, 0, -3.6), 1.0],
		["skeleton", Vector3(-5.0, 0, -4.5), 1.0],
		["orc", Vector3(5.0, 0, -4.8), 1.3],
		["boss", Vector3(0, 0, -8.5), 1.0],
	]
	var spots: Array = [Vector3(0, 0, 5.5)]
	for c in cast:
		var m: Node3D
		match c[0]:
			"skeleton":
				m = MU.build_undead(0)
			"zombie":
				m = MU.build_undead(1)
			"elf":
				m = MU.build_elf()
			"orc":
				m = MU.build_orc()
			_:
				m = MU.build_boss()
		var pos: Vector3 = c[1]
		m.position = pos
		m.scale *= float(c[2])
		world.add_child(m)
		m.look_at(Vector3(0, 0, 10.0), Vector3.UP)
		spots.append(pos)

	# --- scenery
	var kinds := ["grave", "grave", "grave", "grave", "cross", "bones", "dead_bush", "coffin"]
	for i in 90:
		var pos2 := Vector3(rng.randf_range(-15.0, 15.0), 0, rng.randf_range(-14.0, 8.0))
		var ok := true
		for s in spots:
			if Vector2(pos2.x - s.x, pos2.z - s.z).length() < 1.7:
				ok = false
		if not ok:
			continue
		var prop: Node3D = MU.decor(kinds[rng.randi() % kinds.size()])
		prop.position = pos2
		prop.rotation.y = rng.randf() * TAU
		prop.scale = Vector3.ONE * rng.randf_range(1.0, 1.5)
		world.add_child(prop)
	for tx in [-10.5, -8.0, 8.5, 11.0, -13.0, 13.0]:
		var tree: Node3D = MU.decor("dead_tree")
		tree.position = Vector3(tx, 0, rng.randf_range(-6.0, 3.0))
		tree.rotation.y = rng.randf() * TAU
		tree.scale = Vector3.ONE * rng.randf_range(1.8, 2.5)
		world.add_child(tree)
	for cx in [-11.0, 12.0]:
		var crypt: Node3D = MU.decor("crypt")
		crypt.position = Vector3(cx, 0, -14.0)
		crypt.scale = Vector3.ONE * 2.6
		world.add_child(crypt)
	for lx in [-4.8, 4.8]:
		var lamp: Node3D = MU.decor("lamp")
		lamp.position = Vector3(lx, 0, 7.0)
		lamp.scale = Vector3.ONE * 1.4
		world.add_child(lamp)
		_add_light(lamp, Color(1.0, 0.65, 0.3), 1.6, 9.0, Vector3(0, 2.4, 0))
	for fx in range(-14, 15, 3):
		var fence: Node3D = MU.decor("fence")
		fence.position = Vector3(fx, 0, -12.0)
		world.add_child(fence)
	for i in 6:
		var fog: Node3D = MU.decor("fog")
		fog.position = Vector3(rng.randf_range(-8.0, 8.0), 0, rng.randf_range(-4.0, 7.0))
		fog.scale = Vector3.ONE * rng.randf_range(1.0, 1.6)
		world.add_child(fog)

	# --- embers around the hero
	for i in 60:
		var e := MeshInstance3D.new()
		e.mesh = MU.sph(rng.randf_range(0.025, 0.06))
		var em := StandardMaterial3D.new()
		em.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		em.albedo_color = Color(1.0, rng.randf_range(0.4, 0.75), 0.15)
		e.material_override = em
		e.position = Vector3(rng.randf_range(-3.2, 3.2), rng.randf_range(0.4, 4.2), rng.randf_range(3.0, 7.5))
		world.add_child(e)

	var cam := Camera3D.new()
	cam.fov = 45.0
	cam.far = 300.0
	world.add_child(cam)
	cam.position = Vector3(0, 1.7, 10.2)
	cam.look_at(Vector3(0, 1.35, 5.5))
	cam.current = true


func _build_ui(vp: SubViewport) -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp.add_child(root)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 44)
	row.anchor_left = 0.0
	row.anchor_right = 1.0
	row.offset_top = 30.0
	row.offset_bottom = 270.0
	root.add_child(row)
	var magic := _title_label("MAGIC", Color(0.62, 0.55, 1.0), Color(0.08, 0.04, 0.3))
	var mayhem := _title_label("MAYHEM", Color(1.0, 0.58, 0.18), Color(0.4, 0.05, 0.0))
	row.add_child(magic)
	row.add_child(mayhem)
	var line := ColorRect.new()
	line.color = Color(1.0, 0.82, 0.4, 0.85)
	line.anchor_left = 0.5
	line.anchor_right = 0.5
	line.offset_left = -520.0
	line.offset_right = 520.0
	line.offset_top = 282.0
	line.offset_bottom = 286.0
	root.add_child(line)
	var sub := Label.new()
	sub.text = "Hardcore PvE Swarm Survival \u2022 Arcane Action Shooter"
	sub.add_theme_font_size_override("font_size", 40)
	sub.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	sub.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	sub.add_theme_constant_override("shadow_offset_x", 3)
	sub.add_theme_constant_override("shadow_offset_y", 3)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.anchor_left = 0.0
	sub.anchor_right = 1.0
	sub.offset_top = 296.0
	sub.offset_bottom = 346.0
	root.add_child(sub)


func _title_label(text: String, color: Color, outline: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 200)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", outline)
	l.add_theme_constant_override("outline_size", 26)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_x", 5)
	l.add_theme_constant_override("shadow_offset_y", 7)
	return l
