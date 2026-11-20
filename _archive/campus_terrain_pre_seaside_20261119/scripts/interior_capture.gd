extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var manager=world.interiors
	for child in world.get_children():
		if child is CanvasLayer: child.visible=false
	manager.prompt.visible=false
	for index in [0,6,8,13,18,28]:
		world.player.teleport(manager.records[index].outside)
		await manager.enter(index,false)
		assert(not world.wildlife.visible and not world.breeze.visible,"Outdoor effects must stay out of interiors")
		world.player.paused=true
		world.camera.target=manager.active_room
		world.camera.zoom=0.8 if manager.active_room.get_meta("room_depth")>20 else 0.65
		world.camera.instant=true
		for i in range(30): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://screenshots/interior_%02d_20261119.png"%index)
		await manager.leave(false)
		assert(world.wildlife.visible and world.breeze.visible,"Outdoor effects must resume after exit")
	print("INTERIOR_CAPTURES_SAVED")
	await world._quit_cleanly()
