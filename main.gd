extends Node3D

# BACKROOMS - 3 niveles (Lobby, Zona Habitable, Tuneles)
# Todo se genera por codigo: no hay que descargar nada.
# Modelos/texturas propios: ver README.

const S := 3.0
const WALL_H := 2.8
const PR := 0.3
const WALK := 3.0
const RUN := 5.2

static var current_level: int = 0
static var menu_done: bool = false

var cfg: Dictionary
var levels_count := 3
var N := 14
var SIZE := 29
var bottles_needed := 3

var map: Array = []
var dist: Array = []
var rng := RandomNumberGenerator.new()

var head: Node3D
var cam: Camera3D
var plight: OmniLight3D
var flash: SpotLight3D
var flash_on := false
var battery := 1.0
var pos := Vector3.ZERO
var yaw := 0.0
var pitch := 0.0
var stamina := 1.0
var bob := 0.0
var last_sign := 1.0

var panel_mat: StandardMaterial3D
var flicker_t := 0.0
var flick_on := true

var entity: Node3D
var entity_active := false
var entity_timer := 0.0
var entity_path_t := 0.0
var entity_next := Vector3.ZERO
var ent_speed := 3.3
var threat := 0.0

var bottles: Array = []
var batteries: Array = []
var got := 0
var exit_node: MeshInstance3D
var exit_tile := Vector2i.ZERO

var state := "menu"
var state_time := 0.0
var hud: Control
var label: Label
var msg: Label
var msg_t := 0.0
var danger: ColorRect

var move_touch := -1
var move_origin := Vector2.ZERO
var move_vec := Vector2.ZERO
var look_touch := -1

var playback: AudioStreamGeneratorPlayback
var hum_t := 0.0
var step_env := 0.0
var clank_env := 0.0
var clank_pan := 0.5
var clank_t := 5.0


func make_levels() -> Array:
	return [
		{
			"name": "NIVEL 0 - El Lobby",
			"n": 14,
			"wall": Color(0.80, 0.72, 0.34), "wall_style": 0,
			"floor": Color(0.52, 0.42, 0.20), "floor_style": 2,
			"ceil": Color(0.85, 0.82, 0.68),
			"bg": Color(0.25, 0.22, 0.10), "fog": Color(0.35, 0.30, 0.12), "fog_d": 0.06,
			"amb": Color(0.6, 0.55, 0.3), "amb_e": 0.55,
			"light": Color(1.0, 0.93, 0.65), "light_e": 1.3, "light_r": 13.0,
			"panel": Color(1.0, 0.95, 0.7), "panel_mod": 2, "panel_e": 2.0,
			"hum": [120, 60, 240], "clank": false,
			"ent_speed": 3.3, "ent_delay": 25.0,
			"bottles": 3, "batteries": 3,
			"label_col": Color(0.35, 0.2, 0.05),
			"texts": ["NO ESTÁS SOLO", "SALIDA ->", "VUELVE", "¿HOLA?", "EL ZUMBIDO NO PARA", "NO MIRES ATRÁS", "SIGUE EL AGUA"],
			"intro": "Hiciste noclip fuera de la realidad.\nNIVEL 0. Encuentra las botellas de Agua de Almendra y la grieta de salida.\nNo estás solo."
		},
		{
			"name": "NIVEL 1 - Zona Habitable",
			"n": 16,
			"wall": Color(0.55, 0.55, 0.52), "wall_style": 1,
			"floor": Color(0.38, 0.38, 0.37), "floor_style": 1,
			"ceil": Color(0.45, 0.45, 0.43),
			"bg": Color(0.07, 0.08, 0.09), "fog": Color(0.12, 0.13, 0.14), "fog_d": 0.08,
			"amb": Color(0.35, 0.38, 0.42), "amb_e": 0.4,
			"light": Color(0.8, 0.9, 1.0), "light_e": 0.9, "light_r": 10.0,
			"panel": Color(0.8, 0.9, 1.0), "panel_mod": 3, "panel_e": 1.6,
			"hum": [50, 100, 150], "clank": true,
			"ent_speed": 3.8, "ent_delay": 18.0,
			"bottles": 4, "batteries": 4,
			"label_col": Color(0.6, 0.1, 0.1),
			"texts": ["ZONA HABITABLE", "NO CORRAS", "ELLOS ESCUCHAN", "ALMACÉN 7", "APAGA LA LUZ", "TODOS SE FUERON"],
			"intro": "NIVEL 1 - Zona Habitable.\nMás oscuro y más grande. Usa la linterna (botón LUZ o tecla F): frena a la entidad."
		},
		{
			"name": "NIVEL 2 - Túneles de servicio",
			"n": 18,
			"wall": Color(0.45, 0.30, 0.22), "wall_style": 1,
			"floor": Color(0.30, 0.22, 0.18), "floor_style": 1,
			"ceil": Color(0.35, 0.25, 0.20),
			"bg": Color(0.15, 0.05, 0.02), "fog": Color(0.35, 0.12, 0.05), "fog_d": 0.09,
			"amb": Color(0.5, 0.28, 0.18), "amb_e": 0.4,
			"light": Color(1.0, 0.55, 0.3), "light_e": 0.9, "light_r": 9.0,
			"panel": Color(1.0, 0.4, 0.15), "panel_mod": 4, "panel_e": 1.4,
			"hum": [45, 90, 181], "clank": true,
			"ent_speed": 4.3, "ent_delay": 12.0,
			"bottles": 5, "batteries": 5,
			"label_col": Color(0.9, 0.8, 0.6),
			"texts": ["CALOR", "TUBERÍAS", "NO HAY SALIDA", "TE VEN", "RESPIRA", "ÚLTIMO NIVEL"],
			"intro": "NIVEL 2 - Túneles de servicio.\nCalor y ruido de máquinas. La entidad está mucho más cerca."
		}
	]


