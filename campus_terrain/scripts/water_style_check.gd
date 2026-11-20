extends SceneTree
const Layout=preload("res://scripts/terrain_layout.gd")
var failures=0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool,message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok: failures+=1

func run() -> void:
	for x in range(-290,611,25):
		for north in [true,false]:
			var edge=Layout.river_water_edge(x,north)
			check(absf(Layout.river_height(x,edge)-Layout.RIVER_WATER_Y)<0.001,"River surface reaches its actual bank at "+str(x))
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var river=world.get_node("ContinuousSouthRiver")
	var lake=world.get_node("DistrictLake")
	check(river.material_override.get_shader_parameter("water_kind")==1,"River uses the flowing stylized material")
	check(lake.material_override.get_shader_parameter("water_kind")==2,"Lake uses gentle pool ripples")
	check(lake.scale.x==49 and lake.scale.z==46,"Lake reaches the shoreline instead of stopping short")
	var arrays=river.mesh.surface_get_arrays(0)
	check(arrays[Mesh.ARRAY_TEX_UV].size()==arrays[Mesh.ARRAY_VERTEX].size(),"Flow and bank coordinates cover the entire river")
	var rocks=get_nodes_in_group("stylized_river_stones")
	check(rocks.size()==12,"Twelve shoreline stones with animated foam rings")
	if DisplayServer.get_name()!="headless":
		world.player.paused=true
		world.camera.set_process(false)
		for child in world.get_children():
			if child is CanvasLayer: child.visible=false
		for owner in [world.interiors,world.skytrain]:
			for child in owner.get_children():
				if child is CanvasLayer: child.visible=false
		for label in world.labels: label.visible=false
		for daylight in [true,false]:
			if world.night==daylight: world.toggle_night()
			for entry in [{"name":"river","at":Vector3(112.68,-1.5,Layout.river_north_bank(160)+35),"offset":Vector3(21.13,65,70)}, {"name":"lake","at":Vector3(387.32,-2.25,548),"offset":Vector3(24.65,65,70)}, {"name":"creek","at":Vector3(Layout.north_stream_x(-65),Layout.north_water_y(-65),-65),"offset":Vector3(12,26,25)}, {"name":"canal","at":Vector3(45.77,2,150),"offset":Vector3(6,18,16)}]:
				world.camera.position=entry.at+entry.offset
				world.camera.look_at(entry.at)
				for i in range(35): await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://screenshots/stylized_water_%s_%s_20261119.png"%[entry.name,"day" if daylight else "dusk"])
	print("WATER_STYLE_CHECK ","PASS" if failures==0 else "FAIL"," failures=",failures)
	await world._quit_cleanly()
