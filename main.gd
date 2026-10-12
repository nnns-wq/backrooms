extends Node3D

# BACKROOMS - MUNDO LIBRE v4
# Mundo infinito por chunks + zonas + monstruos con IA + salud/cordura + inventario.
# Todo se genera por codigo. Modelos/texturas propios: ver README.

const CH := 15
const S := 3.0
const CHUNK_M := 45.0
const WALL_H := 2.8
const PR := 0.3
const WALK := 3.0
const RUN := 5.2

static var menu_done: bool = false

var zones: Array = []
var chunks: Dictionary = {}
var taken: Dictionary = {}
var zone_cache: Dictionary = {}
var mat_cache: Dictionary = {}
var world_seed := 0
var rng := RandomNumberGenerator.new()
var env: Environment
var water_mat: StandardMaterial3D
var bottle_mesh: CylinderMesh
var bottle_mat: StandardMaterial3D
var batt_mesh: BoxMesh
var batt_mat: StandardMaterial3D
var flare_mesh: CylinderMesh
var flare_mat: StandardMaterial3D

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
var cur_zone := 0
var cur_le := 1.3
var play_time := 0.0

# supervivencia
var health := 1.0
var sanity := 1.0
var crouch := false
var run_on := false
var sprinting := false
var moving := false
var cam_h := 1.65
var inv_water := 1
var inv_batt := 1
var inv_flare := 1
var sel := 0
var attack_cd := 0.0
var swing_t := 0.0
var noise_extra := 0.0
var damage_flash := 0.0
var flare_t := 0.0
var flare_node: Node3D = null
var flare_light: OmniLight3D = null
var viewmodel: Node3D
var axe_node: Node3D

var flicker_t := 0.0
var flick_on := true

var monsters: Array = []
var entity_seen := false
var threat := 0.0
var ghost: Node3D
var ghost_t := 10.0
var ghost_vis := 0.0

var state := "menu"
var state_time := 0.0
var hud: Control
var msg: Label
var msg_t := 0.0
var danger: ColorRect
var san_rect: ColorRect

var move_touch := -1
var move_origin := Vector2.ZERO
var move_vec := Vector2.ZERO
var look_touch := -1

var playback: AudioStreamGeneratorPlayback
var hum_t := 0.0
var step_env := 0.0
var step_freq := 70.0
var step_amp := 0.2
var clank_env := 0.0
var clank_pan := 0.5
var clank_t := 6.0
var drip_env := 0.0
var drip_pan := 0.5
var drip_t := 1.0
var mstep_env := 0.0
var mstep_pan := 0.5
var growl_env := 0.0


# ---------------------------------------------------------------- ZONAS

func make_zones() -> Array:
	return [
		{
			"name": "El Lobby", "weight": 40,
			"wall": Color(0.80, 0.72, 0.34), "wall_style": 0,
			"floor": Color(0.52, 0.42, 0.20), "floor_style": 2,
			"ceil": Color(0.85, 0.82, 0.68),
			"fog": Color(0.35, 0.30, 0.12), "fog_d": 0.06,
			"amb": Color(0.6, 0.55, 0.3), "amb_e": 0.55,
			"light": Color(1.0, 0.93, 0.65), "light_e": 1.3, "light_r": 13.0,
			"panel": Color(1.0, 0.95, 0.7), "panel_pct": 1.0, "panel_e": 2.0,
			"hum": [120, 60, 240], "clank": false, "drips": false, "water": false,
			"step_freq": 70.0, "step_amp": 0.2,
			"label_col": Color(0.35, 0.2, 0.05),
			"texts": ["NO ESTÁS SOLO", "VUELVE", "¿HOLA?", "EL ZUMBIDO NO PARA", "NO MIRES ATRÁS"]
		},
		{
			"name": "Oficinas", "weight": 22,
			"wall": Color(0.72, 0.70, 0.62), "wall_style": 5,
			"floor": Color(0.30, 0.36, 0.42), "floor_style": 2,
			"ceil": Color(0.80, 0.80, 0.75),
			"fog": Color(0.22, 0.24, 0.22), "fog_d": 0.065,
			"amb": Color(0.5, 0.52, 0.5), "amb_e": 0.5,
			"light": Color(0.9, 1.0, 0.95), "light_e": 1.2, "light_r": 12.0,
			"panel": Color(0.9, 1.0, 0.95), "panel_pct": 0.9, "panel_e": 1.9,
			"hum": [100, 50, 200], "clank": true, "drips": false, "water": false,
			"step_freq": 80.0, "step_amp": 0.2,
			"label_col": Color(0.2, 0.2, 0.25),
			"texts": ["PERSONAL AUTORIZADO", "REUNIÓN 9:00", "NO HAY NADIE", "LLAMA A RECURSOS", "SIGUEN AQUÍ"]
		},
		{
			"name": "Baños", "weight": 15,
			"wall": Color(0.80, 0.88, 0.86), "wall_style": 4,
			"floor": Color(0.70, 0.80, 0.80), "floor_style": 4,
			"ceil": Color(0.85, 0.90, 0.90),
			"fog": Color(0.18, 0.28, 0.28), "fog_d": 0.07,
			"amb": Color(0.45, 0.58, 0.58), "amb_e": 0.5,
			"light": Color(0.8, 1.0, 1.0), "light_e": 1.3, "light_r": 12.0,
			"panel": Color(0.85, 1.0, 1.0), "panel_pct": 0.7, "panel_e": 2.0,
			"hum": [90, 45, 180], "clank": false, "drips": true, "water": false,
			"step_freq": 160.0, "step_amp": 0.35,
			"label_col": Color(0.1, 0.3, 0.35),
			"texts": ["SOLO EMPLEADOS", "LÁVATE LAS MANOS", "NO MIRES AL ESPEJO", "GOTEA", "AGUA"]
		},
		{
			"name": "Piscinas", "weight": 12,
			"wall": Color(0.55, 0.80, 0.85), "wall_style": 4,
			"floor": Color(0.60, 0.85, 0.88), "floor_style": 4,
			"ceil": Color(0.70, 0.85, 0.88),
			"fog": Color(0.15, 0.38, 0.42), "fog_d": 0.05,
			"amb": Color(0.5, 0.75, 0.8), "amb_e": 0.6,
			"light": Color(0.8, 1.0, 1.0), "light_e": 1.2, "light_r": 14.0,
			"panel": Color(0.8, 1.0, 1.0), "panel_pct": 0.8, "panel_e": 2.2,
			"hum": [80, 40, 160], "clank": false, "drips": true, "water": true,
			"step_freq": 55.0, "step_amp": 0.45,
			"label_col": Color(0.05, 0.25, 0.4),
			"texts": ["PROFUNDIDAD 1.2 M", "NO CORRER", "NADA", "SIN SALVAVIDAS", "SILENCIO"]
		},
		{
			"name": "Zona oscura", "weight": 11,
			"wall": Color(0.35, 0.35, 0.33), "wall_style": 1,
			"floor": Color(0.20, 0.20, 0.20), "floor_style": 1,
			"ceil": Color(0.25, 0.25, 0.25),
			"fog": Color(0.04, 0.04, 0.05), "fog_d": 0.10,
			"amb": Color(0.2, 0.2, 0.24), "amb_e": 0.25,
			"light": Color(0.8, 0.9, 1.0), "light_e": 0.9, "light_r": 9.0,
			"panel": Color(0.8, 0.9, 1.0), "panel_pct": 0.12, "panel_e": 1.4,
			"hum": [45, 90, 135], "clank": true, "drips": false, "water": false,
			"step_freq": 60.0, "step_amp": 0.25,
			"label_col": Color(0.7, 0.1, 0.1),
			"texts": ["APAGADO", "NO ENCIENDAS LUZ", "CERCA", "ESCUCHA", "OSCURO"]
		}
	]


func zone_of(cx: int, cz: int) -> int:
	if cx == 0 and cz == 0:
		return 0
	var h = absi((cx * 73856093) ^ (cz * 19349663) ^ world_seed ^ 12345) % 100
	var acc = 0
	for i in zones.size():
		acc += int(zones[i]["weight"])
		if h < acc:
			return i
	return 0


func edge_has(ex: int, ez: int, axis: int, k: int) -> bool:
	if k == 7:
		return true
	var h = absi((ex * 73856093) ^ (ez * 19349663) ^ (axis * 83492791) ^ (k * 2654435761) ^ world_seed) % 100
	return h < 50