func _ready() -> void:
	rng.randomize()
	var all_levels = make_levels()
	levels_count = all_levels.size()
	if current_level >= levels_count:
		current_level = 0
	cfg = all_levels[current_level]
	N = cfg["n"]
	SIZE = 2 * N + 1
	bottles_needed = cfg["bottles"]
	ent_speed = cfg["ent_speed"]

	build_map()
	compute_dist()
	build_world()
	build_player()
	build_items()
	build_entity()
	build_labels(cfg["texts"], 14, cfg["label_col"])
	build_hud()
	build_audio()
	update_label()
	clank_t = rng.randf_range(3.0, 8.0)

	if menu_done:
		state = "play"
		show_msg(str(cfg["intro"]) + "\nBotellas necesarias: %d" % bottles_needed, 7.0)
	else:
		state = "menu"
		show_msg("BACKROOMS\n\nToca la pantalla para empezar", 9999.0)


func start_game() -> void:
	menu_done = true
	state = "play"
	state_time = 0.0
	show_msg(str(cfg["intro"]) + "\nBotellas necesarias: %d" % bottles_needed, 7.0)


func finish_and_reload() -> void:
	if state == "won":
		if current_level >= levels_count - 1:
			current_level = 0
			menu_done = false
		else:
			current_level += 1
	get_tree().reload_current_scene()


# ---------------------------------------------------------------- MAPA

func build_map() -> void:
	map = []
	for z in SIZE:
		var row = []
		for x in SIZE:
			row.append(true)
		map.append(row)

	var stack = [Vector2i(1, 1)]
	map[1][1] = false
	var dirs = [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]
	while stack.size() > 0:
		var c: Vector2i = stack.back()
		var opts = []
		for d in dirs:
			var n: Vector2i = c + d
			if n.x > 0 and n.y > 0 and n.x < SIZE - 1 and n.y < SIZE - 1 and map[n.y][n.x]:
				opts.append(d)
		if opts.is_empty():
			stack.pop_back()
		else:
			var d2: Vector2i = opts[rng.randi() % opts.size()]
			map[c.y + d2.y / 2][c.x + d2.x / 2] = false
			var nn: Vector2i = c + d2
			map[nn.y][nn.x] = false
			stack.append(nn)

	for i in 70 + N * 3:
		var x = rng.randi_range(1, SIZE - 2)
		var z = rng.randi_range(1, SIZE - 2)
		if map[z][x]:
			var h = (not map[z][x - 1]) and (not map[z][x + 1])
			var v = (not map[z - 1][x]) and (not map[z + 1][x])
			if h or v:
				map[z][x] = false

	for i in 6:
		var w = rng.randi_range(3, 5)
		var h2 = rng.randi_range(3, 5)
		var x0 = rng.randi_range(2, SIZE - 2 - w)
		var z0 = rng.randi_range(2, SIZE - 2 - h2)
		for zz in range(z0, z0 + h2):
			for xx in range(x0, x0 + w):
				map[zz][xx] = false
		if w % 2 == 1 and h2 % 2 == 1:
			map[z0 + h2 / 2][x0 + w / 2] = true


