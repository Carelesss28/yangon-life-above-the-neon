extends SceneTree
var failures=0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool,message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok: failures+=1

func frames(count: int) -> void:
	for i in range(count): await physics_frame

func run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await frames(5)
	var manager=world.interiors
	check(manager.records.size()*2>=manager.total_buildings,"At least half of all building/shelter roots are explorable")
	check(manager.records.size()==manager.total_buildings,"Every building has a furnished interior")
	var player=world.player
	player.test_mode=true
	var themes={}
	for index in range(manager.records.size()):
		player.test_direction=Vector3.ZERO
		player.teleport(manager.records[index].outside)
		await frames(5)
		var outside=player.global_position
		var entered: bool=await manager.enter(index,false)
		await frames(12)
		check(entered and manager.inside and player.interior_mode,"Enter "+manager.records[index].title)
		if index==0:
			var before_navigation=player.position
			world.visit_section(1)
			check(player.position==before_navigation,"Outdoor area shortcuts cannot teleport out of an interior")
		check(player.is_on_floor(),"Interior has a solid floor")
		check(manager.active_room.get_meta("furniture_count")>=30,"Furnished for purpose")
		themes[manager.active_room.get_meta("theme")]=true
		var start=player.position
		player.test_direction=Vector3(0,0,-1)
		await frames(95)
		player.test_direction=Vector3.ZERO
		await frames(5)
		check(start.z-player.position.z>7.0,"Walkable central aisle")
		check(player.position.y>-181 and player.position.y<-179,"Stays inside without world-boundary reset")
		if DisplayServer.get_name()!="headless" and index in [0,6,8,13,18,28]:
			player.teleport(manager.exit_position+Vector3(0,0,-2.5))
			for child in world.get_children():
				if child is CanvasLayer: child.visible=false
			manager.prompt.visible=false
			world.camera.target=manager.active_room
			world.camera.zoom=0.8 if manager.active_room.get_meta("room_depth")>20 else 0.65
			world.camera.instant=true
			for i in range(30): await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://screenshots/interior_%02d_20261119.png"%index)
		var exited: bool=await manager.leave(false)
		check(exited and not manager.inside and not player.interior_mode,"Exit restores outdoor mode")
		check(player.position.distance_to(outside)<0.05,"Exit returns to the same exterior position")
		await frames(3)
	check(themes.size()>=8,"Different furniture layouts for distinct building purposes")
	# Exercise the actual E key path and animated fade, rather than only direct calls.
	player.test_direction=Vector3.ZERO
	player.teleport(manager.records[0].outside)
	await frames(5)
	var event=InputEventKey.new()
	event.physical_keycode=KEY_E
	event.pressed=true
	Input.parse_input_event(event)
	await frames(1)
	var before_fade_navigation=player.position
	world.visit_section(2)
	check(player.position==before_fade_navigation,"Area navigation is blocked during a fade")
	await frames(79)
	check(manager.inside and not manager.busy,"E enters through a completed fade")
	if manager.inside:
		player.teleport(manager.exit_position)
		await frames(3)
		Input.parse_input_event(event)
		await frames(80)
		check(not manager.inside and not manager.busy,"E exits through a completed fade")
	print("INTERIOR_CHECK ","PASS" if failures==0 else "FAIL"," interiors=",manager.records.size(),"/",manager.total_buildings," themes=",themes.size()," failures=",failures)
	await world._quit_cleanly()
