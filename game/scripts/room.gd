extends Node2D
## A walk-in interior (framework section 6), built from campus.json "rooms".
## Room coordinates are pixels of the room image.

const PlayerScript := preload("res://game/scripts/player.gd")

var room: Dictionary
var player: CharacterBody2D
var pads: Array[Node2D] = []


class Pad extends Node2D:
	## Glowing floor pad marking a lift.
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var a := 0.45 + 0.25 * sin(t * 3.0)
		for k in 3:
			var pts := PackedVector2Array()
			var rx := 14.0 - k * 4.0
			for i in 20:
				var ang := TAU * i / 20.0
				pts.append(Vector2(cos(ang) * rx, sin(ang) * rx * 0.5))
			draw_colored_polygon(pts, Color(0.44, 0.93, 0.96, a * (0.35 + k * 0.2)))


func _ready() -> void:
	room = Game.layout["rooms"][Game.next_room]
	Game.show_title(room["title"])
	var p: Dictionary = Game.pieces[room["piece"]]

	var spr := Sprite2D.new()
	spr.texture = load(p["texture"])
	spr.centered = false
	spr.z_index = -10
	add_child(spr)
	if p["glow"] != "":
		var glow := Sprite2D.new()
		glow.texture = load(p["glow"])
		glow.centered = false
		glow.z_index = -9
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		glow.material = mat
		glow.modulate.a = 0.6
		add_child(glow)

	# walls: the player stays on the floor
	var body := StaticBody2D.new()
	var poly := CollisionPolygon2D.new()
	poly.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
	var floor_pts := PackedVector2Array()
	for pt in room["floor"]:
		floor_pts.append(Vector2(pt[0], pt[1]))
	floor_pts.append(floor_pts[0])
	poly.polygon = floor_pts
	body.add_child(poly)
	add_child(body)

	for e in room["exits"]:
		if e.get("pad", false):
			var pad := Pad.new()
			pad.position = Vector2(e["at"][0], e["at"][1])
			pad.z_index = -5
			add_child(pad)

	player = CharacterBody2D.new()
	player.set_script(PlayerScript)
	var spawn := Vector2(room["spawn"][0], room["spawn"][1])
	if Game.room_spawn.x >= 0.0:
		spawn = Game.room_spawn
		Game.room_spawn = Vector2(-1, -1)
	player.position = spawn
	add_child(player)
	# small rooms: hold the camera on the room's centre
	player.camera.enabled = false
	var cam := Camera2D.new()
	cam.position = spr.texture.get_size() * 0.5
	add_child(cam)
	cam.make_current()


func _process(_delta: float) -> void:
	var best: Dictionary = {}
	var best_d := 16.0
	for e in room["exits"]:
		var d := player.position.distance_to(Vector2(e["at"][0], e["at"][1]))
		if d < best_d:
			best_d = d
			best = e
	if best.is_empty():
		Game.show_prompt("")
		return
	Game.show_prompt("E: " + best["name"])
	if Input.is_action_just_pressed("interact"):
		if best["to"] == "campus":
			Game.go_to_campus(Vector2(best["spawn"][0], best["spawn"][1]))
		else:
			var at: Array = best.get("spawn_at", [-1, -1])
			Game.go_to_room(best["to"], Vector2(at[0], at[1]))
