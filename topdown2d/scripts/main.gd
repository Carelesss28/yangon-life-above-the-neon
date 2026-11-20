extends Node2D
## YANGON: Life above the neon -- 2D top-down world (whole campus_terrain map, streamed in 100 m chunks).
## Coordinates: metres (x east, z south) -> pixels with wp(). 16 px per metre. Data: assets/game_data.dat (art/build.mjs).

const U := 16.0
const INTERIOR_ORIGIN := Vector2(40000, 40000)

var D: Dictionary
var OX := 300.0
var OY := 700.0
var CHUNK_PX := 1600.0
var tex_cache := {}
var world: Node2D
var glow: Node2D
var player: CharacterBody2D
var psprite: Sprite2D
var cam: Camera2D
var hud: CanvasLayer
var prompt: Label
var clock_label: Label
var help_label: Label
var fade_rect: ColorRect
var lift_rect: ColorRect
var add_mat: CanvasItemMaterial
var halo_tex: Texture2D
var dlg_panel: PanelContainer
var dlg_name: Label
var dlg_text: Label
var map_rect: TextureRect
var map_dot: ColorRect
var map_info: Label

var chunk_meta := {}               # "i_j" -> {emis}
var buckets := {}                  # "i_j" -> {trees, props, doors, cats, birds, nav}
var loaded := {}                   # "i_j" -> {ents:Array, emis:Sprite2D}
var load_queue: Array = []
var loader_thread: Thread = null
var loader_key := ""
var halos := {}                    # key -> Array[{node,strength}]
var adj := {}                      # nav node index -> Array[int]
var nav_pos: Array = []
var stations: Array = []
var tod := 18.7
var time_mult := 1.0
var night := 1.0
var facing := "d"
var anim_t := 0.0
var busy := false
var talking := false
var dlg_lines: Array = []
var dlg_i := 0
var dlg_target: Node = null
var interior_type := ""
var interior_root: Node2D
var interior_door: Dictionary = {}
var chunk_timer := 0.0
var cars: Array = []
var map_on := false

# ------------------------------------------------------------------ helpers
func wp(x: float, z: float) -> Vector2:
	return Vector2((x + OX) * U, (z + OY) * U)

func ckey(p: Vector2) -> String:
	return "%d_%d" % [int(floor(p.x / CHUNK_PX)), int(floor(p.y / CHUNK_PX))]

func tex(name: String) -> Texture2D:
	if tex_cache.has(name):
		return tex_cache[name]
	var img := Image.new()
	if img.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/" + name.replace(".png", ".dat"))) != OK:
		push_error("missing texture: " + name)
		return null
	var t := ImageTexture.create_from_image(img)
	tex_cache[name] = t
	return t

func make_sprite(name: String, foot: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex("sprites/" + name + ".png")
	s.centered = false
	s.offset = -foot
	return s

func radial_tex(size: int) -> Texture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.35, 0.7, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0.12), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = size
	t.height = size
	return t

