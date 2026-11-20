extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var manager=world.interiors
	var service=world.skytrain
	service.set_physics_process(false)
	world.player.test_mode=true
	world.player.teleport(manager.records[0].outside+Vector3(0,0,2))
	world.camera.zoom=0.7
	world.camera.instant=true
	for i in range(40): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://screenshots/building_entry_fixed_20261119.png")
	manager.action_button.pressed.emit()
	for i in range(50): await process_frame
	assert(manager.inside,"The visible Enter button must enter the building")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://screenshots/building_entered_fixed_20261119.png")
	await manager.leave(false)
	for child in world.get_children():
		if child is CanvasLayer: child.visible=false
	manager.prompt.visible=false
	manager.action_button.visible=false
	service.prompt.visible=false
	service.advance(1.5)
	world.camera.set_process(false)
	for entry in [{"name":"campus_station","index":0},{"name":"interchange","index":1},{"name":"market_station","index":7}]:
		var target: Vector3=service.stations[entry.index].platform
		world.camera.position=target+Vector3(30,32,40)
		world.camera.look_at(target)
		for i in range(30): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://screenshots/skytrain_%s_20261119.png"%entry.name)
	world.player.teleport(service.stations[0].platform)
	assert(service.board(0))
	world.camera.set_process(true)
	for i in range(180): service.advance(0.1)
	for i in range(30): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://screenshots/skytrain_ride_20261119.png")
	print("ENTRANCE_AND_LOWERED_CAPTURE_PASS")
	await world._quit_cleanly()