func tile_wall(tx: int, tz: int) -> bool:
	if tx < 0 or tz < 0 or tx >= SIZE or tz >= SIZE:
		return true
	return map[tz][tx]


func compute_dist() -> void:
	dist = []
	for z in SIZE:
		var row = []
		for x in SIZE:
			row.append(-1)
		dist.append(row)
	var q = [Vector2i(1, 1)]
	dist[1][1] = 0
	var qi = 0
	while qi < q.size():
		var c: Vector2i = q[qi]
		qi += 1
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if not tile_wall(n.x, n.y) and dist[n.y][n.x] == -1:
				dist[n.y][n.x] = dist[c.y][c.x] + 1
				q.append(n)


func tile_center(t: Vector2i) -> Vector3:
	return Vector3((t.x + 0.5) * S, 0, (t.y + 0.5) * S)


# ---------------------------------------------------------------- TEXTURAS

func tex_or(path: String, img: Image) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return ImageTexture.create_from_image(img)


# style: 0 papel tapiz con rayas, 1 concreto, 2 alfombra, 3 techo
func make_surface_img(c: Color, style: int, size: int) -> Image:
	var img = Image.create(size, size, false, Image.FORMAT_RGB8)
	var nz = FastNoiseLite.new()
	nz.seed = rng.randi()
	nz.frequency = 0.04
	var stripe = maxi(1, size / 64)
	for y in size:
		for x in size:
			var base = c
			var n = rng.randf_range(-0.04, 0.04)
			if style == 0:
				if (x % (size / 8)) < stripe:
					base = base.darkened(0.12)
				if y > size - size / 14:
					base = base.darkened(0.18)
			elif style == 1:
				n += nz.get_noise_2d(x, y) * 0.14
			elif style == 2:
				n = rng.randf_range(-0.09, 0.09)
			elif style == 3:
				if x < stripe or y < stripe:
					base = base.darkened(0.3)
			img.set_pixel(x, y, Color(base.r + n, base.g + n, base.b + n * 0.7))
	if style == 2:
		for i in 22:
			var cx = rng.randi_range(0, size - 1)
			var cy = rng.randi_range(0, size - 1)
			for dy in range(-5, 6):
				for dx in range(-5, 6):
					if dx * dx + dy * dy < 25:
						var px = (cx + dx + size) % size
						var py = (cy + dy + size) % size
						img.set_pixel(px, py, img.get_pixel(px, py).darkened(0.25))
	return img


func make_mat(tex: Texture2D, scale: float) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_texture = tex
	m.roughness = 1.0
	m.uv1_scale = Vector3(scale, scale, 1.0)
	return m


# ---------------------------------------------------------------- MUNDO