func add_halo(key: String, ents: Array, pos: Vector2, col: Color, radius_px: float, strength: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = halo_tex
	s.material = add_mat
	s.position = pos
	s.scale = Vector2.ONE * (radius_px * 2.0 / 128.0)
	s.modulate = Color(col.r, col.g, col.b, 0.0)
	s.set_meta("col", col)
	glow.add_child(s)
	ents.append(s)
	if not halos.has(key):
		halos[key] = []
	halos[key].append({"node": s, "strength": strength})
	return s

func add_rect(body: StaticBody2D, r: Rect2) -> void:
	var cs := CollisionShape2D.new()
	var s := RectangleShape2D.new()
	s.size = r.size
	cs.shape = s
	cs.position = r.position + r.size / 2.0
	body.add_child(cs)

# ------------------------------------------------------------------ setup
func _ready() -> void:
	D = JSON.parse_string(FileAccess.get_file_as_string("res://assets/game_data.dat"))
	OX = D.ox
	OY = D.oy
	CHUNK_PX = D.chunkM * U
	add_mat = CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	halo_tex = radial_tex(128)
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	glow = Node2D.new()
	glow.name = "Glow"
	add_child(glow)
	for c in D.chunks:
		chunk_meta["%d_%d" % [c.i, c.j]] = c
	_build_buckets()
	_build_nav()
	_build_global_colliders()
	_build_player()
	_build_hud()
	stations = D.stations
	_update_chunks(true)
	_spawn_cars()
	_spawn_trains()
	_apply_time()
	var args := OS.get_cmdline_user_args()
	if "--capture" in args:
		_capture()
	elif "--collide" in args:
		_collide_test()

func _bucket(key: String) -> Dictionary:
	if not buckets.has(key):
		buckets[key] = {"trees": [], "props": [], "doors": [], "cats": [], "birds": [], "nav": []}
	return buckets[key]

func _build_buckets() -> void:
	for t in D.trees:
		_bucket(ckey(wp(t.x, t.z)))["trees"].append(t)
	for p in D.props:
		_bucket(ckey(wp(p.x, p.z)))["props"].append(p)
	for d in D.doors:
		_bucket(ckey(wp(d.x, d.z)))["doors"].append(d)
	for c in D.catHomes:
		_bucket(ckey(wp(c[0], c[1])))["cats"].append(c)
	for b in D.birdHomes:
		_bucket(ckey(wp(b[0], b[1])))["birds"].append(b)

func _build_nav() -> void:
	nav_pos = D.navNodes
	for i in range(nav_pos.size()):
		adj[i] = []
		_bucket(ckey(wp(nav_pos[i][0], nav_pos[i][1])))["nav"].append(i)
	for e in D.navEdges:
		adj[int(e[0])].append(int(e[1]))
		adj[int(e[1])].append(int(e[0]))

func _build_global_colliders() -> void:
	var body := StaticBody2D.new()
	body.name = "Solid"
	world.add_child(body)
	for r in D.colliders:
		add_rect(body, Rect2(wp(r[0], r[1]), Vector2(r[2], r[3]) * U))
	var w: float = D.wm * U
	var h: float = D.hm * U
	var t := 600.0
	add_rect(body, Rect2(-t, -t, w + 2 * t, t))
	add_rect(body, Rect2(-t, h, w + 2 * t, t))
	add_rect(body, Rect2(-t, 0, t, h))
	add_rect(body, Rect2(w, 0, t, h))

func _build_player() -> void:
	player = CharacterBody2D.new()
	player.name = "Player"
	player.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(10, 5)
	cs.shape = rs
	cs.position = Vector2(0, -2.5)
	player.add_child(cs)
	psprite = make_sprite("p_d0", Vector2(7, 26))
	player.add_child(psprite)
	cam = Camera2D.new()
	cam.zoom = Vector2(2, 2)
	cam.position = Vector2(0, -14)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 9.0
	player.add_child(cam)
	player.position = wp(D.start[0], D.start[1])
	world.add_child(player)
	_set_outdoor_limits()

func _set_outdoor_limits() -> void:
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(D.wm * U)
	cam.limit_bottom = int(D.hm * U)

func _label(pos: Vector2, size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 5)
	hud.add_child(l)
	return l

func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	lift_rect = ColorRect.new()
	lift_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	lift_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lift_rect.material = add_mat
	hud.add_child(lift_rect)
	fade_rect = ColorRect.new()
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.color = Color(0, 0, 0, 0)
	hud.add_child(fade_rect)
	clock_label = _label(Vector2(12, 8), 18)
	help_label = _label(Vector2(12, 34), 13)
	help_label.text = "WASD / arrows: move   Shift: run   E: talk / enter / ride   M: map   N: time of day   T: fast time   H: help"
	help_label.modulate = Color(0.75, 0.85, 1.0, 0.85)
	prompt = _label(Vector2(0, 0), 22)
	prompt.anchor_left = 0.0
	prompt.anchor_right = 1.0
	prompt.anchor_top = 1.0
	prompt.anchor_bottom = 1.0
	prompt.offset_top = -170
	prompt.offset_bottom = -140
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.modulate = Color(0.35, 0.95, 0.9)
	dlg_panel = PanelContainer.new()
	dlg_panel.anchor_left = 0.1
	dlg_panel.anchor_right = 0.9
	dlg_panel.anchor_top = 1.0
	dlg_panel.anchor_bottom = 1.0
	dlg_panel.offset_top = -150
	dlg_panel.offset_bottom = -20
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.04, 0.12, 0.92)
	sb.border_color = Color(0.35, 0.95, 0.9)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(14)
	dlg_panel.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	dlg_panel.add_child(vb)
	dlg_name = Label.new()
	dlg_name.add_theme_font_size_override("font_size", 20)
	dlg_name.modulate = Color(1.0, 0.45, 0.75)
	vb.add_child(dlg_name)
	dlg_text = Label.new()
	dlg_text.add_theme_font_size_override("font_size", 20)
	dlg_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dlg_text.custom_minimum_size = Vector2(900, 60)
	vb.add_child(dlg_text)
	var hint := Label.new()
	hint.text = "E  -  continue"
	hint.add_theme_font_size_override("font_size", 13)
	hint.modulate = Color(0.35, 0.95, 0.9, 0.8)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vb.add_child(hint)
	dlg_panel.visible = false
	hud.add_child(dlg_panel)
	map_rect = TextureRect.new()
	map_rect.texture = tex("worldmap.png")
	map_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_rect.stretch_mode = TextureRect.STRETCH_SCALE
	var mh := 690.0
	var mw: float = mh * float(D.wm) / float(D.hm)
	map_rect.size = Vector2(mw, mh)
	map_rect.position = Vector2((1280.0 - mw) / 2.0, 15)
	map_rect.visible = false
	hud.add_child(map_rect)
	map_dot = ColorRect.new()
	map_dot.size = Vector2(8, 8)
	map_dot.color = Color(1, 0.2, 0.5)
	map_rect.add_child(map_dot)
	map_info = _label(Vector2(12, 690), 16)
	map_info.visible = false

# ------------------------------------------------------------------ chunk streaming
func _read_chunk_images(key: String) -> Dictionary:
	var res := {}
	for kind in ["b", "e"]:
		if kind == "e" and not chunk_meta[key].emis:
			continue
		var path := "res://assets/chunks/%s_%s.dat" % [kind, key]
		if not FileAccess.file_exists(path):
			continue
		var img := Image.new()
		if img.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK:
			res[kind] = img
	return res

