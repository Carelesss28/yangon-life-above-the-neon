extends RefCounted
## Reviewed prototype copies; production parts/interiors are still pending.
const Layout = preload("res://scripts/terrain_layout.gd")
const PLACEMENTS = [
	{"piece":"futuristic_tower", "centre":Vector2(89.79,37.5), "width":28.0, "plot":Rect2(77.46,20,24.65,35)},
	{"piece":"neo_utopian_city", "centre":Vector2(369.72,117.5), "width":36.0, "plot":Rect2(352.11,95,35.21,45)}
]

func setup(world) -> void:
	var group = Node3D.new()
	group.name = "DownloadedBuildings"
	world.add_child(group)
	for entry in PLACEMENTS:
		var scene = load("res://models/downloaded_buildings/%s.glb" % entry.piece) as PackedScene
		var model = scene.instantiate() as Node3D
		var bounds: AABB = world._scene_bounds(model)
		var factor: float = entry.width / maxf(bounds.size.x, bounds.size.z)
		var centre: Vector2 = entry.centre
		var ground = Layout.height_at(centre.x,centre.y)+0.08
		var body = StaticBody3D.new()
		body.name = entry.piece
		group.add_child(body)
		body.position = Vector3(centre.x,ground,centre.y)
		body.add_child(model)
		model.scale = Vector3.ONE*factor
		model.position = -Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*factor
		# Simple exterior collision keeps players out of unfinished interiors.
		var collider = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = bounds.size*factor
		collider.shape = box
		collider.position.y = box.size.y/2
		body.add_child(collider)
		world.grass_exclusions.append(entry.plot)
		print("BUILDING_PLACED: ",entry.piece," size=",box.size," at=",body.position)
