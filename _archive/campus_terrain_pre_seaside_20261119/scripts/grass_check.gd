extends SceneTree
var failures=0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool,label: String) -> void:
	print(("PASS: " if value else "FAIL: ")+label)
	if not value: failures+=1
func run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var grass=load("res://scripts/grass_system.gd").new()
	grass.excluded_rects=world.grass_exclusions
	grass.excluded_routes=world.grass_routes
	var layout=load("res://scripts/terrain_layout.gd")
	for point in [Vector2(150,295),Vector2(125,35),Vector2(550,548),Vector2(150,-35),Vector2(200,655),Vector2(200,layout.river_north_bank(200)-11),Vector2(150,140)]:
		check(not grass._allowed(point.x,point.y,layout.height_at(point.x,point.y)),"No blades on road, plot, water, trail or fountain "+str(point))
	var point=Vector2(140,249)
	check(grass._allowed(point.x,point.y,layout.height_at(point.x,point.y)),"Campus lawn grows grass")
	check(world.grass_exclusions.size()>30,"All terrain zones supply grass exclusions")
	check(world.grass_routes.size()>10,"Forest and waterfront routes supply grass exclusions")
	grass.free()
	print("GRASS_CHECK_COMPLETE failures=",failures)
	quit(1 if failures else 0)