func _desired_keys() -> Array:
	var parts := ckey(player.position).split("_")
	var pi := int(parts[0])
	var pj := int(parts[1])
	var out: Array = []
	for di in range(-1, 2):
		for dj in range(-1, 2):
			var k := "%d_%d" % [pi + di, pj + dj]
			if chunk_meta.has(k):
				out.append(k)
	return out

func _update_chunks(sync: bool = false) -> void:
	if interior_type != "":
		return
	for k in _desired_keys():
		if not loaded.has(k) and not load_queue.has(k) and k != loader_key:
			if sync:
				_finish_chunk(k, _read_chunk_images(k))
			else:
				load_queue.append(k)
	var pk := ckey(player.position).split("_")
	for k in loaded.keys():
		var p := String(k).split("_")
		if absi(int(p[0]) - int(pk[0])) > 2 or absi(int(p[1]) - int(pk[1])) > 2:
			_unload_chunk(k)

func _pump_loader() -> void:
	if loader_thread != null and not loader_thread.is_alive():
		var res: Dictionary = loader_thread.wait_to_finish()
		loader_thread = null
		var k := loader_key
		loader_key = ""
		if not loaded.has(k):
			_finish_chunk(k, res)
	if loader_thread == null and load_queue.size() > 0:
		var k: String = load_queue.pop_front()
		if not _desired_keys().has(k):
			return
		if (not OS.has_feature("web")):
			loader_key = k
			loader_thread = Thread.new()
			loader_thread.start(_read_chunk_images.bind(k))
		else:
			_finish_chunk(k, _read_chunk_images(k))

func _finish_chunk(key: String, imgs: Dictionary) -> void:
	if loaded.has(key):
		return
	var parts := key.split("_")
	var origin := Vector2(int(parts[0]), int(parts[1])) * CHUNK_PX
	var ents: Array = []
	var rec := {"ents": ents, "emis": null}
	if imgs.has("b"):
		var s := Sprite2D.new()
		s.texture = ImageTexture.create_from_image(imgs["b"])
		s.centered = false
		s.position = origin
		s.z_index = -100
		world.add_child(s)
		ents.append(s)
	if imgs.has("e"):
		var e := Sprite2D.new()
		e.texture = ImageTexture.create_from_image(imgs["e"])
		e.centered = false
		e.position = origin
		e.material = add_mat
		glow.add_child(e)
		ents.append(e)
		rec["emis"] = e
	loaded[key] = rec
	_spawn_entities(key, ents)
	if interior_type != "":
		for n in ents:
			n.visible = false
	_apply_time()

func _unload_chunk(key: String) -> void:
	for n in loaded[key].ents:
		if is_instance_valid(n):
			n.queue_free()
	halos.erase(key)
	loaded.erase(key)

const PROP_FOOT := {
	"lamp": Vector2(8, 72), "bench": Vector2(16, 19), "bin": Vector2(6, 18), "vending": Vector2(12, 36),
	"board": Vector2(20, 42), "bikerack": Vector2(23, 20), "signmap": Vector2(20, 46), "kiosk": Vector2(25, 40),
	"statue": Vector2(41, 132), "swing": Vector2(20, 40),
}

func _spawn_entities(key: String, ents: Array) -> void:
	if not buckets.has(key):
		return
	var b: Dictionary = buckets[key]
	var body := StaticBody2D.new()
	world.add_child(body)
	ents.append(body)
	for t in b.trees:
		var k: String = t.k
		var s := make_sprite(k, Vector2(49, 120) if k == "palm" else Vector2(49, 110))
		s.position = wp(t.x, t.z)
		world.add_child(s)
		ents.append(s)
		add_rect(body, Rect2(s.position + Vector2(-5, -6), Vector2(10, 6)))
		if k == "palm":
			add_halo(key, ents, s.position + Vector2(0, -78), Color(1.0, 0.3, 0.65), 46.0, 0.35)
	for p in b.props:
		var foot: Vector2 = PROP_FOOT[p.k]
		var s := make_sprite(p.k, foot)
		s.position = wp(p.x, p.z)
		world.add_child(s)
		ents.append(s)
		if p.coll != null:
			var w: float = p.coll[0] * U
			var d: float = p.coll[1] * U
			add_rect(body, Rect2(s.position + Vector2(-w / 2.0, -d), Vector2(w, d)))
		match p.k:
			"lamp": add_halo(key, ents, s.position + Vector2(0, -66), Color(0.35, 0.95, 0.9), 95.0, 0.55)
			"vending": add_halo(key, ents, s.position + Vector2(0, -18), Color(1.0, 0.6, 0.5), 36.0, 0.5)
			"board", "signmap": add_halo(key, ents, s.position + Vector2(0, -28), Color(0.35, 0.9, 0.95), 40.0, 0.4)
			"statue": add_halo(key, ents, s.position + Vector2(0, -80), Color(0.35, 0.95, 0.9), 70.0, 0.5)
			"kiosk": add_halo(key, ents, s.position + Vector2(0, -16), Color(1.0, 0.45, 0.7), 56.0, 0.5)
	for d in b.doors:
		add_halo(key, ents, wp(d.x, d.z + 1.0), Color(1.0, 0.72, 0.35), 70.0, 0.55)
	for c in b.cats:
		var cat := Cat.new()
		cat.main = self
		cat.prefix = c[2]
		cat.home = wp(c[0], c[1])
		cat.position = cat.home
		world.add_child(cat)
		ents.append(cat)
	for h in b.birds:
		for k in range(3):
			var bird := Bird.new()
			bird.main = self
			bird.home = wp(h[0] + randf_range(-3, 3), h[1] + randf_range(-3, 3))
			bird.position = bird.home
			world.add_child(bird)
			ents.append(bird)
	var nav: Array = b.nav
	for k in range(mini(3, nav.size())):
		var idx: int = nav[randi() % nav.size()]
		var p := Person.new()
		p.main = self
		p.skin = randi() % 6
		p.cur = idx
		p.nxt = adj[idx][randi() % adj[idx].size()] if adj[idx].size() > 0 else idx
		p.pname = D.names[randi() % D.names.size()]
		p.off = Vector2(randf_range(-0.9, 0.9), randf_range(-0.9, 0.9)) * U
		p.position = wp(nav_pos[idx][0], nav_pos[idx][1]) + p.off
		world.add_child(p)
		ents.append(p)

