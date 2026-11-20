extends SceneTree
var failures=0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool,message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok: failures+=1

func run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var lighting=world.city_lighting
	check(world.night,"Starts at blue hour")
	for zone in ["shopfronts","window_spill","market_halls","rooftop_cafes","forest_paths","lake_walk","retaining_wall","skytrain_platforms"]:
		check(lighting.zones.get(zone,0)>0,"Reference lighting covers "+zone)
	check(get_nodes_in_group("city_window_panels").size()>500,"Warm window panes on front, back and side facades")
	check(lighting.materials.size()>=6,"Windows have varied amber, warm-white and cool accents")
	var energy=0.0
	for light in world.lamps: energy+=light.light_energy
	check(energy>500,"Street and building lights cast real illumination")
	world.toggle_night()
	var all_off=true
	for light in world.lamps:
		if light.light_energy!=0: all_off=false
	check(all_off,"Daylight switches off exterior lamps")
	var emission_off=true
	for entry in lighting.materials:
		if entry.material.emission_enabled: emission_off=false
	check(emission_off,"Daylight switches off window and lamp emission")
	world.toggle_night()
	var restored=0.0
	for light in world.lamps: restored+=light.light_energy
	check(absf(energy-restored)<0.01,"Night restores authored light intensities")
	if DisplayServer.get_name()!="headless" and failures==0:
		world.player.paused=true
		world.skytrain.set_physics_process(false)
		for child in world.get_children():
			if child is CanvasLayer: child.visible=false
		for owner in [world.interiors,world.skytrain,world.buses]:
			for child in owner.get_children():
				if child is CanvasLayer: child.visible=false
		for label in world.labels: label.visible=false
		var portrait=SubViewport.new()
		portrait.size=Vector2i(1024,1536)
		portrait.world_3d=world.get_world_3d()
		portrait.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		portrait.msaa_3d=Viewport.MSAA_2X
		root.add_child(portrait)
		var view=Camera3D.new()
		portrait.add_child(view)
		view.current=true
		view.projection=Camera3D.PROJECTION_ORTHOGONAL
		view.size=1450
		view.far=6000
		view.position=Vector3(157,1500,1450)
		view.look_at(Vector3(157,0,40))
		world.sun.directional_shadow_max_distance=3000
		for i in range(50): await process_frame
		await RenderingServer.frame_post_draw
		var overview=portrait.get_texture().get_image()
		overview.save_png("res://screenshots/low_poly_reference_full.png")
		portrait.queue_free()
		world.sun.directional_shadow_max_distance=500
		world.camera.set_process(false)
		for entry in [{"name":"home","at":Vector3(150,5,465),"offset":Vector3(55,180,165)}, {"name":"market","at":Vector3(300,24,-520),"offset":Vector3(65,290,245)}, {"name":"campus","at":Vector3(150,5,130),"offset":Vector3(40,175,160)}, {"name":"tech","at":Vector3(465,5,140),"offset":Vector3(40,175,160)}, {"name":"lake","at":Vector3(462,3,462),"offset":Vector3(35,175,160)}, {"name":"forest","at":Vector3(355,22,-173),"offset":Vector3(35,105,110)}, {"name":"riverfront","at":Vector3(150,4,657),"offset":Vector3(30,210,200)}]:
			world.player.teleport(entry.at+Vector3(0,0,20))
			world.camera.position=entry.at+entry.offset
			world.camera.look_at(entry.at)
			for i in range(35): await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://screenshots/low_poly_reference_%s.png"%entry.name)
	print("CITY_LIGHTING_CHECK ","PASS" if failures==0 else "FAIL"," lights=",world.lamps.size()," new=",lighting.added_lights.size()," failures=",failures)
	await world._quit_cleanly()
