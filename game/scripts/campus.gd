extends Node2D
## The academy campus, built from game/data/campus.json: ground tiles, buildings and props,
## collisions, doors, isometric depth order, fading buildings and day/night.

const PlayerScript := preload("res://game/scripts/player.gd")
const SEE_THROUGH := preload("res://game/scripts/see_through.gdshader")
const HOLE_RADIUS := 34.0
const LAMP_LIGHT := Color(1.0, 0.82, 0.55)


class Ground extends Node2D:
	var w := 0
	var h := 0
	var cells := PackedInt32Array()
	var textures: Array[Texture2D] = []

	func _draw() -> void:
		for j in h:
			for i in w:
				var t := cells[j * w + i]
				if t >= 0:
					draw_texture(textures[t], Vector2((i - j) * 16 - 16, (i + j) * 8))


var data: Dictionary
var map_size: Vector2i
var ground: Ground
var world: Node2D
var player: CharacterBody2D
var statics: Array[Dictionary] = []
var lights: Array[Node2D] = []


func _ready() -> void:
	data = Game.layout
	map_size = Vector2i(data["size"][0], data["size"][1])
	Game.show_title("Academy campus")
	_build_ground()
	world = Node2D.new()
	add_child(world)
	for o in data["objects"]:
		_add_object(o)
	_sort_statics()
	_add_border()
	_spawn_player()


func _process(_delta: float) -> void:
	_update_depth()
	_update_light()
	_update_doors()


# --- ground ---------------------------------------------------------------------------------

func _build_ground() -> void:
	ground = Ground.new()
	ground.z_index = -100
	ground.w = map_size.x
	ground.h = map_size.y
	ground.cells.resize(map_size.x * map_size.y)
	ground.cells.fill(-1)
	var sets := {}   # tile set name -> list of texture indices
	for name in Game.tiles:
		var ids: Array[int] = []
		for path in Game.tiles[name]:
			ground.textures.append(load(path))
			ids.append(ground.textures.size() - 1)
		sets[name] = ids
	for fill in data["ground"]:
		var ids: Array = sets[fill["tiles"]]
		var r: Array = fill["rect"]
		for j in range(int(r[1]), int(r[3])):
			for i in range(int(r[0]), int(r[2])):
				if i < map_size.x and j < map_size.y:
					var hsh := absi(i * 73856093 ^ j * 19349663)
					ground.cells[j * map_size.x + i] = ids[hsh % ids.size()]
	add_child(ground)


# --- objects --------------------------------------------------------------------------------

func _add_object(o: Dictionary) -> void:
	var p: Dictionary = Game.pieces[o["piece"]]
	var front := Vector2(o["at"][0], o["at"][1])
	var fp := Vector2(p["footprint"][0], p["footprint"][1])
	var rect := Rect2(front - fp, fp)
	var anchor := Vector2(p["anchor"][0], p["anchor"][1])

	var node := Node2D.new()
	node.position = Iso.to_screen(front)
	var spr := Sprite2D.new()
	spr.texture = load(p["texture"])
	spr.centered = false
	spr.offset = -anchor
	if p["kind"] == "building":
		var see := ShaderMaterial.new()
		see.shader = SEE_THROUGH
		see.set_shader_parameter("hole_radius", 0.0)
		spr.material = see
	node.add_child(spr)
	var glow: Sprite2D = null
	if p["glow"] != "":
		glow = Sprite2D.new()
		glow.texture = load(p["glow"])
		glow.centered = false
		glow.offset = -anchor
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		glow.material = mat
		node.add_child(glow)
	world.add_child(node)

	# collision on the footprint, leaving archways open
	var body := StaticBody2D.new()
	var y0 := rect.position.y
	var cuts: Array = o.get("gaps", [])
	for g in cuts + [[rect.end.y, rect.end.y]]:
		var seg := Rect2(rect.position.x, y0, rect.size.x, float(g[0]) - y0)
		if seg.size.y > 0.05:
			var poly := CollisionPolygon2D.new()
			poly.polygon = Iso.rect_corners(seg)
			body.add_child(poly)
		y0 = float(g[1])
	world.add_child(body)

	var size := Vector2(p["size"][0], p["size"][1])
	statics.append({
		"node": node, "sprite": spr, "glow": glow, "rect": rect, "kind": p["kind"],
		"screen": Rect2(node.position - anchor, size), "order": 0, "anchor": anchor,
		# buildings keep their pixels so fading can test what actually covers the player
		"image": spr.texture.get_image() if p["kind"] == "building" else null,
	})
	if o["piece"] == "heritage_lamp_post":
		_add_lamp_light(node.position)


func _add_lamp_light(at: Vector2) -> void:
	var tex := GradientTexture2D.new()
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 96
	tex.height = 48
	var grad := Gradient.new()
	grad.set_color(0, Color(LAMP_LIGHT, 0.55))
	grad.set_color(1, Color(LAMP_LIGHT, 0.0))
	tex.gradient = grad
	var pool := Sprite2D.new()
	pool.texture = tex
	pool.position = at
	pool.z_index = -50
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	pool.material = mat
	add_child(pool)
	lights.append(pool)