# ------------------------------------------------------------------ actors
func _spawn_cars() -> void:
	var li := 0
	for loop in D.carLoops:
		var pts: Array = []
		for p in loop:
			pts.append(wp(p[0], p[1]))
		for i in range(2):
			var c := Car.new()
			c.main = self
			c.pts = pts
			c.variant = (li + i) % 3
			c.idx = (i * 2) % pts.size()
			world.add_child(c)
			cars.append(c)
		li += 1

func _spawn_trains() -> void:
	var city: Array = []
	for p in D.cityLine:
		city.append(wp(p[0], p[1]))
	for i in range(2):
		var t := Train.new()
		t.main = self
		t.pts = city
		t.loop = true
		t.idx = i * 2
		t.position = city[t.idx]
		t.z_index = 30
		add_child(t)
	var mk: Array = []
	for p in D.marketLine:
		mk.append(wp(p[0], p[1]))
	var t2 := Train.new()
	t2.main = self
	t2.pts = mk
	t2.loop = false
	t2.position = mk[0]
	t2.z_index = 30
	add_child(t2)

class Person extends Node2D:
	var main
	var skin := 0
	var cur := 0
	var nxt := 0
	var off := Vector2.ZERO
	var wait := 0.0
	var f := 0.0
	var dir := "d"
	var pname := ""
	var talking := false
	var spr: Sprite2D
	func _ready() -> void:
		spr = main.make_sprite("n%d_d0" % skin, Vector2(7, 26))
		add_child(spr)
		add_to_group("talkable")
		if not has_meta("talk"):
			set_meta("talk", {"name": pname, "role": "Resident", "lines": []})
	func _process(dt: float) -> void:
		if main.interior_type != "" or talking or main.talking:
			return
		if wait > 0.0:
			wait -= dt
			spr.texture = main.tex("sprites/n%d_%s0.png" % [skin, dir])
			return
		var np: Array = main.nav_pos[nxt]
		var tgt: Vector2 = main.wp(np[0], np[1]) + off
		var to := tgt - position
		if to.length() < 3.0:
			var opts: Array = main.adj[nxt].duplicate()
			if opts.size() == 0:
				wait = 3.0
				return
			if opts.size() > 1:
				opts.erase(cur)
			cur = nxt
			nxt = opts[randi() % opts.size()]
			if randf() < 0.3:
				wait = randf_range(1.0, 4.0)
			return
		dir = ("r" if to.x > 0 else "l") if absf(to.x) > absf(to.y) else ("d" if to.y > 0 else "u")
		position += to.normalized() * 50.0 * dt
		f += dt * 7.0
		spr.texture = main.tex("sprites/n%d_%s%d.png" % [skin, dir, int(f) % 4])
	func face(p: Vector2) -> void:
		var d := p - global_position
		dir = ("r" if d.x > 0 else "l") if absf(d.x) > absf(d.y) else ("d" if d.y > 0 else "u")
		spr.texture = main.tex("sprites/n%d_%s0.png" % [skin, dir])

class Cat extends Node2D:
	var main
	var prefix := "cat"
	var home := Vector2.ZERO
	var tgt := Vector2.ZERO
	var state := "sit"
	var timer := 2.0
	var f := 0.0
	var spr: Sprite2D
	func _ready() -> void:
		spr = main.make_sprite(prefix + "_s", Vector2(8, 10))
		add_child(spr)
	func _process(dt: float) -> void:
		if main.interior_type != "":
			return
		timer -= dt
		if state == "sit":
			spr.texture = main.tex("sprites/%s_s.png" % prefix)
			if timer <= 0.0:
				tgt = home + Vector2(randf_range(-80, 80), randf_range(-60, 60))
				state = "walk"
				timer = 8.0
		else:
			var to := tgt - position
			if to.length() < 3.0 or timer <= 0.0:
				state = "sit"
				timer = randf_range(3.0, 9.0)
				return
			spr.flip_h = to.x < 0
			position += to.normalized() * 22.0 * dt
			f += dt * 6.0
			spr.texture = main.tex("sprites/%s_%d.png" % [prefix, int(f) % 2])