func build_world() -> void:
	var lv = current_level
	var wall_tex = tex_or("res://textures/level%d_wall.png" % lv, make_surface_img(cfg["wall"], cfg["wall_style"], 128))
	var floor_tex = tex_or("res://textures/level%d_floor.png" % lv, make_surface_img(cfg["floor"], cfg["floor_style"], 128))
	var ceil_tex = tex_or("res://textures/level%d_ceiling.png" % lv, make_surface_img(cfg["ceil"], 3, 64))

	var wall_tiles = []
	for z in SIZE:
		for x in SIZE:
			if map[z][x]:
				var near_open = false
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					if not tile_wall(x + d.x, z + d.y):
						near_open = true
				if near_open:
					wall_tiles.append(Vector2i(x, z))
	var box = BoxMesh.new()
	box.size = Vector3(S, WALL_H, S)
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = box
	mm.instance_count = wall_tiles.size()
	for i in wall_tiles.size():
		var t: Vector2i = wall_tiles[i]
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3((t.x + 0.5) * S, WALL_H / 2.0, (t.y + 0.5) * S)))
	var walls = MultiMeshInstance3D.new()
	walls.multimesh = mm
	walls.material_override = make_mat(wall_tex, 1.0)
	add_child(walls)

	var plane = PlaneMesh.new()
	plane.size = Vector2(SIZE * S, SIZE * S)
	var fl = MeshInstance3D.new()
	fl.mesh = plane
	fl.material_override = make_mat(floor_tex, SIZE * 1.5)
	fl.position = Vector3(SIZE * S / 2.0, 0, SIZE * S / 2.0)
	add_child(fl)

	var ce = MeshInstance3D.new()
	ce.mesh = plane
	ce.material_override = make_mat(ceil_tex, SIZE * S / 1.2)
	ce.position = Vector3(SIZE * S / 2.0, WALL_H, SIZE * S / 2.0)
	ce.rotation_degrees = Vector3(180, 0, 0)
	add_child(ce)

	panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(1, 1, 0.9)
	panel_mat.emission_enabled = true
	panel_mat.emission = cfg["panel"]
	panel_mat.emission_energy_multiplier = cfg["panel_e"]
	var pmod: int = cfg["panel_mod"]
	var panel_tiles = []
	for z in SIZE:
		for x in SIZE:
			if not map[z][x] and (x + z) % pmod == 0:
				panel_tiles.append(Vector2i(x, z))
	var pbox = BoxMesh.new()
	pbox.size = Vector3(1.3, 0.06, 0.5)
	var pmm = MultiMesh.new()
	pmm.transform_format = MultiMesh.TRANSFORM_3D
	pmm.mesh = pbox
	pmm.instance_count = panel_tiles.size()
	for i in panel_tiles.size():
		var t2: Vector2i = panel_tiles[i]
		pmm.set_instance_transform(i, Transform3D(Basis(), Vector3((t2.x + 0.5) * S, WALL_H - 0.03, (t2.y + 0.5) * S)))
	var panels = MultiMeshInstance3D.new()
	panels.multimesh = pmm
	panels.material_override = panel_mat
	add_child(panels)

	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = cfg["bg"]
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = cfg["amb"]
	env.ambient_light_energy = cfg["amb_e"]
	env.fog_enabled = true
	env.fog_light_color = cfg["fog"]
	env.fog_density = cfg["fog_d"]
	var we = WorldEnvironment.new()
	we.environment = env
	add_child(we)


func build_labels(texts: Array, count: int, col: Color) -> void:
	var dirs = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var placed = 0
	var tries = 0
	while placed < count and tries < 500:
		tries += 1
		var x = rng.randi_range(1, SIZE - 2)
		var z = rng.randi_range(1, SIZE - 2)
		if map[z][x]:
			continue
		var d: Vector2i = dirs[rng.randi() % 4]
		if not tile_wall(x + d.x, z + d.y):
			continue
		var l = Label3D.new()
		l.text = texts[rng.randi() % texts.size()]
		l.font_size = 96
		l.pixel_size = 0.004
		l.modulate = col
		l.double_sided = false
		l.position = tile_center(Vector2i(x, z)) + Vector3(d.x * (S / 2.0 - 0.03), 1.3, d.y * (S / 2.0 - 0.03))
		l.rotation.y = atan2(-d.x, -d.y)
		add_child(l)
		placed += 1


func build_player() -> void:
	pos = Vector3(1.5 * S, 0, 1.5 * S)
	head = Node3D.new()
	add_child(head)
	cam = Camera3D.new()
	cam.fov = 75
	cam.near = 0.05
	cam.far = 70
	cam.current = true
	head.add_child(cam)
	plight = OmniLight3D.new()
	plight.omni_range = cfg["light_r"]
	plight.light_energy = cfg["light_e"]
	plight.light_color = cfg["light"]
	head.add_child(plight)
	flash = SpotLight3D.new()
	flash.spot_range = 20.0
	flash.spot_angle = 30.0
	flash.light_energy = 3.0
	flash.visible = false
	cam.add_child(flash)
	head.position = pos + Vector3(0, 1.65, 0)


# ---------------------------------------------------------------- OBJETOS