# ---------------------------------------------------------------- INICIO

func _ready() -> void:
	rng.randomize()
	world_seed = rng.randi() & 0x7fffffff
	zones = make_zones()
	build_env()
	build_item_assets()
	build_player()
	build_viewmodel()
	update_chunks(true)
	monsters.append(make_monster("stalker"))
	monsters.append(make_monster("hound"))
	var gm = make_stalker_model()
	ghost = gm["root"]
	ghost.visible = false
	add_child(ghost)
	build_hud()
	build_audio()
	clank_t = rng.randf_range(3.0, 8.0)

	if menu_done:
		state = "play"
		show_msg(intro_text(), 7.0)
	else:
		state = "menu"
		show_msg("BACKROOMS\nMundo libre\n\nToca la pantalla para empezar", 9999.0)


func intro_text() -> String:
	return "Mundo libre. Sobrevive y explora.\nEscucha: correr hace ruido, agacharte te oculta.\nNo mires fijamente al Smiler."


func start_game() -> void:
	menu_done = true
	state = "play"
	state_time = 0.0
	show_msg(intro_text(), 7.0)


func build_env() -> void:
	var z: Dictionary = zones[0]
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.1, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = z["amb"]
	env.ambient_light_energy = z["amb_e"]
	env.fog_enabled = true
	env.fog_light_color = z["fog"]
	env.fog_density = z["fog_d"]
	var we = WorldEnvironment.new()
	we.environment = env
	add_child(we)

	water_mat = StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.3, 0.7, 0.8, 0.45)
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_mat.roughness = 0.1
	water_mat.emission_enabled = true
	water_mat.emission = Color(0.05, 0.2, 0.25)


func build_item_assets() -> void:
	bottle_mesh = CylinderMesh.new()
	bottle_mesh.top_radius = 0.05
	bottle_mesh.bottom_radius = 0.07
	bottle_mesh.height = 0.3
	bottle_mat = StandardMaterial3D.new()
	bottle_mat.albedo_color = Color(0.9, 1, 0.95)
	bottle_mat.emission_enabled = true
	bottle_mat.emission = Color(0.7, 1.0, 0.85)
	bottle_mat.emission_energy_multiplier = 1.5
	batt_mesh = BoxMesh.new()
	batt_mesh.size = Vector3(0.12, 0.22, 0.12)
	batt_mat = StandardMaterial3D.new()
	batt_mat.albedo_color = Color(1, 0.8, 0.2)
	batt_mat.emission_enabled = true
	batt_mat.emission = Color(1.0, 0.7, 0.1)
	batt_mat.emission_energy_multiplier = 1.5
	flare_mesh = CylinderMesh.new()
	flare_mesh.top_radius = 0.04
	flare_mesh.bottom_radius = 0.04
	flare_mesh.height = 0.28
	flare_mat = StandardMaterial3D.new()
	flare_mat.albedo_color = Color(1, 0.2, 0.1)
	flare_mat.emission_enabled = true
	flare_mat.emission = Color(1.0, 0.15, 0.05)
	flare_mat.emission_energy_multiplier = 2.0


func build_player() -> void:
	var z: Dictionary = zones[0]
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
	plight.omni_range = z["light_r"]
	plight.light_energy = z["light_e"]
	plight.light_color = z["light"]
	head.add_child(plight)
	flash = SpotLight3D.new()
	flash.spot_range = 20.0
	flash.spot_angle = 30.0
	flash.light_energy = 3.0
	flash.visible = false
	cam.add_child(flash)
	head.position = pos + Vector3(0, 1.65, 0)


func build_viewmodel() -> void:
	viewmodel = Node3D.new()
	viewmodel.position = Vector3(0.0, 0.0, 0.0)
	cam.add_child(viewmodel)
	var skin = Color(0.78, 0.6, 0.5)
	# manos
	add_box(viewmodel, Vector3(0.09, 0.09, 0.2), Vector3(-0.3, -0.35, -0.55), skin)
	add_box(viewmodel, Vector3(0.09, 0.09, 0.2), Vector3(0.3, -0.38, -0.5), skin)
	# hacha (pivote en la mano derecha)
	axe_node = Node3D.new()
	axe_node.position = Vector3(0.3, -0.38, -0.5)
	viewmodel.add_child(axe_node)
	add_box(axe_node, Vector3(0.05, 0.55, 0.05), Vector3(0.0, 0.25, 0.0), Color(0.4, 0.27, 0.15))
	add_box(axe_node, Vector3(0.05, 0.16, 0.2), Vector3(0.0, 0.52, -0.08), Color(0.35, 0.35, 0.38))
	add_box(axe_node, Vector3(0.05, 0.06, 0.07), Vector3(0.0, 0.52, 0.05), Color(0.3, 0.3, 0.33))


# ---------------------------------------------------------------- TEXTURAS

func make_surface_img(c: Color, style: int, size: int) -> Image:
	var img = Image.create(size, size, false, Image.FORMAT_RGB8)
	var nz = FastNoiseLite.new()
	nz.seed = rng.randi()
	nz.frequency = 0.04
	var stripe = maxi(1, size / 64)
	var cell = maxi(2, size / 8)
	for y in size:
		for x in size:
			var base = c
			var n = rng.randf_range(-0.04, 0.04)
			if style == 0:
				if (x % cell) < stripe:
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
			elif style == 4:
				if (x % cell) == 0 or (y % cell) == 0:
					base = base.darkened(0.3)
				n = rng.randf_range(-0.02, 0.02)
			elif style == 5:
				n = rng.randf_range(-0.025, 0.025)
				if y > size - size / 12:
					base = base.darkened(0.25)
			img.set_pixel(x, y, Color(base.r + n, base.g + n, base.b + n * 0.7))
	if style == 2:
		for i in 18:
			var cx = rng.randi_range(0, size - 1)
			var cy = rng.randi_range(0, size - 1)
			for dy in range(-4, 5):
				for dx in range(-4, 5):
					if dx * dx + dy * dy < 17:
						var px = (cx + dx + size) % size
						var py = (cy + dy + size) % size
						img.set_pixel(px, py, img.get_pixel(px, py).darkened(0.25))
	return img


func zone_tex(path: String, c: Color, style: int, size: int) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return ImageTexture.create_from_image(make_surface_img(c, style, size))


func make_mat(tex: Texture2D, scale: float) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_texture = tex
	m.roughness = 1.0
	m.uv1_scale = Vector3(scale, scale, 1.0)
	return m


func get_zone_mats(zi: int) -> Dictionary:
	if zone_cache.has(zi):
		return zone_cache[zi]
	var z: Dictionary = zones[zi]
	var d = {}
	d["wall"] = make_mat(zone_tex("res://textures/zone%d_wall.png" % zi, z["wall"], z["wall_style"], 96), 1.0)
	d["floor"] = make_mat(zone_tex("res://textures/zone%d_floor.png" % zi, z["floor"], z["floor_style"], 96), CH * 1.5)
	d["ceil"] = make_mat(zone_tex("res://textures/zone%d_ceiling.png" % zi, z["ceil"], 3, 48), CHUNK_M / 1.2)
	var pm = StandardMaterial3D.new()
	pm.albedo_color = Color(1, 1, 0.9)
	pm.emission_enabled = true
	pm.emission = z["panel"]
	pm.emission_energy_multiplier = z["panel_e"]
	d["panel"] = pm
	zone_cache[zi] = d
	return d


func solid_mat(c: Color) -> StandardMaterial3D:
	var k = c.to_html()
	if mat_cache.has(k):
		return mat_cache[k]
	var m = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	mat_cache[k] = m
	return m


func glow_mat(c: Color, e: float) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = e
	return m


func add_box(parent: Node3D, size: Vector3, p: Vector3, c: Color) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = solid_mat(c)
	mi.position = p
	parent.add_child(mi)
	return mi


# ---------------------------------------------------------------- CHUNKS

func pchunk() -> Vector2i:
	return Vector2i(floori(pos.x / CHUNK_M), floori(pos.z / CHUNK_M))