class Bird extends Node2D:
	var main
	var home := Vector2.ZERO
	var state := "stand"
	var timer := 0.0
	var vel := Vector2.ZERO
	var f := 0.0
	var spr: Sprite2D
	func _ready() -> void:
		spr = main.make_sprite("bird_0", Vector2(4, 7))
		add_child(spr)
		timer = randf_range(0.5, 3.0)
	func _process(dt: float) -> void:
		if main.interior_type != "":
			return
		var pd: float = position.distance_to(main.player.position)
		if state == "stand":
			if pd < 70.0:
				state = "fly"
				vel = (position - main.player.position).normalized() * 120.0 + Vector2(randf_range(-30, 30), -40)
				timer = randf_range(3.0, 5.0)
				z_index = 50
				return
			timer -= dt
			if timer <= 0.0:
				timer = randf_range(0.6, 3.0)
				position += Vector2(randf_range(-8, 8), randf_range(-5, 5))
				spr.texture = main.tex("sprites/bird_%d.png" % randi_range(0, 1))
		elif state == "fly":
			timer -= dt
			position += vel * dt
			f += dt * 14.0
			spr.texture = main.tex("sprites/bird_f%d.png" % (int(f) % 2))
			spr.flip_h = vel.x < 0
			if timer <= 0.0:
				state = "away"
				timer = randf_range(6.0, 12.0)
				visible = false
		elif state == "away":
			timer -= dt
			if timer <= 0.0 and pd > 200.0:
				position = home
				z_index = 0
				visible = main.interior_type == ""
				state = "stand"

class Car extends Node2D:
	var main
	var pts: Array = []
	var variant := 0
	var idx := 0
	var spr: Sprite2D
	var halo: Sprite2D
	var speed := 135.0
	var junk: Array = []
	func _ready() -> void:
		spr = Sprite2D.new()
		spr.texture = main.tex("sprites/%s_h.png" % _prefix())
		spr.offset = Vector2(0, -8)
		add_child(spr)
		position = pts[idx % pts.size()]
		halo = main.add_halo("cars", junk, position, Color(0.35, 0.95, 0.9) if variant != 1 else Color(1, 0.3, 0.65), 55.0, 0.55)
	func _prefix() -> String:
		return ["car", "car2", "car3"][variant]
	func _process(dt: float) -> void:
		var a: Vector2 = pts[idx % pts.size()]
		var b: Vector2 = pts[(idx + 1) % pts.size()]
		var d := (b - a).normalized()
		var v := speed
		var rel: Vector2 = main.player.position - position
		if main.interior_type == "" and rel.dot(d) > 0.0 and rel.dot(d) < 110.0 and absf(rel.cross(d)) < 40.0:
			v = 0.0
		position += d * v * dt
		if (position - a).length() >= (b - a).length():
			position = b
			idx += 1
		var near: bool = main.interior_type == "" and position.distance_to(main.player.position) < 1100.0
		visible = near
		if halo != null:
			halo.visible = near
			halo.position = position
		if not near:
			return
		var horiz := absf(d.x) > absf(d.y)
		spr.texture = main.tex("sprites/%s_%s.png" % [_prefix(), "h" if horiz else "v"])
		spr.flip_h = horiz and d.x < 0
		spr.flip_v = (not horiz) and d.y < 0

class Train extends Node2D:
	var main
	var pts: Array = []
	var loop := true
	var idx := 0
	var dirn := 1
	var wait := 0.0
	var spr: Sprite2D
	func _ready() -> void:
		spr = Sprite2D.new()
		spr.texture = main.tex("sprites/train_h.png")
		spr.offset = Vector2(0, -6)
		add_child(spr)
	func _process(dt: float) -> void:
		if wait > 0.0:
			wait -= dt
			return
		var n := pts.size()
		var ai: int = idx % n
		var bi: int = (idx + dirn) % n if loop else clampi(idx + dirn, 0, n - 1)
		var a: Vector2 = pts[ai]
		var b: Vector2 = pts[bi]
		var d := (b - a).normalized()
		position += d * 300.0 * dt
		if (position - a).length() >= (b - a).length():
			position = b
			if loop:
				idx += 1
			else:
				idx += dirn
				if idx <= 0 or idx >= n - 1:
					dirn = -dirn
					wait = 6.0
		var horiz := absf(d.x) > absf(d.y)
		spr.texture = main.tex("sprites/train_%s.png" % ("h" if horiz else "v"))
		spr.flip_h = horiz and d.x < 0
		spr.flip_v = (not horiz) and d.y < 0
		visible = main.interior_type == "" and position.distance_to(main.player.position) < 1500.0