func build_items() -> void:
	var best = -1
	for z in SIZE:
		for x in SIZE:
			if dist[z][x] > best:
				best = dist[z][x]
				exit_tile = Vector2i(x, z)
	var rift_mesh = BoxMesh.new()
	rift_mesh.size = Vector3(1.4, 2.3, 0.08)
	var rm = StandardMaterial3D.new()
	rm.albedo_color = Color(0.8, 1, 1)
	rm.emission_enabled = true
	rm.emission = Color(0.5, 0.9, 1.0)
	rm.emission_energy_multiplier = 3.0
	exit_node = MeshInstance3D.new()
	exit_node.mesh = rift_mesh
	exit_node.material_override = rm
	exit_node.position = tile_center(exit_tile) + Vector3(0, 1.2, 0)
	add_child(exit_node)
	var rl = OmniLight3D.new()
	rl.light_color = Color(0.5, 0.9, 1.0)
	rl.omni_range = 7.0
	rl.light_energy = 1.2
	exit_node.add_child(rl)

	var cands = []
	for z in SIZE:
		for x in SIZE:
			if not map[z][x] and dist[z][x] >= 8 and Vector2i(x, z) != exit_tile:
				cands.append(Vector2i(x, z))
	cands.shuffle()

	var bmesh = CylinderMesh.new()
	bmesh.top_radius = 0.05
	bmesh.bottom_radius = 0.07
	bmesh.height = 0.3
	var bm = StandardMaterial3D.new()
	bm.albedo_color = Color(0.9, 1, 0.95)
	bm.emission_enabled = true
	bm.emission = Color(0.7, 1.0, 0.85)
	bm.emission_energy_multiplier = 1.5
	var idx = 0
	for i in bottles_needed:
		if idx >= cands.size():
			break
		var b = MeshInstance3D.new()
		b.mesh = bmesh
		b.material_override = bm
		b.position = tile_center(cands[idx]) + Vector3(0, 0.9, 0)
		add_child(b)
		bottles.append(b)
		idx += 1

	var pmesh = BoxMesh.new()
	pmesh.size = Vector3(0.12, 0.22, 0.12)
	var pm = StandardMaterial3D.new()
	pm.albedo_color = Color(1, 0.8, 0.2)
	pm.emission_enabled = true
	pm.emission = Color(1.0, 0.7, 0.1)
	pm.emission_energy_multiplier = 1.5
	var nb: int = cfg["batteries"]
	for i in nb:
		if idx >= cands.size():
			break
		var p = MeshInstance3D.new()
		p.mesh = pmesh
		p.material_override = pm
		p.position = tile_center(cands[idx]) + Vector3(0, 0.6, 0)
		add_child(p)
		batteries.append(p)
		idx += 1


func build_entity() -> void:
	entity = Node3D.new()
	var path = "res://models/entity.glb"
	if ResourceLoader.exists(path):
		var scn = load(path)
		entity.add_child(scn.instantiate())
	else:
		var black = StandardMaterial3D.new()
		black.albedo_color = Color(0.02, 0.02, 0.02)
		black.roughness = 1.0
		var body = MeshInstance3D.new()
		var cm = CapsuleMesh.new()
		cm.radius = 0.2
		cm.height = 1.5
		body.mesh = cm
		body.material_override = black
		body.position = Vector3(0, 1.2, 0)
		entity.add_child(body)
		var hd = MeshInstance3D.new()
		var sm = SphereMesh.new()
		sm.radius = 0.16
		sm.height = 0.32
		hd.mesh = sm
		hd.material_override = black
		hd.position = Vector3(0, 2.15, 0)
		hd.scale = Vector3(1, 1.4, 1)
		entity.add_child(hd)
		for sx in [-1.0, 1.0]:
			var arm = MeshInstance3D.new()
			var am = CylinderMesh.new()
			am.top_radius = 0.04
			am.bottom_radius = 0.03
			am.height = 1.5
			arm.mesh = am
			arm.material_override = black
			arm.position = Vector3(sx * 0.32, 1.05, 0.05)
			arm.rotation_degrees = Vector3(0, 0, sx * -5.0)
			entity.add_child(arm)
		var eye_mat = StandardMaterial3D.new()
		eye_mat.albedo_color = Color(1, 0, 0)
		eye_mat.emission_enabled = true
		eye_mat.emission = Color(1, 0.05, 0.05)
		eye_mat.emission_energy_multiplier = 4.0
		for sx2 in [-1.0, 1.0]:
			var eye = MeshInstance3D.new()
			var em = SphereMesh.new()
			em.radius = 0.03
			em.height = 0.06
			eye.mesh = em
			eye.material_override = eye_mat
			eye.position = Vector3(sx2 * 0.07, 2.17, 0.14)
			entity.add_child(eye)
	entity.visible = false
	add_child(entity)


