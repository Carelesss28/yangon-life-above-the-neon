extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var service=world.skytrain
	service.set_physics_process(false)
	world.player.paused=true
	world.camera.set_process(false)
	for child in world.get_children():
		if child is CanvasLayer: child.visible=false
	world.interiors.prompt.visible=false
	service.prompt.visible=false
	for i in range(15): service.advance(0.1)
	for entry in [{"name":"campus_station","at":service.stations[0].platform,"offset":Vector3(17.61,32,40)},{"name":"interchange","at":service.stations[1].platform,"offset":Vector3(28.17,45,50)},{"name":"market_station","at":service.stations[7].platform,"offset":Vector3(24.65,40,48)}]:
		world.camera.position=entry.at+entry.offset
		world.camera.look_at(entry.at)
		for j in range(25): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://screenshots/skytrain_%s_20261119.png"%entry.name)
	world.player.paused=false
	world.player.teleport(service.stations[0].platform)
	assert(service.board(0))
	world.camera.set_process(true)
	for i in range(180): service.advance(0.1)
	for j in range(25): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://screenshots/skytrain_ride_20261119.png")
	service.route_panel.visible=true
	for j in range(35): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://screenshots/skytrain_line_map_20261119.png")
	print("SKYTRAIN_CAPTURE_PASS")
	await world._quit_cleanly()