# ------------------------------------------------------------------ loop
func _physics_process(dt: float) -> void:
	if busy or talking:
		player.velocity = Vector2.ZERO
		return
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): v.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): v.x += 1
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP): v.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN): v.y += 1
	var run := Input.is_physical_key_pressed(KEY_SHIFT)
	player.velocity = v.normalized() * (170.0 if run else 100.0)
	player.move_and_slide()
	if v != Vector2.ZERO:
		facing = ("r" if v.x > 0 else "l") if absf(v.x) > absf(v.y) else ("d" if v.y > 0 else "u")
		anim_t += dt * (11.0 if run else 8.0)
	else:
		anim_t = 0.0
	psprite.texture = tex("sprites/p_%s%d.png" % [facing, int(anim_t) % 4])

func _process(dt: float) -> void:
	if interior_type == "" and not talking and not busy:
		tod = fposmod(tod + dt * (24.0 / 1800.0) * time_mult, 24.0)
	_apply_time()
	chunk_timer -= dt
	if chunk_timer <= 0.0:
		chunk_timer = 0.3
		_update_chunks()
	_pump_loader()
	_update_prompt()
	if map_on:
		_update_map()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_E, KEY_ENTER, KEY_SPACE:
				_interact()
			KEY_M:
				map_on = not map_on
				map_rect.visible = map_on
				map_info.visible = map_on
			KEY_N:
				var nxt := [8.0, 12.0, 18.7, 22.0, 3.0]
				for h in nxt:
					if h > tod + 0.05:
						tod = h
						return
				tod = nxt[0]
			KEY_T:
				time_mult = 1.0 if time_mult > 10.0 else 30.0
			KEY_H:
				help_label.visible = not help_label.visible

func _update_map() -> void:
	var pm := _player_m()
	var sx: float = map_rect.size.x / float(D.wm)
	var sy: float = map_rect.size.y / float(D.hm)
	map_dot.position = Vector2((pm.x + OX) * sx, (pm.y + OY) * sy) - Vector2(4, 4)
	map_info.text = "YOU ARE HERE  -  %s     (M to close)" % _district(pm)

# ------------------------------------------------------------------ day / night
const KH := [0.0, 5.0, 6.5, 8.0, 17.0, 18.5, 20.5, 24.0]
const KTINT := [Color(0.42, 0.5, 0.82), Color(0.42, 0.5, 0.82), Color(0.9, 0.78, 0.86), Color(1, 1, 1), Color(1, 1, 1), Color(1.0, 0.74, 0.72), Color(0.58, 0.64, 0.92), Color(0.42, 0.5, 0.82)]
const KLIFT := [Color(0, 0, 0), Color(0, 0, 0), Color(0.05, 0.03, 0.02), Color(0.2, 0.18, 0.09), Color(0.2, 0.18, 0.09), Color(0.07, 0.03, 0.02), Color(0, 0, 0), Color(0, 0, 0)]
const KNIGHT := [1.0, 1.0, 0.6, 0.0, 0.0, 0.5, 1.0, 1.0]

func _district(pm: Vector2) -> String:
	if pm.y < -300: return "NORTHERN MARKET"
	if pm.y < 0: return "NORTH HILLS"
	if pm.x < 0 and pm.y < 614: return "WEST HILLS"
	if pm.y > 614: return "SOUTH RIVERFRONT"
	if pm.x < 314 and pm.y < 314: return "YUST CAMPUS"
	if pm.x >= 314 and pm.y < 314: return "STUDENT / TECH HUB"
	if pm.x < 314: return "HOME TERRACES"
	return "LAKESIDE"

func _apply_time() -> void:
	var i := 0
	while i < KH.size() - 2 and tod >= KH[i + 1]:
		i += 1
	var f: float = (tod - KH[i]) / (KH[i + 1] - KH[i])
	var tint: Color = KTINT[i].lerp(KTINT[i + 1], f)
	var lift: Color = KLIFT[i].lerp(KLIFT[i + 1], f)
	night = lerpf(KNIGHT[i], KNIGHT[i + 1], f)
	var hh := "%02d:%02d" % [int(tod), int(fmod(tod, 1.0) * 60.0)]
	if interior_type != "":
		world.modulate = Color(1, 1, 1)
		lift_rect.visible = false
		glow.visible = false
		clock_label.text = "%s   %s" % [interior_door.label, hh]
		return
	world.modulate = tint
	lift_rect.visible = true
	lift_rect.color = Color(lift.r, lift.g, lift.b, 1.0)
	glow.visible = true
	var ea := Color(1, 1, 1, clampf(0.12 + night, 0.0, 1.0))
	for k in loaded:
		var e = loaded[k].emis
		if e != null and is_instance_valid(e):
			e.modulate = ea
	for k in halos:
		for n in halos[k]:
			var s: Sprite2D = n.node
			if is_instance_valid(s):
				var c: Color = s.get_meta("col")
				s.modulate = Color(c.r, c.g, c.b, night * n.strength)
	clock_label.text = "%s   %s" % [_district(_player_m()), hh]

# ------------------------------------------------------------------ interaction
func _player_m() -> Vector2:
	return player.position / U - Vector2(OX, OY)

func _near_door() -> Dictionary:
	var pm := _player_m()
	for d in D.doors:
		var r: Array = d.r
		if Rect2(r[0], r[1], r[2], r[3]).has_point(pm):
			return d
	return {}