func tile_wall(gx: int, gz: int) -> bool:
	var cx = floori(float(gx) / CH)
	var cz = floori(float(gz) / CH)
	var key = Vector2i(cx, cz)
	if not chunks.has(key):
		return true
	var ch: Dictionary = chunks[key]
	var lx = gx - cx * CH
	var lz = gz - cz * CH
	return ch["map"][lz][lx] or ch["pb"][lz][lx]


func tile_center(t: Vector2i) -> Vector3:
	return Vector3((t.x + 0.5) * S, 0, (t.y + 0.5) * S)


func update_chunks(force: bool) -> void:
	var pc = pchunk()
	for key in chunks.keys():
		if absi(key.x - pc.x) > 2 or absi(key.y - pc.y) > 2:
			chunks[key]["node"].queue_free()
			chunks.erase(key)
	var missing = []
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var k = Vector2i(pc.x + dx, pc.y + dz)
			if not chunks.has(k):
				missing.append(k)
	if force:
		for k2 in missing:
			build_chunk(k2.x, k2.y)
	elif missing.size() > 0:
		missing.sort_custom(func(a, b): return Vector2(a - pc).length() < Vector2(b - pc).length())
		build_chunk(missing[0].x, missing[0].y)


func build_chunk(cx: int, cz: int) -> void:
	var key = Vector2i(cx, cz)
	if chunks.has(key):
		return
	var zi = zone_of(cx, cz)
	var z: Dictionary = zones[zi]
	var crng = RandomNumberGenerator.new()
	crng.seed = ((cx * 73856093) ^ (cz * 19349663) ^ world_seed ^ 777) & 0x7fffffff

	var lm: Array = []
	var pb: Array = []
	for lz in CH:
		var r1 = []
		var r2 = []
		for lx in CH:
			r1.append(true)
			r2.append(false)
		lm.append(r1)
		pb.append(r2)

	var stack = [Vector2i(1, 1)]
	lm[1][1] = false
	var dirs = [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]
	while stack.size() > 0:
		var c: Vector2i = stack.back()
		var opts = []
		for d in dirs:
			var n: Vector2i = c + d
			if n.x > 0 and n.y > 0 and n.x < CH - 1 and n.y < CH - 1 and lm[n.y][n.x]:
				opts.append(d)
		if opts.is_empty():
			stack.pop_back()
		else:
			var d2: Vector2i = opts[crng.randi() % opts.size()]
			lm[c.y + d2.y / 2][c.x + d2.x / 2] = false
			var nn: Vector2i = c + d2
			lm[nn.y][nn.x] = false
			stack.append(nn)

	for i in 20:
		var x = crng.randi_range(2, CH - 3)
		var zz = crng.randi_range(2, CH - 3)
		if lm[zz][x]:
			var h = (not lm[zz][x - 1]) and (not lm[zz][x + 1])
			var v = (not lm[zz - 1][x]) and (not lm[zz + 1][x])
			if h or v:
				lm[zz][x] = false

	var rooms: Array = []
	var carved: Dictionary = {}
	var nr = 3
	var wmin = 3
	var wmax = 5
	var hmin = 3
	var hmax = 5
	if zi == 1:
		nr = 2
		wmin = 5
		wmax = 6
		hmin = 5
		hmax = 5
	elif zi == 2:
		nr = 2
		wmin = 5
		wmax = 7
		hmin = 4
		hmax = 4
	elif zi == 3:
		nr = 2
		wmin = 5
		wmax = 7
		hmin = 5
		hmax = 7
	elif zi == 4:
		nr = 2
		wmin = 5
		wmax = 5
		hmin = 5
		hmax = 5
	for i in nr:
		var w = crng.randi_range(wmin, wmax)
		var h2 = crng.randi_range(hmin, hmax)
		var x0 = crng.randi_range(2, CH - 2 - w)
		var z0 = crng.randi_range(2, CH - 2 - h2)
		rooms.append(Rect2i(x0, z0, w, h2))
		for zz2 in range(z0, z0 + h2):
			for xx in range(x0, x0 + w):
				if lm[zz2][xx]:
					carved[Vector2i(xx, zz2)] = true
				lm[zz2][xx] = false

	var props: Array = []
	for r in rooms:
		var x0: int = r.position.x
		var z0: int = r.position.y
		var w: int = r.size.x
		var h2: int = r.size.y
		if zi == 0:
			if w % 2 == 1 and h2 % 2 == 1:
				lm[z0 + h2 / 2][x0 + w / 2] = true
		elif zi == 3:
			if w >= 5 and h2 >= 5:
				lm[z0 + 1][x0 + 1] = true
				lm[z0 + 1][x0 + w - 2] = true
				lm[z0 + h2 - 2][x0 + 1] = true
				lm[z0 + h2 - 2][x0 + w - 2] = true
		elif zi == 4:
			if w == 5 and h2 == 5:
				lm[z0 + 1][x0 + 1] = true
				lm[z0 + 1][x0 + 3] = true
				lm[z0 + 3][x0 + 1] = true
				lm[z0 + 3][x0 + 3] = true
		elif zi == 1:
			for zz3 in [z0 + 1, z0 + 3]:
				for xx3 in range(x0 + 1, x0 + w - 1, 2):
					var t = Vector2i(xx3, zz3)
					if carved.has(t) and not lm[zz3][xx3] and not pb[zz3][xx3]:
						pb[zz3][xx3] = true
						props.append({"type": "desk", "t": t, "rot": PI * float(crng.randi() % 2), "mirror": false})
		elif zi == 2:
			for xx4 in range(x0 + 1, x0 + w - 1, 2):
				var t1 = Vector2i(xx4, z0)
				if carved.has(t1) and not lm[z0][xx4] and not pb[z0][xx4]:
					pb[z0][xx4] = true
					props.append({"type": "stall", "t": t1, "rot": 0.0, "mirror": false})
				var zb = z0 + h2 - 1
				var t2 = Vector2i(xx4, zb)
				if carved.has(t2) and not lm[zb][xx4] and not pb[zb][xx4]:
					pb[zb][xx4] = true
					var wall_behind = (zb + 1 < CH) and lm[zb + 1][xx4]
					props.append({"type": "sink", "t": t2, "rot": 0.0, "mirror": wall_behind})

	for k in range(1, CH - 1, 2):
		if edge_has(cx - 1, cz, 0, k):
			lm[k][0] = false
		if edge_has(cx, cz, 0, k):
			lm[k][CH - 1] = false
		if edge_has(cx, cz - 1, 1, k):
			lm[0][k] = false
		if edge_has(cx, cz, 1, k):
			lm[CH - 1][k] = false

	var mats = get_zone_mats(zi)
	var root = Node3D.new()
	root.position = Vector3(cx * CHUNK_M, 0, cz * CHUNK_M)
	add_child(root)

	var wall_tiles = []
	for lz in CH:
		for lx in CH:
			if lm[lz][lx]:
				var near_open = false
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var nx = lx + d.x
					var nz = lz + d.y
					if nx >= 0 and nz >= 0 and nx < CH and nz < CH and not lm[nz][nx]:
						near_open = true
				if near_open:
					wall_tiles.append(Vector2i(lx, lz))
	var box = BoxMesh.new()
	box.size = Vector3(S, WALL_H, S)
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = box
	mm.instance_count = wall_tiles.size()
	for i in wall_tiles.size():
		var t3: Vector2i = wall_tiles[i]
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3((t3.x + 0.5) * S, WALL_H / 2.0, (t3.y + 0.5) * S)))
	var walls = MultiMeshInstance3D.new()
	walls.multimesh = mm
	walls.material_override = mats["wall"]
	root.add_child(walls)

	var plane = PlaneMesh.new()
	plane.size = Vector2(CHUNK_M, CHUNK_M)
	var fl = MeshInstance3D.new()
	fl.mesh = plane
	fl.material_override = mats["floor"]
	fl.position = Vector3(CHUNK_M / 2.0, 0, CHUNK_M / 2.0)
	root.add_child(fl)
	var ce = MeshInstance3D.new()
	ce.mesh = plane
	ce.material_override = mats["ceil"]
	ce.position = Vector3(CHUNK_M / 2.0, WALL_H, CHUNK_M / 2.0)
	ce.rotation_degrees = Vector3(180, 0, 0)
	root.add_child(ce)

	if z["water"]:
		var wp = MeshInstance3D.new()
		wp.mesh = plane
		wp.material_override = water_mat
		wp.position = Vector3(CHUNK_M / 2.0, 0.3, CHUNK_M / 2.0)
		root.add_child(wp)

	var panel_tiles = []
	var pct: float = z["panel_pct"]
	for lz in CH:
		for lx in CH:
			if not lm[lz][lx] and not pb[lz][lx] and (lx + lz) % 2 == 0:
				if crng.randf() < pct:
					panel_tiles.append(Vector2i(lx, lz))
	var pbox = BoxMesh.new()
	pbox.size = Vector3(1.3, 0.06, 0.5)
	var pmm = MultiMesh.new()
	pmm.transform_format = MultiMesh.TRANSFORM_3D
	pmm.mesh = pbox
	pmm.instance_count = panel_tiles.size()
	for i in panel_tiles.size():
		var t4: Vector2i = panel_tiles[i]
		pmm.set_instance_transform(i, Transform3D(Basis(), Vector3((t4.x + 0.5) * S, WALL_H - 0.03, (t4.y + 0.5) * S)))
	var panels = MultiMeshInstance3D.new()
	panels.multimesh = pmm
	panels.material_override = mats["panel"]
	root.add_child(panels)

	for p in props:
		add_prop(root, p)

	var texts: Array = z["texts"]
	var placed = 0
	var tries = 0
	while placed < 2 and tries < 40:
		tries += 1
		var lx2 = crng.randi_range(1, CH - 2)
		var lz2 = crng.randi_range(1, CH - 2)
		if lm[lz2][lx2] or pb[lz2][lx2]:
			continue
		var dd: Vector2i = dirs[crng.randi() % 4] / 2
		var nx2 = lx2 + dd.x
		var nz2 = lz2 + dd.y
		if nx2 < 0 or nz2 < 0 or nx2 >= CH or nz2 >= CH:
			continue
		if not lm[nz2][nx2]:
			continue
		var lb = Label3D.new()
		lb.text = texts[crng.randi() % texts.size()]
		lb.font_size = 96
		lb.pixel_size = 0.004
		lb.modulate = z["label_col"]
		lb.double_sided = false
		lb.position = Vector3((lx2 + 0.5) * S + dd.x * (S / 2.0 - 0.03), 1.3, (lz2 + 0.5) * S + dd.y * (S / 2.0 - 0.03))
		lb.rotation.y = atan2(-dd.x, -dd.y)
		root.add_child(lb)
		placed += 1

	# objetos (agua, pilas, bengalas)
	var items: Array = []
	var open_tiles = []
	for lz in range(1, CH - 1):
		for lx in range(1, CH - 1):
			if not lm[lz][lx] and not pb[lz][lx]:
				open_tiles.append(Vector2i(lx, lz))
	var item_chances = [0.5, 0.4, 0.25]
	for i in 3:
		var roll = crng.randf()
		var ti = crng.randi() % open_tiles.size()
		var id = Vector3i(cx, cz, i)
		if roll < float(item_chances[i]) and not taken.has(id):
			var tt: Vector2i = open_tiles[ti]
			var node = MeshInstance3D.new()
			var iy = 0.9
			if i == 0:
				node.mesh = bottle_mesh
				node.material_override = bottle_mat
				iy = 0.9
			elif i == 1:
				node.mesh = batt_mesh
				node.material_override = batt_mat
				iy = 0.6
			else:
				node.mesh = flare_mesh
				node.material_override = flare_mat
				iy = 0.5
			node.position = Vector3((tt.x + 0.5) * S, iy, (tt.y + 0.5) * S)
			root.add_child(node)
			items.append({"node": node, "id": id, "kind": i, "y": iy})

	# Smiler (aparece mas en la zona oscura)
	var smilers: Array = []
	var sch = 0.5 if zi == 4 else 0.12
	var sroll = crng.randf()
	var sti = crng.randi() % open_tiles.size()
	if sroll < sch and not (cx == 0 and cz == 0):
		var st: Vector2i = open_tiles[sti]
		var sn = make_smiler()
		sn.position = Vector3((st.x + 0.5) * S, 1.75, (st.y + 0.5) * S)
		root.add_child(sn)
		smilers.append({"node": sn})

	chunks[key] = {"node": root, "map": lm, "pb": pb, "zone": zi, "items": items, "smilers": smilers}