func spawn_entity() -> void:
	var cands = []
	for z in SIZE:
		for x in SIZE:
			if not map[z][x] and dist[z][x] >= 0:
				var c = tile_center(Vector2i(x, z))
				if Vector2(c.x - pos.x, c.z - pos.z).length() > 30.0:
					cands.append(Vector2i(x, z))
	if cands.is_empty():
		cands.append(Vector2i(SIZE - 2, SIZE - 2))
	var t: Vector2i = cands[rng.randi() % cands.size()]
	entity.position = tile_center(t)
	entity.visible = true
	entity_active = true
	show_msg("Algo se mueve en los pasillos...", 3.0)


# ---------------------------------------------------------------- HUD

func build_hud() -> void:
	var cl = CanvasLayer.new()
	add_child(cl)

	danger = ColorRect.new()
	danger.color = Color(0.4, 0, 0, 0)
	danger.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(danger)
	danger.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.draw.connect(_draw_hud)

	label = Label.new()
	label.position = Vector2(20, 14)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(label)

	msg = Label.new()
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.add_theme_font_size_override("font_size", 30)
	msg.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	msg.add_theme_constant_override("outline_size", 8)
	msg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(msg)
	msg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	msg.offset_left = 60
	msg.offset_right = -60


func _draw_hud() -> void:
	var vs = get_viewport().get_visible_rect().size
	if move_touch != -1:
		hud.draw_circle(move_origin, 70, Color(1, 1, 1, 0.12))
		hud.draw_circle(move_origin + move_vec * 70.0, 32, Color(1, 1, 1, 0.3))
	hud.draw_rect(Rect2(20, vs.y - 30, 200.0 * stamina, 8), Color(1, 1, 1, 0.5))
	hud.draw_rect(Rect2(20, vs.y - 48, 200.0 * battery, 8), Color(1, 0.85, 0.3, 0.7))
	var a = 0.35 if flash_on else 0.15
	hud.draw_circle(Vector2(vs.x - 60, 60), 38, Color(1, 1, 1, a))
	hud.draw_string(ThemeDB.fallback_font, Vector2(vs.x - 80, 68), "LUZ", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.85))


func update_label() -> void:
	label.text = "%s  -  Agua de Almendra: %d/%d" % [cfg["name"], got, bottles_needed]


func show_msg(text: String, secs: float) -> void:
	msg.text = text
	msg_t = secs


func toggle_flash() -> void:
	if battery <= 0.01:
		show_msg("Sin batería...", 1.5)
		return
	flash_on = not flash_on
	flash.visible = flash_on


# ---------------------------------------------------------------- AUDIO

func build_audio() -> void:
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 0.25
	var ap = AudioStreamPlayer.new()
	ap.stream = gen
	add_child(ap)
	ap.play()
	playback = ap.get_stream_playback()


func fill_audio() -> void:
	if playback == null:
		return
	var f: Array = cfg["hum"]
	var n = playback.get_frames_available()
	for i in n:
		hum_t = fposmod(hum_t + 1.0 / 22050.0, 1.0)
		var s = sin(hum_t * TAU * f[0]) * 0.05 + sin(hum_t * TAU * f[1]) * 0.05 + sin(hum_t * TAU * f[2]) * 0.015
		s += (rng.randf() - 0.5) * 0.01
		s += sin(hum_t * TAU * 38.0) * 0.14 * threat
		if step_env > 0.001:
			s += ((rng.randf() - 0.5) * 0.5 + sin(hum_t * TAU * 70.0) * 0.4) * step_env * 0.25
			step_env *= 0.9989
		var cl = 0.0
		if clank_env > 0.001:
			cl = ((rng.randf() - 0.5) * 0.4 + sin(hum_t * TAU * 210.0) * 0.6) * clank_env * 0.18
			clank_env *= 0.9997
		playback.push_frame(Vector2(s + cl * (1.0 - clank_pan), s + cl * clank_pan))


# ---------------------------------------------------------------- INPUT