func _station_horiz(s: Dictionary) -> bool:
	return s.z == 8 or s.z == 616 or s.id == "M2"

func _station_rect(s: Dictionary) -> Rect2:
	return Rect2(s.x - 10, s.z - 6, 20, 12) if _station_horiz(s) else Rect2(s.x - 6, s.z - 10, 12, 20)

func _near_station() -> Dictionary:
	var pm := _player_m()
	for s in stations:
		if _station_rect(s).has_point(pm):
			return s
	return {}

func _next_station(s: Dictionary) -> Dictionary:
	var line: Array = []
	for t in stations:
		if s.line == "C" and t.line == "C":
			line.append(t)
		elif s.line == "M" and t.id in ["C2", "M2", "M3"]:
			line.append(t)
		elif s.id == "C2" and t.id in ["C2", "M2", "M3"]:
			line.append(t)
	if s.id == "C2":
		line = []
		for t in stations:
			if t.line == "C":
				line.append(t)
	var i := 0
	for k in range(line.size()):
		if line[k].id == s.id:
			i = k
	return line[(i + 1) % line.size()]

func _near_talk() -> Node:
	var best: Node = null
	var bd := 34.0
	for n in get_tree().get_nodes_in_group("talkable"):
		if not is_instance_valid(n) or not n.is_visible_in_tree():
			continue
		var d: float = n.global_position.distance_to(player.position)
		if d < bd:
			bd = d
			best = n
	return best

func _near_exit() -> bool:
	var R: Dictionary = D.interiors[interior_type]
	var pm := (player.position - INTERIOR_ORIGIN) / U - Vector2(1, 1)
	var e: Array = R.exit
	return Rect2(e[0], e[1], e[2], e[3]).has_point(pm)

func _update_prompt() -> void:
	if busy or talking:
		prompt.text = ""
		return
	var t := _near_talk()
	if t != null:
		prompt.text = "E  -  talk to %s" % t.get_meta("talk").name
		return
	if interior_type == "":
		var d := _near_door()
		if not d.is_empty():
			prompt.text = "E  -  enter %s" % d.label
			return
		var s := _near_station()
		if not s.is_empty():
			prompt.text = "E  -  ride the skytrain to %s" % _next_station(s).name
			return
		prompt.text = ""
	else:
		prompt.text = "E  -  leave" if _near_exit() else ""

func _interact() -> void:
	if talking:
		_advance_dialogue()
		return
	if busy:
		return
	var t := _near_talk()
	if t != null:
		_start_dialogue(t)
		return
	if interior_type == "":
		var d := _near_door()
		if not d.is_empty():
			_enter(d)
			return
		var s := _near_station()
		if not s.is_empty():
			_ride(s)
	elif _near_exit():
		_leave()

func _ambient_line() -> String:
	var pool: Array = D.ambient.day
	if night > 0.7:
		pool = D.ambient.night
	elif tod >= 17.0 and tod < 21.0:
		pool = D.ambient.dusk
	return pool[randi() % pool.size()]

func _start_dialogue(n: Node) -> void:
	var info: Dictionary = n.get_meta("talk")
	dlg_lines = Array(info.lines).duplicate()
	if dlg_lines.is_empty():
		dlg_lines = [_ambient_line()]
	dlg_i = 0
	dlg_target = n
	talking = true
	if n.has_method("face"):
		n.talking = true
		n.face(player.position)
	dlg_name.text = info.name + ("  -  " + info.role if info.role != "" else "")
	dlg_text.text = dlg_lines[0]
	dlg_panel.visible = true

func _advance_dialogue() -> void:
	dlg_i += 1
	if dlg_i >= dlg_lines.size():
		talking = false
		dlg_panel.visible = false
		if dlg_target != null and is_instance_valid(dlg_target) and interior_type == "":
			dlg_target.talking = false
		dlg_target = null
		return
	dlg_text.text = dlg_lines[dlg_i]

func _fade(to: float, dur: float) -> void:
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", to, dur)
	await tw.finished

func _ride(s: Dictionary) -> void:
	busy = true
	var dst := _next_station(s)
	await _fade(1.0, 0.3)
	var inward := Vector2(0, 6.0)
	if _station_horiz(dst):
		inward = Vector2(0, 6.0) if dst.z < 300 else Vector2(0, -6.0)
	else:
		inward = Vector2(-6.0, 0) if dst.x > 300 else Vector2(6.0, 0)
	player.position = wp(dst.x + inward.x, dst.z + inward.y)
	cam.reset_smoothing()
	_update_chunks(true)
	_apply_time()
	await _fade(0.0, 0.3)
	busy = false

