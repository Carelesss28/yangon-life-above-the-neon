extends SceneTree
## Seaside town regression check: plan integrity, transport running, and real player walks.
## Run: godot --headless --fixed-fps 60 --path . --script res://scripts/town_check.gd
const Layout=preload("res://scripts/terrain_layout.gd")
const Roads=preload("res://scripts/road_layout.gd")
var failures=0
var world

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in range(count): await physics_frame

func check(ok: bool,message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok: failures+=1

func walk(label: String,points: Array) -> void:
	# Steer the real player body through waypoints; fail if it stops making progress.
	var player=world.player
	var first: Vector2=points[0]
	player.teleport(Vector3(first.x,Layout.height_at(first.x,first.y)+0.2,first.y))
	await frames(10)
	var ok=true
	for i in range(1,points.size()):
		var target: Vector2=points[i]
		var best=INF
		var stalled=0
		var budget=int(Vector2(player.position.x,player.position.z).distance_to(target)/0.1*1.6)+120
		for tick in range(budget):
			var here=Vector2(player.position.x,player.position.z)
			var d=here.distance_to(target)
			if d<1.6: break
			if d<best-0.05:
				best=d
				stalled=0
			else:
				stalled+=1
			if stalled>90: break
			player.test_direction=Vector3(target.x-here.x,0,target.y-here.y).normalized()
			await physics_frame
		var reached=Vector2(player.position.x,player.position.z).distance_to(target)<2.0
		if not reached:
			ok=false
			print("   stuck near ",player.position," heading for ",target)
			var space=player.get_world_3d().direct_space_state
			var dir=Vector3(target.x-player.position.x,0,target.y-player.position.z).normalized()
			for h in [0.05,0.15,0.3,1.0]:
				var q=PhysicsRayQueryParameters3D.create(player.global_position+Vector3.UP*h,player.global_position+Vector3.UP*h+dir*2.0)
				q.exclude=[player.get_rid()]
				var hit=space.intersect_ray(q)
				if hit: print("   blocked at h=",h," by ",hit.collider.get_path()," at ",hit.position," normal ",hit.normal)
			var down=PhysicsRayQueryParameters3D.create(player.global_position+Vector3.UP*1.0,player.global_position+Vector3.DOWN*1.0)
			down.exclude=[player.get_rid()]
			var floor_hit=space.intersect_ray(down)
			if floor_hit: print("   standing on ",floor_hit.collider.get_path()," normal ",floor_hit.normal," on_floor=",player.is_on_floor()," vel=",player.velocity)
			for c in range(player.get_slide_collision_count()):
				var col=player.get_slide_collision(c)
				print("   slide collision ",col.get_collider().get_path() if col.get_collider() else "?"," normal ",col.get_normal()," at ",col.get_position())
			var probe=PhysicsShapeQueryParameters3D.new()
			var sphere=SphereShape3D.new()
			sphere.radius=0.6
			probe.shape=sphere
			probe.collision_mask=0xFFFFFFFF
			probe.transform=Transform3D(Basis(),player.global_position+Vector3.UP*0.9+dir*0.6)
			probe.exclude=[player.get_rid()]
			for r in space.intersect_shape(probe,8): print("   overlaps ",r.collider.get_path())
			break
	player.test_direction=Vector3.ZERO
	check(ok,"Walk: "+label)

func run() -> void:
	world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await frames(5)
	world.player.test_mode=true
	# Plan integrity.
	var degree={}
	for key in Roads.NODES: degree[key]=0
	for edge in Roads.EDGES:
		degree[edge[0]]+=1
		degree[edge[1]]+=1
	var dead_ends=0
	for key in degree: if degree[key]<2: dead_ends+=1
	check(dead_ends==0,"Road graph has no dead ends (%d nodes, %d edges)"%[Roads.NODES.size(),Roads.EDGES.size()])
	var seen={}
	var stack=[Roads.NODES.keys()[0]]
	while not stack.is_empty():
		var n=stack.pop_back()
		if seen.has(n): continue
		seen[n]=true
		for edge in Roads.EDGES:
			if edge[0]==n: stack.append(edge[1])
			elif edge[1]==n: stack.append(edge[0])
	check(seen.size()==Roads.NODES.size(),"Every road node is connected")
	var campus: Rect2=Layout.CAMPUS
	check(campus.size.x>=220 and campus.size.y>=300,"YUST campus is at least 220 x 300 m (%d x %d)"%[campus.size.x,campus.size.y])
	var falling=true
	for route in Layout.WATER_ROUTES:
		for i in range(route.points.size()-1):
			if route.points[i+1].y>route.points[i].y+0.001: falling=false
	check(falling,"Every canal falls downstream (gravity-fed)")
	check(world.get_node("PrototypeBuildings").get_child_count()>=85,"Town has %d main buildings"%world.get_node("PrototypeBuildings").get_child_count())
	check(world.shophouses.counts.units>=180,"Streets are lined with %d shophouses"%world.shophouses.counts.units)
	check(world.interiors.records.size()==world.interiors.total_buildings,"Every building has an entrance (%d)"%world.interiors.records.size())
	# Transport is running.
	check(world.skytrain.lines.C.stops.size()==8 and world.skytrain.lines.M.stops.size()==5,"Eight City Loop stops and five Market Link stops")
	check(world.buses.routes.size()==4 and world.buses.vehicles.size()==12,"Four bus routes with twelve buses")
	var before=[]
	for train in world.skytrain.trains: before.append(train.distance)
	var bus_before=[]
	for bus in world.buses.vehicles: bus_before.append(bus.distance)
	await frames(60*25)
	var moved=0
	for i in range(world.skytrain.trains.size()):
		if absf(world.skytrain.trains[i].distance-before[i])>5: moved+=1
	check(moved==world.skytrain.trains.size(),"All %d trains run between stations"%world.skytrain.trains.size())
	var bus_moved=0
	for i in range(world.buses.vehicles.size()):
		if absf(world.buses.vehicles[i].distance-bus_before[i])>5: bus_moved+=1
	check(bus_moved>=world.buses.vehicles.size()-1,"Buses circulate (%d/%d moved)"%[bus_moved,world.buses.vehicles.size()])
	# Real walks with the player body.
	await walk("campus walk to the main gate",[Vector2(693.66,646),Vector2(633.8,646),Vector2(588.73,646),Vector2(585.21,600)])
	var promenade=[]
	for x in [211.0,253.0,296.0,338.0,380.0,423.0,465.0]: promenade.append(Vector2(x,Layout.shore(x)+16.0))
	await walk("seafront promenade",promenade)
	await walk("downtown canal footbridge",[Vector2(421.13,360),Vector2(438.03,360)])
	await walk("home terraces climb (sidewalk)",[Vector2(175.5,250),Vector2(175.5,400),Vector2(175.5,552)])
	await walk("hill park trail",Layout.HILL_TRAIL.slice(0,6))
	await walk("beach stairs down to the sand",[Vector2(453.0,Layout.shore(453.0)+6),Vector2(453.0,Layout.shore(453.0)-8)])
	print("TOWN_CHECK ","PASS" if failures==0 else "FAIL"," failures=",failures)
	await world._quit_cleanly()