func add_prop(root: Node3D, p: Dictionary) -> void:
	var t: Vector2i = p["t"]
	var kind: String = p["type"]
	var grp = Node3D.new()
	grp.position = Vector3((t.x + 0.5) * S, 0, (t.y + 0.5) * S)
	grp.rotation.y = p["rot"]
	root.add_child(grp)
	if kind == "desk":
		add_box(grp, Vector3(2.3, 0.75, 1.0), Vector3(0, 0.375, 0), Color(0.45, 0.33, 0.22))
		add_box(grp, Vector3(0.5, 0.35, 0.05), Vector3(0, 0.95, -0.2), Color(0.04, 0.04, 0.05))
		add_box(grp, Vector3(0.12, 0.2, 0.1), Vector3(0, 0.85, -0.2), Color(0.1, 0.1, 0.1))
		add_box(grp, Vector3(0.5, 0.06, 0.5), Vector3(0, 0.5, 0.85), Color(0.15, 0.2, 0.3))
		add_box(grp, Vector3(0.5, 0.5, 0.06), Vector3(0, 0.8, 1.1), Color(0.15, 0.2, 0.3))
		add_box(grp, Vector3(0.06, 0.45, 0.06), Vector3(0, 0.25, 0.85), Color(0.2, 0.2, 0.2))
	elif kind == "stall":
		add_box(grp, Vector3(2.6, 1.9, 2.6), Vector3(0, 1.15, 0), Color(0.32, 0.55, 0.55))
		add_box(grp, Vector3(1.0, 1.7, 0.04), Vector3(0, 1.05, 1.31), Color(0.22, 0.4, 0.42))
	elif kind == "sink":
		add_box(grp, Vector3(2.6, 0.9, 0.7), Vector3(0, 0.45, 1.1), Color(0.88, 0.9, 0.9))
		add_box(grp, Vector3(0.6, 0.04, 0.4), Vector3(-0.6, 0.92, 1.1), Color(0.25, 0.35, 0.38))
		add_box(grp, Vector3(0.6, 0.04, 0.4), Vector3(0.6, 0.92, 1.1), Color(0.25, 0.35, 0.38))
		add_box(grp, Vector3(0.05, 0.2, 0.05), Vector3(-0.6, 1.05, 1.35), Color(0.7, 0.7, 0.75))
		add_box(grp, Vector3(0.05, 0.2, 0.05), Vector3(0.6, 1.05, 1.35), Color(0.7, 0.7, 0.75))
		if p["mirror"]:
			add_box(grp, Vector3(2.4, 1.0, 0.03), Vector3(0, 1.7, 1.46), Color(0.75, 0.85, 0.9))


# ---------------------------------------------------------------- MODELOS DE MONSTRUOS

func limb(parent: Node3D, p: Vector3, length: float, radius: float, mat: StandardMaterial3D) -> Node3D:
	var pivot = Node3D.new()
	pivot.position = p
	parent.add_child(pivot)
	var mi = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius * 0.8
	cm.height = length
	mi.mesh = cm
	mi.material_override = mat
	mi.position = Vector3(0, -length / 2.0, 0)
	pivot.add_child(mi)
	return pivot


func make_stalker_model() -> Dictionary:
	var root = Node3D.new()
	var black = StandardMaterial3D.new()
	black.albedo_color = Color(0.03, 0.03, 0.035)
	black.roughness = 1.0
	var torso = MeshInstance3D.new()
	var cm = CapsuleMesh.new()
	cm.radius = 0.17
	cm.height = 0.95
	torso.mesh = cm
	torso.material_override = black
	torso.position = Vector3(0, 1.5, 0)
	root.add_child(torso)
	var hd = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 0.13
	sm.height = 0.26
	hd.mesh = sm
	hd.material_override = black
	hd.position = Vector3(0, 2.17, 0.02)
	hd.scale = Vector3(1.0, 1.5, 1.0)
	root.add_child(hd)
	var la = limb(root, Vector3(-0.24, 1.9, 0), 1.5, 0.04, black)
	var ra = limb(root, Vector3(0.24, 1.9, 0), 1.5, 0.04, black)
	var ll = limb(root, Vector3(-0.1, 1.05, 0), 1.05, 0.06, black)
	var rl = limb(root, Vector3(0.1, 1.05, 0), 1.05, 0.06, black)
	var eye_mat = glow_mat(Color(1, 0.05, 0.05), 4.0)
	for sx in [-1.0, 1.0]:
		var eye = MeshInstance3D.new()
		var em = SphereMesh.new()
		em.radius = 0.03
		em.height = 0.06
		eye.mesh = em
		eye.material_override = eye_mat
		eye.position = Vector3(sx * 0.06, 2.22, 0.1)
		root.add_child(eye)
	return {"root": root, "a": [la, rl], "b": [ra, ll]}