func _unhandled_input(event: InputEvent) -> void:
	var pressed_any = (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed)

	if state == "menu":
		if pressed_any and state_time > 0.4:
			if event is InputEventMouseButton:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			start_game()
		return
	if state != "play":
		if pressed_any and state_time > 1.0:
			finish_and_reload()
		return

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
		toggle_flash()
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * 0.0025
		pitch = clamp(pitch - event.relative.y * 0.0025, -1.4, 1.4)
	elif event is InputEventScreenTouch:
		var vs = get_viewport().get_visible_rect().size
		if event.pressed:
			if event.position.distance_to(Vector2(vs.x - 60, 60)) < 55:
				toggle_flash()
			elif event.position.x < vs.x * 0.5 and move_touch == -1:
				move_touch = event.index
				move_origin = event.position
				move_vec = Vector2.ZERO
			elif event.position.x >= vs.x * 0.5 and look_touch == -1:
				look_touch = event.index
		else:
			if event.index == move_touch:
				move_touch = -1
				move_vec = Vector2.ZERO
			if event.index == look_touch:
				look_touch = -1
	elif event is InputEventScreenDrag:
		if event.index == move_touch:
			move_vec = ((event.position - move_origin) / 90.0).limit_length(1.0)
		elif event.index == look_touch:
			yaw -= event.relative.x * 0.005
			pitch = clamp(pitch - event.relative.y * 0.005, -1.4, 1.4)


# ---------------------------------------------------------------- BUCLE

func _process(delta: float) -> void:
	state_time += delta

	flicker_t -= delta
	if flicker_t <= 0.0:
		if rng.randf() < 0.12 + threat * 0.3:
			flick_on = false
			flicker_t = rng.randf_range(0.04, 0.18)
		else:
			flick_on = true
			flicker_t = rng.randf_range(0.2, 2.0)
	var pe: float = cfg["panel_e"]
	var le: float = cfg["light_e"]
	panel_mat.emission_energy_multiplier = pe if flick_on else 0.3
	plight.light_energy = le if flick_on else le * 0.5

	if cfg["clank"]:
		clank_t -= delta
		if clank_t <= 0.0:
			clank_env = 1.0
			clank_pan = rng.randf()
			clank_t = rng.randf_range(4.0, 12.0)

	if msg_t > 0.0:
		msg_t -= delta
		if msg_t <= 0.0 and state == "play":
			msg.text = ""

	if state == "play":
		update_player(delta)
		update_entity(delta)
		update_items(delta)
	elif state == "menu":
		yaw += delta * 0.25
		head.rotation.y = yaw

	danger.color = Color(0.4, 0, 0, clamp(threat, 0.0, 1.0) * 0.4)
	fill_audio()
	hud.queue_redraw()


func hits_wall(p: Vector3) -> bool:
	for ox in [-PR, PR]:
		for oz in [-PR, PR]:
			if tile_wall(int(floor((p.x + ox) / S)), int(floor((p.z + oz) / S))):
				return true
	return false


func update_player(delta: float) -> void:
	var k = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		k.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		k.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		k.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		k.x += 1
	var inp = (k + move_vec).limit_length(1.0)

	var running = Input.is_key_pressed(KEY_SHIFT) or move_vec.length() > 0.95
	var speed = WALK
	if running and stamina > 0.02 and inp.length() > 0.1:
		speed = RUN
		stamina = max(0.0, stamina - delta * 0.25)
	else:
		stamina = min(1.0, stamina + delta * 0.15)

	var forward = Vector3(-sin(yaw), 0, -cos(yaw))
	var right = Vector3(cos(yaw), 0, -sin(yaw))
	var dir = right * inp.x + forward * (-inp.y)
	var step = dir * speed * delta

	var np = pos + Vector3(step.x, 0, 0)
	if not hits_wall(np):
		pos = np
	np = pos + Vector3(0, 0, step.z)
	if not hits_wall(np):
		pos = np

	if inp.length() > 0.1:
		bob += delta * speed * 2.2
		var s_now = sin(bob)
		if (last_sign < 0.0 and s_now >= 0.0) or (last_sign >= 0.0 and s_now < 0.0):
			step_env = 1.0
		last_sign = s_now
	head.position = pos + Vector3(0, 1.65 + sin(bob) * 0.035, 0)
	head.rotation.y = yaw
	cam.rotation.x = pitch

	if flash_on:
		battery -= delta / 100.0
		if battery <= 0.0:
			battery = 0.0
			flash_on = false
			flash.visible = false
			show_msg("Se acabó la batería", 2.0)