## Order the static pieces so each is drawn after everything behind it.
func _sort_statics() -> void:
	var n := statics.size()
	var indeg := PackedInt32Array()
	indeg.resize(n)
	var after: Array = []
	for i in n:
		after.append([])
	for i in n:
		for j in n:
			if i != j and Iso.behind(statics[i]["rect"], statics[j]["rect"]):
				after[i].append(j)
				indeg[j] += 1
	var ready_list: Array[int] = []
	for i in n:
		if indeg[i] == 0:
			ready_list.append(i)
	var order := 0
	var done := {}
	while not ready_list.is_empty():
		ready_list.sort_custom(func(a, b): return _depth_key(a) < _depth_key(b))
		var i: int = ready_list.pop_front()
		done[i] = true
		statics[i]["order"] = order
		order += 1
		for j in after[i]:
			indeg[j] -= 1
			if indeg[j] == 0:
				ready_list.append(j)
	for i in n:   # anything left in a cycle goes last, front-most first
		if not done.has(i):
			statics[i]["order"] = order
			order += 1
	for s in statics:
		s["node"].z_index = s["order"] * 2


func _depth_key(i: int) -> float:
	var r: Rect2 = statics[i]["rect"]
	return r.end.x + r.end.y


func _add_border() -> void:
	var body := StaticBody2D.new()
	var poly := CollisionPolygon2D.new()
	poly.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
	var r := Rect2(Vector2.ZERO, Vector2(map_size))
	var c := Iso.rect_corners(r)
	c.append(c[0])
	poly.polygon = c
	body.add_child(poly)
	add_child(body)


func _spawn_player() -> void:
	player = CharacterBody2D.new()
	player.set_script(PlayerScript)
	var start := Vector2(data["player_start"][0], data["player_start"][1])
	if Game.campus_spawn.x >= 0.0:
		start = Game.campus_spawn
		Game.campus_spawn = Vector2(-1, -1)
	player.position = Iso.to_screen(start)
	world.add_child(player)
	var w := float(map_size.x)
	var h := float(map_size.y)
	player.set_camera_limits(Rect2(Vector2(-h * 16.0, -160.0), Vector2((w + h) * 16.0, (w + h) * 8.0 + 200.0)))


# --- per frame ------------------------------------------------------------------------------

func _update_depth() -> void:
	var pm := Iso.to_map(player.position)
	var prect := Rect2(pm - Vector2(0.35, 0.35), Vector2(0.35, 0.35))
	var pscreen := Rect2(player.position + Vector2(-16, -46), Vector2(32, 48))
	var z := -1
	for s in statics:
		var overlaps: bool = s["screen"].intersects(pscreen)
		var hide := false
		if overlaps:
			if Iso.behind(s["rect"], prect):
				z = maxi(z, s["order"] * 2 + 1)
			elif Iso.behind(prect, s["rect"]) and s["kind"] == "building":
				hide = _covers_player(s)
		if s["kind"] == "building":
			var mat: ShaderMaterial = s["sprite"].material
			var r: float = mat.get_shader_parameter("hole_radius")
			mat.set_shader_parameter("hole_radius", lerpf(r, HOLE_RADIUS if hide else 0.0, 0.25))
			mat.set_shader_parameter("hole_center", player.global_position + Vector2(0, -18))
	player.z_index = z


## True if the building's opaque pixels cover part of the player's body.
func _covers_player(s: Dictionary) -> bool:
	var img: Image = s["image"]
	var base: Vector2 = player.position - s["node"].position + s["anchor"]
	for off in [Vector2(0, -6), Vector2(0, -16), Vector2(0, -28), Vector2(-6, -18), Vector2(6, -18)]:
		var q := Vector2i(base + off)
		if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height():
			if img.get_pixelv(q).a > 0.5:
				return true
	return false


func _update_light() -> void:
	var amb := Game.ambient()
	var night := Game.night_factor()
	ground.modulate = amb
	for s in statics:
		s["sprite"].self_modulate = amb
		if s["glow"] != null:
			s["glow"].modulate = Color(1, 1, 1, 0.25 + 0.75 * night)
	for l in lights:
		l.modulate.a = night
	player.sprite.self_modulate = amb


func _update_doors() -> void:
	var pm := Iso.to_map(player.position)
	var best: Dictionary = {}
	var best_d := 1.8
	for d in data["doors"]:
		var dist := pm.distance_to(Vector2(d["at"][0], d["at"][1]))
		if dist < best_d:
			best_d = dist
			best = d
	if best.is_empty():
		Game.show_prompt("")
		return
	if best["room"] == "":
		Game.show_prompt(best["name"])
		return
	Game.show_prompt("E: enter " + best["name"])
	if Input.is_action_just_pressed("interact"):
		Game.go_to_room(best["room"])
