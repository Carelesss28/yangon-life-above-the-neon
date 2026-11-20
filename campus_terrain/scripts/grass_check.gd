extends SceneTree
var failures=0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool,label: String) -> void:
	print(("PASS: " if value else "FAIL: ")+label)
	if not value: failures+=1
func plantable(grass,layout,point: Vector2) -> bool:
	return grass._plantable(point.x,point.y,grass.excluded_rects,grass.excluded_routes) and grass._allowed_surface(point.x,point.y,layout.height_at(point.x,point.y))
func run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var grass=load("res://scripts/grass_system.gd").new()
	grass.excluded_rects=world.grass_exclusions
	grass.excluded_routes=world.grass_routes
	var layout=load("res://scripts/terrain_layout.gd")
	var blocks=load("res://scripts/reference_blocks.gd")
	for point in [Vector2(422.54,235),blocks.CAMPUS[0][0].get_center(),Vector2(88.03,35),Vector2(105.63,-35),layout.HILL_TRAIL[3],Vector2(layout.RESERVOIR.x,layout.RESERVOIR.y)]:
		check(not plantable(grass,layout,point),"No blades on road, plot, water, trail or fountain "+str(point))
	var point=Vector2(692,634)
	check(plantable(grass,layout,point),"Lawn grows grass")
	check(world.grass_exclusions.size()>30,"All terrain zones supply grass exclusions")
	check(world.grass_routes.size()>=layout.TRAILS.size(),"Hill trails supply grass exclusions")
	grass.free()
	print("GRASS_CHECK_COMPLETE failures=",failures)
	quit(1 if failures else 0)