func make_hound_model() -> Dictionary:
	var root = Node3D.new()
	var bone = StandardMaterial3D.new()
	bone.albedo_color = Color(0.62, 0.58, 0.52)
	bone.roughness = 1.0
	var skin = StandardMaterial3D.new()
	skin.albedo_color = Color(0.82, 0.68, 0.58)
	skin.roughness = 1.0
	var body = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.5, 0.4, 1.1)
	body.mesh = bm
	body.material_override = bone
	body.position = Vector3(0, 0.75, 0)
	root.add_child(body)
	var hd = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 0.2
	sm.height = 0.4
	hd.mesh = sm
	hd.material_override = skin
	hd.position = Vector3(0, 0.95, 0.7)
	root.add_child(hd)
	var dark = glow_mat(Color(0.02, 0.02, 0.02), 0.0)
	for sx in [-1.0, 1.0]:
		var eye = MeshInstance3D.new()
		var em = SphereMesh.new()
		em.radius = 0.03
		em.height = 0.06
		eye.mesh = em
		eye.material_override = dark
		eye.position = Vector3(sx * 0.07, 1.0, 0.88)
		root.add_child(eye)
	add_box(root, Vector3(0.18, 0.05, 0.16), Vector3(0, 0.82, 0.86), Color(0.25, 0.05, 0.05))
	var fl = limb(root, Vector3(-0.18, 0.6, 0.4), 0.6, 0.05, bone)
	var fr = limb(root, Vector3(0.18, 0.6, 0.4), 0.6, 0.05, bone)
	var bl = limb(root, Vector3(-0.18, 0.6, -0.4), 0.6, 0.05, bone)
	var br = limb(root, Vector3(0.18, 0.6, -0.4), 0.6, 0.05, bone)
	return {"root": root, "a": [fl, br], "b": [fr, bl]}


func make_smiler() -> Node3D:
	var root = Node3D.new()
	var m = glow_mat(Color(1, 1, 0.9), 3.0)
	for sx in [-1.0, 1.0]:
		var eye = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(0.1, 0.2, 0.04)
		eye.mesh = bm
		eye.material_override = m
		eye.position = Vector3(sx * 0.28, 0.25, 0)
		root.add_child(eye)
	for i in range(-4, 5):
		var tooth = MeshInstance3D.new()
		var tm = BoxMesh.new()
		tm.size = Vector3(0.07, 0.07, 0.04)
		tooth.mesh = tm
		tooth.material_override = m
		var fx = float(i) * 0.1
		tooth.position = Vector3(fx, -0.08 - 0.14 * (1.0 - (fx / 0.4) * (fx / 0.4)), 0)
		root.add_child(tooth)
	return root


func make_monster(kind: String) -> Dictionary:
	var model: Dictionary
	if kind == "stalker":
		if ResourceLoader.exists("res://models/entity.glb"):
			var holder = Node3D.new()
			var scn = load("res://models/entity.glb")
			holder.add_child(scn.instantiate())
			model = {"root": holder, "a": [], "b": []}
		else:
			model = make_stalker_model()
	else:
		model = make_hound_model()
	var node: Node3D = model["root"]
	node.visible = false
	add_child(node)
	var m = {
		"kind": kind, "node": node, "a": model["a"], "b": model["b"],
		"active": false, "timer": 0.0,
		"delay": 25.0 if kind == "stalker" else 90.0,
		"hp": 3 if kind == "stalker" else 2,
		"maxhp": 3 if kind == "stalker" else 2,
		"speed": 3.4 if kind == "stalker" else 5.2,
		"dmg": 0.25 if kind == "stalker" else 0.2,
		"hearing": 1.0 if kind == "stalker" else 1.6,
		"sight": 20.0 if kind == "stalker" else 9.0,
		"stun": 0.0, "state": "patrol", "target": Vector3.ZERO,
		"lose_t": 0.0, "cd": 0.0, "path_t": 0.0, "next": Vector3.ZERO,
		"phase": 0.0, "last_sign": 1.0
	}
	return m


# ---------------------------------------------------------------- HUD

func build_hud() -> void:
	var cl = CanvasLayer.new()
	add_child(cl)

	san_rect = ColorRect.new()
	san_rect.color = Color(0.1, 0.0, 0.15, 0.0)
	san_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(san_rect)
	san_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

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

	msg = Label.new()
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.add_theme_font_size_override("font_size", 28)
	msg.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	msg.add_theme_constant_override("outline_size", 8)
	msg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(msg)
	msg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	msg.offset_left = 60
	msg.offset_right = -60


func button_defs(vs: Vector2) -> Array:
	return [
		{"id": "run", "p": Vector2(vs.x - 70, vs.y - 270), "r": 38.0, "t": "CORRER"},
		{"id": "luz", "p": Vector2(vs.x - 180, vs.y - 200), "r": 38.0, "t": "LUZ"},
		{"id": "use", "p": Vector2(vs.x - 90, vs.y - 130), "r": 55.0, "t": "USAR"},
		{"id": "crouch", "p": Vector2(vs.x - 210, vs.y - 90), "r": 38.0, "t": "AGACHAR"}
	]


func slot_rect(i: int, vs: Vector2) -> Rect2:
	return Rect2(vs.x / 2.0 - 172.0 + float(i) * 86.0, vs.y - 92.0, 80.0, 80.0)


func txt(s: String, p: Vector2, size: int, col: Color, align: int = 0, width: float = -1.0) -> void:
	var f = ThemeDB.fallback_font
	hud.draw_string(f, p + Vector2(1, 1), s, align, width, size, Color(0, 0, 0, 0.8))
	hud.draw_string(f, p, s, align, width, size, col)


func bar(x: float, y: float, w: float, h: float, frac: float, col: Color) -> void:
	hud.draw_rect(Rect2(x, y, w, h), Color(0, 0, 0, 0.5))
	hud.draw_rect(Rect2(x, y, w * clampf(frac, 0.0, 1.0), h), col)
	hud.draw_rect(Rect2(x, y, w, h), Color(1, 1, 1, 0.35), false, 1.0)


func _draw_hud() -> void:
	var vs = get_viewport().get_visible_rect().size
	if move_touch != -1:
		hud.draw_circle(move_origin, 70, Color(1, 1, 1, 0.12))
		hud.draw_circle(move_origin + move_vec * 70.0, 32, Color(1, 1, 1, 0.3))

	# cordura y salud (arriba izquierda)
	txt("CORDURA", Vector2(24, 30), 16, Color(1, 1, 1, 0.9))
	bar(24, 36, 220, 10, sanity, Color(0.35, 0.55, 0.95))
	txt("SALUD", Vector2(24, 72), 16, Color(1, 1, 1, 0.9))
	bar(24, 78, 220, 10, health, Color(0.85, 0.25, 0.25))
	# bateria, tiempo y zona (arriba derecha)
	txt("BATERÍA", Vector2(vs.x - 244, 30), 16, Color(1, 1, 1, 0.9), 2, 220.0)
	bar(vs.x - 244, 36, 220, 10, battery, Color(0.45, 0.85, 0.4))
	txt(format_time(play_time), Vector2(vs.x - 244, 72), 20, Color(1, 1, 1, 0.9), 2, 220.0)
	txt(str(zones[cur_zone]["name"]), Vector2(vs.x - 244, 96), 16, Color(1, 1, 1, 0.7), 2, 220.0)
	# stamina
	bar(24, vs.y - 28, 200, 8, stamina, Color(1, 1, 1, 0.6))

	# inventario
	var names = ["HACHA", "AGUA", "PILA", "BENGALA"]
	var counts = [-1, inv_water, inv_batt, inv_flare]
	for i in 4:
		var r = slot_rect(i, vs)
		hud.draw_rect(r, Color(0, 0, 0, 0.5))
		var oc = Color(1, 1, 1, 0.9) if i == sel else Color(1, 1, 1, 0.3)
		hud.draw_rect(r, oc, false, 3.0 if i == sel else 1.0)
		txt(str(names[i]), Vector2(r.position.x, r.position.y + 38), 15, Color(1, 1, 1, 0.9), 1, r.size.x)
		if int(counts[i]) >= 0:
			txt("x%d" % int(counts[i]), Vector2(r.position.x, r.position.y + 58), 15, Color(1, 0.9, 0.5, 0.95), 1, r.size.x)
		txt(str(i + 1), Vector2(r.position.x + 6, r.position.y + 16), 13, Color(1, 1, 1, 0.6))

	# botones
	for b in button_defs(vs):
		var on = false
		if b["id"] == "run":
			on = run_on
		elif b["id"] == "luz":
			on = flash_on
		elif b["id"] == "crouch":
			on = crouch
		var a = 0.35 if on else 0.15
		hud.draw_circle(b["p"], b["r"], Color(1, 1, 1, a))
		hud.draw_arc(b["p"], b["r"], 0.0, TAU, 32, Color(1, 1, 1, 0.5), 2.0)
		txt(str(b["t"]), Vector2(b["p"].x - b["r"], b["p"].y + 6), 15, Color(1, 1, 1, 0.9), 1, b["r"] * 2.0)


