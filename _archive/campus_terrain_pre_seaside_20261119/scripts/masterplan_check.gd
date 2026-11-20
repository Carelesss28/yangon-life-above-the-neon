extends SceneTree
const Roads=preload("res://scripts/road_layout.gd")
var failures=0

func check(ok: bool,message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok: failures+=1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var adjacency={}
	for name in Roads.NODES: adjacency[name]=[]
	for edge in Roads.EDGES:
		adjacency[edge[0]].append(edge[1])
		adjacency[edge[1]].append(edge[0])
		var a: Vector3=Roads.NODES[edge[0]]
		var b: Vector3=Roads.NODES[edge[1]]
		check(absf(b.y-a.y)/Vector2(b.x-a.x,b.z-a.z).length()<=0.1,"Road grade "+str(edge))
	for name in adjacency: check(adjacency[name].size()>=2,"No dead end "+name)
	var visited={}
	var pending=["c"]
	while not pending.is_empty():
		var current=pending.pop_back()
		if visited.has(current): continue
		visited[current]=true
		pending.append_array(adjacency[current])
	check(visited.size()==Roads.NODES.size(),"All district roads connect")
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var buildings=world.get_node("PrototypeBuildings")
	check(buildings.get_child_count()>=45,"Full-town building infill")
	for building in buildings.get_children():
		var plot: Rect2=building.get_meta("reserved_plot")
		var bounds: AABB=world._scene_bounds(building)
		check(plot.grow(1).encloses(Rect2(Vector2(bounds.position.x,bounds.position.z),Vector2(bounds.size.x,bounds.size.z))),str(building.name)+" inside its plot")
	var dressing=world.get_node("MasterplanDressing")
	check(dressing.get_meta("forest_trees")>1500,"Dense broadleaf forest")
	check(dressing.get_meta("palms")>100,"Palm-lined streets and promenade")
	check(dressing.get_meta("parked_cars")==8,"Parked vehicles establish human scale")
	if DisplayServer.get_name()!="headless" and failures==0:
		world.player.paused=true
		for child in world.get_children():
			if child is CanvasLayer: child.visible=false
		for label in world.labels: label.visible=false
		# Offscreen portrait render avoids desktop/window size clamping.
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
		for i in range(70): await process_frame
		await RenderingServer.frame_post_draw
		portrait.get_texture().get_image().save_png("res://screenshots/masterplan_full_20261119.png")
		portrait.queue_free()
		world.sun.directional_shadow_max_distance=500
		world.camera.set_process(false)
		for entry in [{"name":"home","at":Vector3(150,5,460)},{"name":"market","at":Vector3(300,24,-540)},{"name":"lake","at":Vector3(490,2,480)},{"name":"forest","at":Vector3(270,20,-130)},{"name":"waterfront","at":Vector3(150,5,655)}]:
			world.player.teleport(entry.at+Vector3(0,0,25))
			world.camera.position=entry.at+Vector3(85,140,165)
			world.camera.look_at(entry.at)
			for i in range(35): await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://screenshots/masterplan_%s_20261119.png"%entry.name)
	print("MASTERPLAN_CHECK ","PASS" if failures==0 else "FAIL"," failures=",failures)
	await world._quit_cleanly()