func line_clear(a: Vector3, b: Vector3) -> bool:
	var d = a.distance_to(b)
	var steps = int(d / 0.5)
	for i in range(1, steps):
		var p = a.lerp(b, float(i) / steps)
		if tile_wall(int(floor(p.x / S)), int(floor(p.z / S))):
			return false
	return true


func entity_lit() -> bool:
	if not flash_on:
		return false
	var fwd = -cam.global_transform.basis.z
	var to_e = (entity.position + Vector3(0, 1.2, 0)) - cam.global_position
	var d = to_e.length()
	if d > 14.0 or d < 0.1:
		return false
	if fwd.dot(to_e / d) < 0.9:
		return false
	return line_clear(cam.global_position, entity.position + Vector3(0, 1.2, 0))


func update_entity(delta: float) -> void:
	if not entity_active:
		entity_timer += delta
		threat = max(0.0, threat - delta)
		if entity_timer > float(cfg["ent_delay"]):
			spawn_entity()
		return

	entity_path_t -= delta
	var et = Vector2i(int(floor(entity.position.x / S)), int(floor(entity.position.z / S)))
	var pt = Vector2i(int(floor(pos.x / S)), int(floor(pos.z / S)))
	if entity_path_t <= 0.0:
		entity_path_t = 0.3
		entity_next = next_step(et, pt)
	var sp = ent_speed
	if entity_lit():
		sp *= 0.4
	var to = entity_next - entity.position
	to.y = 0
	if to.length() > 0.05:
		entity.position += to.normalized() * sp * delta

	var look = pos - entity.position
	entity.rotation.y = atan2(look.x, look.z)

	var d = Vector2(look.x, look.z).length()
	threat = clamp((14.0 - d) / 14.0, 0.0, 1.0)
	if d < 1.0:
		state = "dead"
		state_time = 0.0
		msg.text = "Te encontró.\n\nToca la pantalla para reintentar"
		msg_t = 9999.0


func next_step(a: Vector2i, b: Vector2i) -> Vector3:
	if a == b:
		return Vector3(pos.x, 0, pos.z)
	var prev = {}
	prev[a] = a
	var q = [a]
	var qi = 0
	var found = false
	while qi < q.size():
		var c: Vector2i = q[qi]
		qi += 1
		if c == b:
			found = true
			break
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if not tile_wall(n.x, n.y) and not prev.has(n):
				prev[n] = c
				q.append(n)
	if not found:
		return entity.position
	var cur: Vector2i = b
	while prev[cur] != a:
		cur = prev[cur]
	return tile_center(cur)


func update_items(delta: float) -> void:
	var t = Time.get_ticks_msec() / 1000.0
	for b in bottles.duplicate():
		b.rotation.y += delta
		b.position.y = 0.9 + sin(t * 2.0 + b.position.x) * 0.05
		if Vector2(b.position.x - pos.x, b.position.z - pos.z).length() < 1.1:
			bottles.erase(b)
			b.queue_free()
			got += 1
			update_label()
			show_msg("Agua de Almendra  (%d/%d)" % [got, bottles_needed], 2.0)

	for p in batteries.duplicate():
		p.rotation.y += delta * 1.5
		p.position.y = 0.6 + sin(t * 2.5 + p.position.z) * 0.04
		if Vector2(p.position.x - pos.x, p.position.z - pos.z).length() < 1.1:
			batteries.erase(p)
			p.queue_free()
			battery = min(1.0, battery + 0.5)
			show_msg("Pilas recogidas", 1.5)

	exit_node.rotation.y = t
	var dx = exit_node.position.x - pos.x
	var dz = exit_node.position.z - pos.z
	if Vector2(dx, dz).length() < 1.4:
		if got >= bottles_needed:
			state = "won"
			state_time = 0.0
			if current_level >= levels_count - 1:
				msg.text = "Escapaste de las Backrooms...\n¿O eso crees?\n\nToca para volver al inicio"
			else:
				msg.text = "Hiciste noclip...\nNIVEL %d\n\nToca para continuar" % (current_level + 1)
			msg_t = 9999.0
		elif msg_t <= 0.0:
			show_msg("La grieta no se estabiliza. Faltan botellas (%d/%d)." % [got, bottles_needed], 2.5)