func format_time(t: float) -> String:
	var s = int(t)
	return "%02d:%02d" % [s / 60, s % 60]


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
	var f: Array = zones[cur_zone]["hum"]
	var n = playback.get_frames_available()
	var whisper = clampf((0.4 - sanity) / 0.4, 0.0, 1.0)
	var heart = 0.0
	if threat > 0.4:
		heart = threat
	elif sanity < 0.35:
		heart = (0.35 - sanity) / 0.35 * 0.7
	for i in n:
		hum_t = fposmod(hum_t + 1.0 / 22050.0, 1.0)
		var s = sin(hum_t * TAU * f[0]) * 0.05 + sin(hum_t * TAU * f[1]) * 0.05 + sin(hum_t * TAU * f[2]) * 0.015
		s += (rng.randf() - 0.5) * 0.01
		s += sin(hum_t * TAU * 38.0) * 0.14 * threat
		if step_env > 0.001:
			s += ((rng.randf() - 0.5) * 0.5 + sin(hum_t * TAU * step_freq) * 0.4) * step_env * step_amp
			step_env *= 0.9989
		if whisper > 0.0:
			var wv = maxf(0.0, sin(hum_t * TAU * 3.0))
			s += (rng.randf() - 0.5) * 0.05 * whisper * wv * wv
		if heart > 0.0:
			s += sin(hum_t * TAU * 50.0) * pow(maxf(0.0, sin(hum_t * TAU * 2.0)), 10.0) * 0.2 * heart
		if growl_env > 0.001:
			s += (sin(hum_t * TAU * 85.0) + sin(hum_t * TAU * 127.0) * 0.6 + (rng.randf() - 0.5) * 0.5) * growl_env * 0.1
			growl_env *= 0.9999
		var cl = 0.0
		if clank_env > 0.001:
			cl = ((rng.randf() - 0.5) * 0.4 + sin(hum_t * TAU * 210.0) * 0.6) * clank_env * 0.18
			clank_env *= 0.9997
		var dr = 0.0
		if drip_env > 0.001:
			dr = sin(hum_t * TAU * 1500.0) * drip_env * 0.07
			drip_env *= 0.9985
		var ms = 0.0
		if mstep_env > 0.001:
			ms = ((rng.randf() - 0.5) * 0.4 + sin(hum_t * TAU * 45.0) * 0.6) * mstep_env * 0.35
			mstep_env *= 0.9988
		var l = s + cl * (1.0 - clank_pan) + dr * (1.0 - drip_pan) + ms * (1.0 - mstep_pan)
		var r = s + cl * clank_pan + dr * drip_pan + ms * mstep_pan
		playback.push_frame(Vector2(l, r))


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
			get_tree().reload_current_scene()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			toggle_flash()
		elif event.keycode == KEY_C:
			crouch = not crouch
		elif event.keycode == KEY_E or event.keycode == KEY_SPACE:
			use_item()
		elif event.keycode == KEY_1:
			sel = 0
		elif event.keycode == KEY_2:
			sel = 1
		elif event.keycode == KEY_3:
			sel = 2
		elif event.keycode == KEY_4:
			sel = 3
		elif event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			use_item()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * 0.0025
		pitch = clamp(pitch - event.relative.y * 0.0025, -1.4, 1.4)
	elif event is InputEventScreenTouch:
		var vs = get_viewport().get_visible_rect().size
		if event.pressed:
			var handled = false
			for i in 4:
				if slot_rect(i, vs).has_point(event.position):
					sel = i
					handled = true
			if not handled:
				for b in button_defs(vs):
					if event.position.distance_to(b["p"]) < float(b["r"]) + 8.0:
						handled = true
						if b["id"] == "run":
							run_on = not run_on
						elif b["id"] == "luz":
							toggle_flash()
						elif b["id"] == "use":
							use_item()
						elif b["id"] == "crouch":
							crouch = not crouch
			if not handled:
				if event.position.x < vs.x * 0.5 and move_touch == -1:
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


# ---------------------------------------------------------------- ACCIONES

func use_item() -> void:
	if state != "play":
		return
	if sel == 0:
		do_attack()
	elif sel == 1:
		if inv_water > 0:
			inv_water -= 1
			health = minf(1.0, health + 0.25)
			sanity = minf(1.0, sanity + 0.35)
			stamina = 1.0
			show_msg("Agua de Almendra: te sientes mejor", 2.0)
		else:
			show_msg("No tienes Agua de Almendra", 1.2)
	elif sel == 2:
		if inv_batt > 0:
			inv_batt -= 1
			battery = minf(1.0, battery + 0.6)
			show_msg("Pilas puestas", 1.5)
		else:
			show_msg("No tienes pilas", 1.2)
	elif sel == 3:
		if inv_flare > 0 and flare_t <= 0.0:
			inv_flare -= 1
			place_flare()
		elif flare_t > 0.0:
			show_msg("Ya hay una bengala encendida", 1.2)
		else:
			show_msg("No tienes bengalas", 1.2)


func place_flare() -> void:
	flare_node = Node3D.new()
	flare_node.position = Vector3(pos.x, 0.15, pos.z)
	add_child(flare_node)
	flare_light = OmniLight3D.new()
	flare_light.light_color = Color(1.0, 0.3, 0.15)
	flare_light.omni_range = 16.0
	flare_light.light_energy = 2.5
	flare_node.add_child(flare_light)
	var core = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 0.06
	sm.height = 0.12
	core.mesh = sm
	core.material_override = glow_mat(Color(1, 0.2, 0.1), 4.0)
	flare_node.add_child(core)
	flare_t = 30.0
	show_msg("Bengala encendida (30 s)", 2.0)


func do_attack() -> void:
	if attack_cd > 0.0:
		return
	attack_cd = 0.8
	swing_t = 1.0
	noise_extra = 22.0
	var fwd = Vector3(-sin(yaw), 0, -cos(yaw))
	for m in monsters:
		if not m["active"]:
			continue
		var node: Node3D = m["node"]
		var to_m = node.position - pos
		to_m.y = 0
		var d = to_m.length()
		if d < 2.6 and d > 0.01 and fwd.dot(to_m / d) > 0.35:
			m["hp"] -= 1
			m["stun"] = 2.0
			m["state"] = "chase"
			var np = node.position + (to_m / d) * 2.5
			if not tile_wall(floori(np.x / S), floori(np.z / S)):
				node.position = np
			if m["hp"] <= 0:
				kill_monster(m)
			else:
				show_msg("¡Golpe!", 0.8)


func kill_monster(m: Dictionary) -> void:
	var node: Node3D = m["node"]
	node.visible = false
	m["active"] = false
	m["timer"] = 0.0
	m["delay"] = 40.0 if m["kind"] == "stalker" else 60.0
	m["hp"] = m["maxhp"]
	m["state"] = "patrol"
	show_msg("Lo derribaste... volverá.", 2.5)


