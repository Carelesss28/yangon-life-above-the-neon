extends SceneTree
const Roads=preload("res://scripts/road_layout.gd")
var failures=0
var visits={}

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool,message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok: failures+=1

func frames(count: int) -> void:
	for i in range(count): await physics_frame

func on_road(point: Vector3) -> bool:
	var road=Roads.sample(point.x,point.z)
	if not road.is_empty() and road.distance<=road.half+0.2: return true
	for key in Roads.NODES:
		var node: Vector3=Roads.NODES[key]
		var half=9.0 if key in ["n","c","s","w","e"] else 4.0
		if absf(point.x-node.x)<=half+0.2 and absf(point.z-node.z)<=half+0.2: return true
	return false

func walk_to(player,target: Vector3) -> bool:
	for i in range(500):
		var delta=Vector2(target.x-player.position.x,target.z-player.position.z)
		if delta.length()<0.5:
			player.test_direction=Vector3.ZERO
			return true
		player.test_direction=Vector3(delta.x,0,delta.y).normalized()
		await physics_frame
	player.test_direction=Vector3.ZERO
	return false

func wait_for(service,index: int,stop: int,limit=9000) -> bool:
	for i in range(limit):
		service.advance(0.1)
		if service.stopped_at(service.vehicles[index])==stop: return true
	return false

func footprint(bus: Node3D) -> PackedVector2Array:
	var polygon=PackedVector2Array()
	for point in [Vector3(-1.2,0,-4.3),Vector3(1.2,0,-4.3),Vector3(1.2,0,4.3),Vector3(-1.2,0,4.3)]:
		var p=bus.to_global(point)
		polygon.append(Vector2(p.x,p.z))
	return polygon

func run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await frames(4)
	var service=world.buses
	service.set_physics_process(false)
	world.skytrain.set_physics_process(false)
	check(service.routes.size()==3,"Three regular bus routes")
	check(service.vehicles.size()==10,"Ten scheduled buses")
	check(service.stops.size()==15,"Fifteen shared and local stops")
	for line in service.routes:
		var off_road=0
		var route: Dictionary=service.routes[line]
		for i in range(int(route.length/3)):
			var p: Vector3=service.position_on_route(line,i*3)
			if not on_road(p):
				off_road+=1
				print("OFF_ROAD ",line," ",p)
		check(off_road==0,line+" stays on existing roads, off-road samples="+str(off_road))
	var player=world.player
	player.test_mode=true
	for stop in service.stops:
		player.teleport(stop.access+Vector3.UP*0.2)
		await frames(12)
		var reached: bool=await walk_to(player,stop.queue)
		check(reached,"Walk from ground to "+stop.title+" pos="+str(player.position)+" target="+str(stop.queue))
		await frames(8)
		check(player.is_on_floor() and absf(player.position.y-stop.queue.y)<0.6,"Usable boarding surface "+stop.title)
	player.teleport(Vector3(150,0.15,275))
	var closest=INF
	var overlaps=0
	for i in range(6000):
		service.advance(0.1)
		for bus in service.vehicles:
			var stop: int=service.stopped_at(bus)
			if stop>=0: visits[str(stop)]=true
		for a in range(service.vehicles.size()):
			for c in range(a+1,service.vehicles.size()):
				var p: Vector3=service.vehicles[a].root.position
				var q: Vector3=service.vehicles[c].root.position
				if absf(p.y-q.y)<1.8:
					var distance=Vector2(p.x-q.x,p.z-q.z).length()
					closest=minf(closest,distance)
					if distance<9.2 and not Geometry2D.intersect_polygons(footprint(service.vehicles[a].root),footprint(service.vehicles[c].root)).is_empty():
						if overlaps==0: print("BUS_OVERLAP ",a," ",c," ",p," ",q)
						overlaps+=1
	check(visits.size()==service.stops.size(),"Scheduled service visits all bus stops, visited="+str(visits.size()))
	check(overlaps==0,"Bus bodies do not overlap; opposite lanes may run side by side, overlaps="+str(overlaps))
	var first: int=service.routes.B1.stops[0].stop
	player.teleport(service.stops[first].queue)
	check(wait_for(service,0,first),"Wait for a City Circuit bus")
	var press=InputEventKey.new()
	press.physical_keycode=KEY_B
	press.pressed=true
	Input.parse_input_event(press)
	await frames(1)
	check(service.rider>=0,"B boards a bus with open doors")
	if service.rider>=0:
		var vehicle: int=service.rider
		var before=player.position
		world.visit_section(2)
		check(player.position==before,"Area shortcuts cannot interrupt a bus ride")
		check(not world.skytrain.use_lift(0,true),"A lift cannot capture a bus passenger")
		for i in range(130): service.advance(0.1)
		check(not service.alight(),"Cannot get off between bus stops")
		check(player.position.distance_to(before)>5,"Passenger travels with the physical bus")
		var next: int=service.routes[service.vehicles[vehicle].line].stops[service.vehicles[vehicle].next_stop].stop
		check(wait_for(service,vehicle,next),"Ride to the next stop")
		check(service.alight(),"Alight at an open stop")
		await frames(12)
		check(not player.transit_mode and player.is_on_floor(),"Walking resumes safely on the boarding platform")
	# Pedestrian avoidance and pause must work, not just the timetable.
	var test_bus: Dictionary=service.vehicles[0]
	test_bus.dwell=0
	test_bus.speed=0
	var forward=service.base_forward(test_bus.line,test_bus.distance)
	player.teleport(test_bus.root.position+forward*6)
	service.advance(0.2)
	check(test_bus.speed<0.1,"Driver yields to a pedestrian ahead")
	var before_distance: float=test_bus.distance
	player.paused=true
	service._physics_process(1)
	check(test_bus.distance==before_distance,"Pause freezes bus operation")
	player.paused=false
	print("BUS_CHECK ","PASS" if failures==0 else "FAIL"," stops_visited=",visits.size()," failures=",failures)
	await world._quit_cleanly()