func _enter(door: Dictionary) -> void:
	busy = true
	await _fade(1.0, 0.25)
	interior_door = door
	interior_type = door.type
	for k in loaded:
		for n in loaded[k].ents:
			if is_instance_valid(n):
				n.visible = false
	for n in cars:
		n.visible = false
	var R: Dictionary = D.interiors[interior_type]
	interior_root = Node2D.new()
	world.add_child(interior_root)
	var s := Sprite2D.new()
	s.texture = tex("scenes/int_%s.png" % interior_type)
	s.centered = false
	s.position = INTERIOR_ORIGIN
	s.z_index = -100
	interior_root.add_child(s)
	var body := StaticBody2D.new()
	interior_root.add_child(body)
	var o := INTERIOR_ORIGIN + Vector2(U, U)
	for r in R.colliders:
		add_rect(body, Rect2(o + Vector2(r[0], r[1]) * U, Vector2(r[2], r[3]) * U))
	var w: float = R.w * U
	var d: float = R.d * U
	add_rect(body, Rect2(o.x - 200, o.y - 200, w + 400, 200))
	add_rect(body, Rect2(o.x - 200, o.y + d + 2, w + 400, 200))
	add_rect(body, Rect2(o.x - 200, o.y, 200, d))
	add_rect(body, Rect2(o.x + w, o.y, 200, d))
	for npc in R.npcs:
		var p := Person.new()
		p.main = self
		p.skin = int(npc.skin)
		p.pname = npc.name
		p.talking = true
		p.position = o + Vector2(npc.x, npc.z) * U
		p.set_meta("talk", {"name": npc.name, "role": npc.role, "lines": npc.lines})
		interior_root.add_child(p)
		add_rect(body, Rect2(p.position + Vector2(-6, -5), Vector2(12, 6)))
	player.position = o + Vector2(R.spawn[0], R.spawn[1]) * U
	facing = "u"
	psprite.texture = tex("sprites/p_u0.png")
	cam.zoom = Vector2(3, 3)
	cam.limit_left = int(INTERIOR_ORIGIN.x)
	cam.limit_top = int(INTERIOR_ORIGIN.y)
	cam.limit_right = int(INTERIOR_ORIGIN.x + w + 2 * U)
	cam.limit_bottom = int(INTERIOR_ORIGIN.y + d + 2 * U)
	cam.reset_smoothing()
	_apply_time()
	await _fade(0.0, 0.25)
	busy = false

func _leave() -> void:
	busy = true
	await _fade(1.0, 0.25)
	interior_root.queue_free()
	interior_type = ""
	for k in loaded:
		for n in loaded[k].ents:
			if is_instance_valid(n):
				n.visible = true
	player.position = wp(interior_door.x, interior_door.z + 2.6)
	facing = "d"
	_set_outdoor_limits()
	cam.zoom = Vector2(2, 2)
	cam.reset_smoothing()
	_update_chunks(true)
	_apply_time()
	await _fade(0.0, 0.25)
	busy = false

# ------------------------------------------------------------------ screenshot + test modes
func _shot(name: String, frames: int = 8) -> void:
	for i in range(frames):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/%s.png" % name))
	print("SHOT ", name)

func _goto(x: float, z: float, h: float) -> void:
	player.position = wp(x, z)
	tod = h
	cam.reset_smoothing()
	_update_chunks(true)

func _capture() -> void:
	help_label.visible = false
	await get_tree().process_frame
	_goto(150, 170, 19.4)
	await _shot("a_campus_quad", 15)
	_goto(450, 150, 21.0)
	await _shot("b_tech_plaza", 15)
	_goto(430, 138, 21.0)
	await _shot("b2_tech_robot", 15)
	_goto(100, 395, 20.0)
	await _shot("c_home_terraces", 15)
	_goto(520, 480, 20.5)
	await _shot("d_lake", 15)
	_goto(300, -480, 21.0)
	await _shot("e_market_core", 15)
	_goto(300, -250, 12.0)
	await _shot("f_north_forest_day", 15)
	_goto(-100, 200, 18.8)
	await _shot("g_west_forest", 15)
	_goto(250, 635, 21.0)
	await _shot("h_waterfront", 15)
	_goto(150, 12, 22.0)
	await _shot("i_station_C1", 20)
	for door in D.doors:
		if door.id in ["familycafe", "hallProduce", "clinic", "robot"]:
			_goto(door.x, door.z + 1.0, 21.0)
			await get_tree().process_frame
			await _enter(door)
			await _shot("int_" + door.id, 12)
			await _leave()
	get_tree().quit()

func _collide_test() -> void:
	await get_tree().process_frame
	var tests := [["campus facade (north)", wp(127.5, 62), Vector2(0, -1)], ["campus stream (east)", wp(55, 100), Vector2(1, 0)],
		["west forest (west)", wp(-60, 250), Vector2(-1, 0)], ["lake (east)", wp(500, 548), Vector2(1, 0)], ["river (south)", wp(300, 660), Vector2(0, 1)],
		["void NW (north)", wp(10, 5), Vector2(0, -1)]]
	for t in tests:
		player.position = t[1]
		_update_chunks(true)
		for i in range(300):
			player.velocity = t[2] * 120.0
			player.move_and_slide()
			await get_tree().physics_frame
		print("COLLIDE ", t[0], " stopped at ", _player_m())
	player.position = wp(55, 150)
	for i in range(240):
		player.velocity = Vector2(120, 0)
		player.move_and_slide()
		await get_tree().physics_frame
	print("COLLIDE bridge crossing ends at x=", _player_m().x)
	get_tree().quit()