func hurt(amount: float, san: float) -> void:
	health -= amount
	sanity = maxf(0.0, sanity - san)
	damage_flash = 1.0
	if health <= 0.0:
		state = "dead"
		state_time = 0.0
		msg.text = "Te encontró.\nSobreviviste " + format_time(play_time) + "\n\nToca la pantalla para reintentar"
		msg_t = 9999.0


func noise_radius() -> float:
	var r = 0.0
	if moving:
		if crouch:
			r = 4.0
		elif sprinting:
			r = 26.0
		else:
			r = 11.0
		if zones[cur_zone]["water"]:
			r *= 1.3
	return maxf(r, noise_extra)


# ---------------------------------------------------------------- BUCLE

func _process(delta: float) -> void:
	state_time += delta

	var pc = pchunk()
	var zi = zone_of(pc.x, pc.y)
	if zi != cur_zone:
		cur_zone = zi
		if state == "play":
			show_msg(str(zones[zi]["name"]), 2.5)
	var z: Dictionary = zones[cur_zone]

	var k = clamp(delta * 0.8, 0.0, 1.0)
	env.fog_light_color = env.fog_light_color.lerp(z["fog"], k)
	env.fog_density = lerpf(env.fog_density, z["fog_d"], k)
	env.ambient_light_color = env.ambient_light_color.lerp(z["amb"], k)
	env.ambient_light_energy = lerpf(env.ambient_light_energy, z["amb_e"], k)
	plight.light_color = plight.light_color.lerp(z["light"], k)
	plight.omni_range = lerpf(plight.omni_range, z["light_r"], k)
	cur_le = lerpf(cur_le, z["light_e"], k)

	flicker_t -= delta
	if flicker_t <= 0.0:
		if rng.randf() < 0.12 + threat * 0.3 + maxf(0.0, 0.4 - sanity) * 0.5:
			flick_on = false
			flicker_t = rng.randf_range(0.04, 0.18)
		else:
			flick_on = true
			flicker_t = rng.randf_range(0.2, 2.0)
	for zk in zone_cache.keys():
		var pm: StandardMaterial3D = zone_cache[zk]["panel"]
		var pe: float = zones[zk]["panel_e"]
		pm.emission_energy_multiplier = pe if flick_on else 0.3
	plight.light_energy = cur_le if flick_on else cur_le * 0.5

	if z["clank"]:
		clank_t -= delta
		if clank_t <= 0.0:
			clank_env = 1.0
			clank_pan = rng.randf()
			clank_t = rng.randf_range(4.0, 12.0)
	if z["drips"]:
		drip_t -= delta
		if drip_t <= 0.0:
			drip_env = 1.0
			drip_pan = rng.randf()
			drip_t = rng.randf_range(0.6, 3.0)

	if msg_t > 0.0:
		msg_t -= delta
		if msg_t <= 0.0 and state == "play":
			msg.text = ""

	if state == "play":
		play_time += delta
		update_chunks(false)
		update_player(delta)
		update_survival(delta)
		update_monsters(delta)
		update_smilers(delta)
		update_items(delta)
	elif state == "menu":
		yaw += delta * 0.25
		head.rotation.y = yaw

	danger.color = Color(0.45, 0, 0, clampf(maxf(threat * 0.35, damage_flash * 0.5), 0.0, 0.7))
	var sa = clampf((0.5 - sanity) * 1.0, 0.0, 0.5)
	san_rect.color = Color(0.1, 0.0, 0.15, sa * (0.7 + 0.3 * sin(state_time * 3.0)))
	axe_node.visible = (sel == 0)
	axe_node.rotation.x = -sin(swing_t * PI) * 1.3
	fill_audio()
	hud.queue_redraw()


func hits_wall(p: Vector3) -> bool:
	for ox in [-PR, PR]:
		for oz in [-PR, PR]:
			if tile_wall(floori((p.x + ox) / S), floori((p.z + oz) / S)):
				return true
	return false


func update_player(delta: float) -> void:
	var z: Dictionary = zones[cur_zone]
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
	moving = inp.length() > 0.1

	var wants_run = Input.is_key_pressed(KEY_SHIFT) or run_on or move_vec.length() > 0.95
	var speed = WALK
	sprinting = false
	if crouch:
		speed = WALK * 0.55
		stamina = min(1.0, stamina + delta * 0.15)
	elif wants_run and stamina > 0.02 and moving:
		speed = RUN
		sprinting = true
		stamina = max(0.0, stamina - delta * 0.25)
	else:
		stamina = min(1.0, stamina + delta * 0.15)
	if z["water"]:
		speed *= 0.7

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

	if moving:
		bob += delta * speed * 2.2
		var s_now = sin(bob)
		if (last_sign < 0.0 and s_now >= 0.0) or (last_sign >= 0.0 and s_now < 0.0):
			step_env = 1.0
			step_freq = z["step_freq"]
			step_amp = float(z["step_amp"]) * (0.35 if crouch else 1.0)
		last_sign = s_now
	cam_h = lerpf(cam_h, 1.0 if crouch else 1.65, clampf(delta * 8.0, 0.0, 1.0))
	head.position = pos + Vector3(0, cam_h + sin(bob) * 0.035, 0)
	head.rotation.y = yaw
	cam.rotation.x = pitch

	if flash_on:
		battery -= delta / 100.0
		if battery <= 0.0:
			battery = 0.0
			flash_on = false
			flash.visible = false
			show_msg("Se acabó la batería", 2.0)


func update_survival(delta: float) -> void:
	var z: Dictionary = zones[cur_zone]
	attack_cd = maxf(0.0, attack_cd - delta)
	swing_t = maxf(0.0, swing_t - delta * 3.0)
	noise_extra = maxf(0.0, noise_extra - delta * 25.0)
	damage_flash = maxf(0.0, damage_flash - delta * 1.5)

	var drain = threat * 0.02
	if cur_zone == 4:
		drain += 0.008
		if not flash_on and flare_t <= 0.0:
			drain += 0.006
	if drain <= 0.0 and threat < 0.1:
		sanity = minf(1.0, sanity + delta * 0.004)
	else:
		sanity = maxf(0.0, sanity - drain * delta)

	# alucinaciones con poca cordura
	if sanity < 0.3:
		ghost_t -= delta
		if ghost_t <= 0.0:
			ghost_t = rng.randf_range(7.0, 16.0)
			var fwd = Vector3(-sin(yaw), 0, -cos(yaw))
			var gp = pos + fwd * rng.randf_range(8.0, 13.0)
			if not tile_wall(floori(gp.x / S), floori(gp.z / S)):
				ghost.position = Vector3(gp.x, 0, gp.z)
				ghost.rotation.y = atan2(pos.x - gp.x, pos.z - gp.z)
				ghost.visible = true
				ghost_vis = 1.3
				growl_env = 0.6
	if ghost_vis > 0.0:
		ghost_vis -= delta
		if ghost_vis <= 0.0:
			ghost.visible = false

	# bengala
	if flare_t > 0.0:
		flare_t -= delta
		if flare_light != null:
			flare_light.light_energy = 2.2 + rng.randf() * 0.8
		if flare_t <= 0.0 and flare_node != null:
			flare_node.queue_free()
			flare_node = null
			flare_light = null


# ---------------------------------------------------------------- MONSTRUOS

func line_clear(a: Vector3, b: Vector3) -> bool:
	var d = a.distance_to(b)
	var steps = int(d / 0.5)
	for i in range(1, steps):
		var p = a.lerp(b, float(i) / steps)
		if tile_wall(floori(p.x / S), floori(p.z / S)):
			return false
	return true


func monster_lit(node: Node3D) -> bool:
	if not flash_on:
		return false
	var fwd = -cam.global_transform.basis.z
	var to_e = (node.position + Vector3(0, 1.2, 0)) - cam.global_position
	var d = to_e.length()
	if d > 14.0 or d < 0.1:
		return false
	if fwd.dot(to_e / d) < 0.9:
		return false
	return line_clear(cam.global_position, node.position + Vector3(0, 1.2, 0))


