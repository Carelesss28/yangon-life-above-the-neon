extends SceneTree
var failures=0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok: failures+=1

func run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var buildings=world.get_node("PrototypeBuildings")
	var halls=0
	var references=0
	for building in buildings.get_children():
		var plot: Rect2=building.get_meta("reserved_plot")
		var bounds: AABB=world._scene_bounds(building)
		check(plot.grow(1).encloses(Rect2(Vector2(bounds.position.x,bounds.position.z),Vector2(bounds.size.x,bounds.size.z))),str(building.name)+" stays within reserved plot")
		if building.get_meta("architectural_style","")=="curved_glass_market":
			halls+=1
			check(building.has_node("roof/CurvedGlassRoof"),"Market has a curved mesh roof")
		if building.has_meta("reference_image"): references+=1
	check(halls==5,"Five curved glass market halls")
	check(references>=20,"Reference architecture throughout town")
	check(world.night,"Starts at reference blue hour")
	check(world.lamps.any(func(light): return light.light_energy>0),"Real-time warm lights active")
	if DisplayServer.get_name()!="headless" and failures==0:
		world.player.paused=true
		world.camera.set_process(false)
		for entry in [{"name":"campus","at":Vector3(102.11,7,70),"offset":Vector3(45.77,110,130)}, {"name":"home","at":Vector3(71.13,12,482),"offset":Vector3(28.17,55,70)}, {"name":"tech","at":Vector3(323.94,7,150),"offset":Vector3(49.3,115,140)}, {"name":"market","at":Vector3(211.27,23,-550),"offset":Vector3(66.9,165,190)}, {"name":"market_close","at":Vector3(171.13,24,-562),"offset":Vector3(31.69,55,80)}]:
			world.camera.position=entry.at+entry.offset
			world.camera.look_at(entry.at)
			world.player.teleport(entry.at+Vector3(0,0,30))
			for i in range(35): await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://screenshots/reference_%s_20261119.png" % entry.name)
	print("REFERENCE_BUILDING_CHECK ","PASS" if failures==0 else "FAIL"," roots=",buildings.get_child_count()," failures=",failures)
	await world._quit_cleanly()
