extends SceneTree
const Layout=preload("res://scripts/terrain_layout.gd")
var failures=0
var visited={}

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool,message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok: failures+=1

func frames(count: int) -> void:
	for i in range(count): await physics_frame

func wait_for_stop(service,train_index: int,station_index: int,limit=3500) -> bool:
	for i in range(limit):
		service.advance(0.1)
		if service.stopped_at(service.trains[train_index])==station_index: return true
	return false

func walk_to(player,target: Vector3) -> bool:
	for i in range(200):
		var delta=Vector2(target.x-player.position.x,target.z-player.position.z)
		if delta.length()<0.45:
			player.test_direction=Vector3.ZERO
			return true
		player.test_direction=Vector3(delta.x,0,delta.y).normalized()
		await physics_frame
	player.test_direction=Vector3.ZERO
	return false

func run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await frames(3)
	var service=world.skytrain
	service.set_physics_process(false)
	check(service.stations.size()==8,"Eight elevated stations")
	check(service.trains.size()==3,"Two city-loop trains and one bidirectional market shuttle")
	check(service.stations[1].services.size()==2,"Tech Interchange serves both lines")
	for line in service.lines:
		var minimum=INF
		var data: Dictionary=service.lines[line]
		for i in range(int(data.length/8)):
			var p: Vector3=service.sample(line,i*8)
			minimum=minf(minimum,p.y-Layout.height_at(p.x,p.z))
		check(minimum>5,line+" stays elevated above terrain, clearance="+str(minimum))
		var roof_conflicts=0
		for building in world.get_node("PrototypeBuildings").get_children():
			var bounds: AABB=world._scene_bounds(building)
			var footprint=Rect2(Vector2(bounds.position.x,bounds.position.z),Vector2(bounds.size.x,bounds.size.z)).grow(2.2)
			for i in range(int(data.length/3)):
				var p: Vector3=service.sample(line,i*3)
				if footprint.has_point(Vector2(p.x,p.z)) and p.y-1<bounds.end.y+0.5:
					roof_conflicts+=1
					print("ROOF_CONFLICT ",line," ",building.name," ",p)
		check(roof_conflicts==0,line+" lower guideway clears building roofs")
	var player=world.player
	player.test_mode=true
	for station in service.stations:
		player.teleport(station.platform+Vector3.UP*0.1)
		await frames(15)
		check(player.is_on_floor() and absf(player.position.y-station.platform.y)<0.5,"Solid platform "+station.code)
	# Complete cycles: all stops are actually visited, with no train overlap.
	var minimum_gap=INF
	for i in range(3500):
		service.advance(0.1)
		for train in service.trains:
			var stop: int=service.stopped_at(train)
			if stop>=0: visited[train.line+str(stop)]=true
		var gap=fposmod(service.trains[0].distance-service.trains[1].distance,service.lines.C.length)
		minimum_gap=minf(minimum_gap,minf(gap,service.lines.C.length-gap))
	check(visited.size()==9,"Service visits all six loop stops and all three shuttle stops")
	check(minimum_gap>40,"Loop trains keep separation")
	# Real player journey: street lift -> platform -> city train -> interchange -> shuttle -> market lift.
	player.teleport(service.stations[0].ground)
	await frames(3)
	check(service.use_lift(0,true),"Board street-level accessible lift")
	for i in range(80): service.advance(0.1)
	check(service.lift_station<0 and not player.transit_mode,"Lift completes at platform level")
	check(await walk_to(player,service.stations[0].platform),"Walk from lift onto the platform")
	check(wait_for_stop(service,0,0),"City train opens doors at Campus North")
	check(service.board(0),"Board city train")
	var before=player.position
	world.visit_section(2)
	check(player.position==before,"Area shortcuts cannot detach a passenger")
	check(not await world.interiors.enter(0,false),"Building entry cannot interrupt a ride")
	for i in range(150): service.advance(0.1)
	check(not service.alight(),"Cannot alight between stops")
	check(player.position.distance_to(before)>5,"Passenger moves with the actual train")
	check(wait_for_stop(service,0,1),"Train reaches Tech Interchange")
	check(service.alight(),"Alight onto interchange platform")
	check(wait_for_stop(service,2,1),"Wait for Market Link connection")
	check(service.board(2),"Transfer to market shuttle on the shared platform")
	check(wait_for_stop(service,2,6),"Ride to Market South")
	check(service.alight(),"Alight at Market South")
	check(await walk_to(player,service.stations[6].upper),"Walk to market station lift")
	check(service.use_lift(6,false),"Take lift down")
	for i in range(100): service.advance(0.1)
	await frames(10)
	check(player.position.distance_to(service.stations[6].ground)<0.6 and player.is_on_floor(),"Return safely to market street")
	# F input must invoke the same usable lift flow, rather than only test APIs.
	var event=InputEventKey.new()
	event.physical_keycode=KEY_F
	event.pressed=true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await frames(1)
	check(service.lift_station==6,"F operates the nearest station lift")
	for i in range(100): service.advance(0.1)
	# When both trains dwell together, F should offer the other line after alighting.
	for index in [0,2]:
		var train: Dictionary=service.trains[index]
		train.current_stop=1 if index==0 else 0
		train.next_stop=2 if index==0 else 1
		train.distance=service.lines[train.line].stops[train.current_stop].distance
		train.dwell=9.0
		train.door_ratio=1.0
		train.speed=0.0
		service.pose(train)
	player.teleport(service.stations[1].platform)
	service.last_line="C"
	check(service.boarding_candidate()==2,"Interchange offers Market Link when both lines are boarding")
	var release=InputEventKey.new()
	release.physical_keycode=KEY_F
	release.pressed=false
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	await frames(1)
	var transfer_press=InputEventKey.new()
	transfer_press.physical_keycode=KEY_F
	transfer_press.pressed=true
	Input.parse_input_event(transfer_press)
	Input.flush_buffered_events()
	await frames(1)
	check(service.rider==2,"F selects the connecting service at a shared platform")
	service.alight()
	var d: float=service.trains[0].distance
	player.paused=true
	service._physics_process(1)
	check(service.trains[0].distance==d,"Pause freezes train operation safely")
	player.paused=false
	print("SKYTRAIN_CHECK ","PASS" if failures==0 else "FAIL"," failures=",failures," stops_visited=",visited.size())
	await world._quit_cleanly()

