extends SceneTree
var failures=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+text)
	if not ok: failures+=1
func run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var animals=world.wildlife
	animals.set_process(false)
	check(animals.creatures.size()==39,"39 animals spawned")
	for c in animals.creatures:
		var bounds=world._scene_bounds(c.model)
		check(bounds.size.length()<2.0,"Correct model scale "+str(c.kind))
	var moved={"cat":false,"bird":false,"duck":false,"butterfly":false}
	for focus in [Vector2(97.89,174),Vector2(387.32,548),Vector2(64.79,165),Vector2(100,252),Vector2(98.59,465),Vector2(197.18,-400)]:
		world.player.teleport(Vector3(focus.x,5,focus.y))
		for i in range(800): animals._process(0.025)
		for c in animals.creatures:
			if c.point.distance_to(c.home)>0.3: moved[c.kind]=true
	var safe=true
	var wet_ducks=true
	for c in animals.creatures:
		if not c.model.position.is_finite(): safe=false
		if c.kind=="cat" and not world.Layout.Roads.sample(c.point.x,c.point.y).is_empty(): safe=false
		if c.kind=="duck" and world.Layout.lake_distance(c.point.x,c.point.y)>0.9: wet_ducks=false
	check(safe,"Finite animal positions and cats off vehicle roads")
	check(wet_ducks,"Ducks stay inside lake")
	for kind in moved: check(moved[kind],kind+" moves within habitat")
	world.night=true
	world.player.teleport(Vector3(100,0,252))
	animals._process(0.1)
	var hidden=true
	for c in animals.creatures:
		if c.kind=="butterfly" and c.model.visible: hidden=false
	check(hidden,"Butterflies rest out of sight at night")
	print("WILDLIFE_CHECK_COMPLETE failures=",failures)
	quit(1 if failures else 0)