func random_open_near(center: Vector3, dmin: float, dmax: float) -> Vector3:
	var keys = chunks.keys()
	for i in 60:
		var key: Vector2i = keys[rng.randi() % keys.size()]
		var ch: Dictionary = chunks[key]
		var lx = rng.randi_range(1, CH - 2)
		var lz = rng.randi_range(1, CH - 2)
		if ch["map"][lz][lx] or ch["pb"][lz][lx]:
			continue
		var c = tile_center(Vector2i(key.x * CH + lx, key.y * CH + lz))
		var d = Vector2(c.x - center.x, c.z - center.z).length()
		if d >= dmin and d <= dmax:
			return c
	return Vector3.ZERO


func spawn_monster(m: Dictionary) -> void:
	var c = random_open_near(pos, 25.0, 60.0)
	if c.length() < 0.1:
		return
	var node: Node3D = m["node"]
	node.position = c
	node.visible = true
	m["active"] = true
	m["state"] = "patrol"
	m["target"] = Vector3.ZERO
	m["path_t"] = 0.0
	m["stun"] = 0.0
	if not entity_seen:
		entity_seen = true
		show_msg("Algo se mueve en los pasillos...", 3.0)


func update_monsters(delta: float) -> void:
	var t = 0.0
	for m in monsters:
		if not m["active"]:
			m["timer"] += delta
			if m["timer"] > m["delay"]:
				spawn_monster(m)
			continue
		update_monster(m, delta)
		var node: Node3D = m["node"]
		var d = Vector2(node.position.x - pos.x, node.position.z - pos.z).length()
		t = maxf(t, clampf((14.0 - d) / 14.0, 0.0, 1.0))
	threat = lerpf(threat, t, clampf(delta * 4.0, 0.0, 1.0))


func update_monster(m: Dictionary, delta: float) -> void:
	var node: Node3D = m["node"]
	m["cd"] = maxf(0.0, float(m["cd"]) - delta)
	var look = pos - node.position
	var d = Vector2(look.x, look.z).length()
	var et = Vector2i(floori(node.position.x / S), floori(node.position.z / S))
	if d > 75.0 or tile_wall(et.x, et.y):
		spawn_monster(m)
		return
	if float(m["stun"]) > 0.0:
		m["stun"] = float(m["stun"]) - delta
		return

	# percepcion: vista y oido
	var sight: float = m["sight"]
	if flash_on:
		sight *= 1.3
	if crouch:
		sight *= 0.6
	var sees = d < sight and line_clear(cam.global_position, node.position + Vector3(0, 1.2, 0))
	var nr = noise_radius() * float(m["hearing"])
	var hears = d < nr
	if sees or (hears and d < nr * 0.6):
		if m["state"] != "chase" and d < 40.0:
			growl_env = maxf(growl_env, 0.8)
		m["state"] = "chase"
		m["lose_t"] = 6.0
	elif hears:
		if m["state"] != "chase":
			m["state"] = "investigate"
			m["target"] = Vector3(pos.x, 0, pos.z)
	elif m["state"] == "chase":
		m["lose_t"] = float(m["lose_t"]) - delta
		if float(m["lose_t"]) <= 0.0:
			m["state"] = "patrol"
			m["target"] = Vector3.ZERO

	var goal = Vector3(pos.x, 0, pos.z)
	var mult = 1.0
	if m["state"] != "chase":
		var tg: Vector3 = m["target"]
		if tg.length() < 0.1 or Vector2(tg.x - node.position.x, tg.z - node.position.z).length() < 2.0:
			tg = random_open_near(node.position, 10.0, 28.0)
			m["target"] = tg
			m["state"] = "patrol"
		goal = tg
		mult = 0.7 if m["state"] == "investigate" else 0.45

	m["path_t"] = float(m["path_t"]) - delta
	if float(m["path_t"]) <= 0.0:
		m["path_t"] = 0.3
		if goal.length() < 0.1:
			m["next"] = node.position
		else:
			var gt = Vector2i(floori(goal.x / S), floori(goal.z / S))
			m["next"] = next_step(et, gt, node.position)

	var sp = float(m["speed"]) * mult
	if m["kind"] == "stalker" and monster_lit(node):
		sp *= 0.4
	var scared = false
	if flare_t > 0.0 and flare_node != null:
		if Vector2(node.position.x - flare_node.position.x, node.position.z - flare_node.position.z).length() < 12.0:
			sp *= 0.3
			scared = true
	var nxt: Vector3 = m["next"]
	var to = nxt - node.position
	to.y = 0
	if to.length() > 0.05:
		node.position += to.normalized() * sp * delta
		node.rotation.y = lerp_angle(node.rotation.y, atan2(to.x, to.z), clampf(delta * 8.0, 0.0, 1.0))

	# animacion y pasos
	m["phase"] = float(m["phase"]) + delta * sp * 2.2
	var ang = sin(float(m["phase"])) * 0.6
	for pa in m["a"]:
		pa.rotation.x = ang
	for pb in m["b"]:
		pb.rotation.x = -ang
	var sg = sin(float(m["phase"]))
	if (float(m["last_sign"]) < 0.0 and sg >= 0.0) or (float(m["last_sign"]) >= 0.0 and sg < 0.0):
		if d < 24.0:
			mstep_env = maxf(mstep_env, 1.0 - d / 24.0)
			var right = Vector3(cos(yaw), 0, -sin(yaw))
			var dirm = Vector3(-look.x, 0, -look.z).normalized()
			mstep_pan = clampf(0.5 + dirm.dot(right) * 0.5, 0.0, 1.0)
	m["last_sign"] = sg

	# ataque
	if m["state"] == "chase" and d < 1.3 and float(m["cd"]) <= 0.0 and not scared:
		hurt(float(m["dmg"]), 0.12)
		m["cd"] = 1.3
		m["stun"] = 0.6
		var back = Vector3(node.position.x - pos.x, 0, node.position.z - pos.z).normalized() * 1.5
		var np = node.position + back
		if not tile_wall(floori(np.x / S), floori(np.z / S)):
			node.position = np


func next_step(a: Vector2i, b: Vector2i, fallback: Vector3) -> Vector3:
	if a == b:
		return tile_center(b)
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
			if not prev.has(n) and not tile_wall(n.x, n.y):
				prev[n] = c
				q.append(n)
	if not found:
		return fallback
	var cur: Vector2i = b
	while prev[cur] != a:
		cur = prev[cur]
	return tile_center(cur)


func update_smilers(delta: float) -> void:
	var fwd3 = -cam.global_transform.basis.z
	for ch in chunks.values():
		for sm in ch["smilers"].duplicate():
			var node: Node3D = sm["node"]
			var gp = node.global_position
			var to = Vector3(pos.x - gp.x, 0, pos.z - gp.z)
			var d = to.length()
			node.rotation.y = atan2(to.x, to.z)
			if d > 40.0:
				continue
			var dir = (Vector3(gp.x, 1.65, gp.z) - cam.global_position).normalized()
			var seen = d < 18.0 and fwd3.dot(dir) > 0.8 and line_clear(cam.global_position, gp)
			if seen:
				sanity = maxf(0.0, sanity - delta * 0.05 * (1.3 - d / 18.0))
				if d < 9.0 and d > 1.3:
					var np = gp + to.normalized() * 2.8 * delta
					if not tile_wall(floori(np.x / S), floori(np.z / S)):
						node.global_position = Vector3(np.x, gp.y, np.z)
			if d < 1.3:
				ch["smilers"].erase(sm)
				node.queue_free()
				show_msg("El Smiler te alcanzó", 2.0)
				hurt(0.3, 0.25)


func update_items(delta: float) -> void:
	var t = Time.get_ticks_msec() / 1000.0
	for ch in chunks.values():
		for it in ch["items"].duplicate():
			var node: MeshInstance3D = it["node"]
			node.rotation.y += delta
			node.position.y = float(it["y"]) + sin(t * 2.0 + node.position.x) * 0.04
			var gp = node.global_position
			if Vector2(gp.x - pos.x, gp.z - pos.z).length() < 1.1:
				taken[it["id"]] = true
				ch["items"].erase(it)
				node.queue_free()
				if it["kind"] == 0:
					inv_water += 1
					show_msg("Agua de Almendra (x%d)" % inv_water, 1.8)
				elif it["kind"] == 1:
					inv_batt += 1
					show_msg("Pilas (x%d)" % inv_batt, 1.8)
				else:
					inv_flare += 1
					show_msg("Bengala (x%d)" % inv_flare, 1.8)
