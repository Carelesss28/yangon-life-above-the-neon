extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var service=world.buses
	service.set_physics_process(false)
	world.skytrain.set_physics_process(false)
	world.player.paused=true
	world.camera.set_process(false)
	for owner in [world,world.interiors,world.skytrain,service]:
		for child in owner.get_children():
			if child is CanvasLayer: child.visible=false
	var bus: Dictionary=service.vehicles[0]
	bus.distance=service.routes.B1.stops[0].distance
	bus.current_stop=0
	bus.next_stop=1
	bus.dwell=7
	bus.door_ratio=1
	service.pose(bus)
	var target: Vector3=bus.root.position
	world.camera.position=target+Vector3(20,18,24)
	world.camera.look_at(target+Vector3.UP*1.5)
	for i in range(30): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://screenshots/regular_bus_stop_20261119.png")
	print("BUS_CAPTURE_PASS")
	await world._quit_cleanly()
