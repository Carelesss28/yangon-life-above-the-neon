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
	var limit=ceili(player.position.distance_to(target)/player.test_speed*60.0)+120
	for i in range(limit):
		var delta=Vector2(target.x-player.position.x,target.z-player.position.z)
		if player.position.y<target.y-10.0: break
		if delta.length()<0.45:
			player.test_direction=Vector3.ZERO
			return absf(player.position.y-target.y)<0.6 and player.is_on_floor()
		player.test_direction=Vector3(delta.x,0,delta.y).normalized()
		await physics_frame
	player.test_direction=Vector3.ZERO
	return false

func station_index(service,code: String) -> int:
	for i in range(service.stations.size()):
		if service.stations[i].code==code: return i
	return -1

func press_f() -> void:
	var event=InputEventKey.new()
	event.physical_keycode=KEY_F
	event.pressed=true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await frames(1)
	event=InputEventKey.new()
	event.physical_keycode=KEY_F
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func walk_transfer(service,player,from: int,to: int) -> bool:
	for target in [service.stations[from].transfer_exit,service.transfer_landing,service.stations[to].transfer_exit,service.stations[to].platform]:
		if not await walk_to(player,target):
			print("TRANSFER_BLOCKED at ",player.global_position," walking to ",target," on_floor=",player.is_on_floor())
			return false
	return service.on_platform(to)

func run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await frames(3)
	var service=world.skytrain
	service.set_physics_process(false)
	check(service.lines.C.stops.size()==8 and service.lines.M.stops.size()==5,"Eight City Loop stops and five Market Link stops")
	check(service.trains.size()==3,"Two city-loop trains and one bidirectional market shuttle")
	var city_transfer=station_index(service,"C4")
	var market_transfer=station_index(service,"M5")
	var market_halls=station_index(service,"M3")
	check(city_transfer>=0 and market_transfer>=0 and service.transfer_stations.get(city_transfer)==market_transfer,"YUST Gate connects to Central Avenue")
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
	check(visited.size()==service.stations.size(),"Service visits every stop on both lines")
	check(minimum_gap>40,"Loop trains keep separation")
	# Real player journey: street lift -> platform -> city train -> interchange -> shuttle -> market lift.
	player.teleport(service.stations[0].ground)
	await frames(3)
	await press_f()
	check(service.lift_station==0,"F boards the street-level lift")
	for i in range(80): service.advance(0.1)
	check(service.lift_station<0 and not player.transit_mode,"Lift completes at platform level")
	check(await walk_to(player,service.stations[0].platform),"Walk from lift onto the platform")
	check(wait_for_stop(service,0,0),"City train opens doors at Seafront Central")
	await press_f()
	check(service.rider==0,"F boards the City Loop")
	var before=player.position
	world.visit_section(2)
	check(player.position==before,"Area shortcuts cannot detach a passenger")
	check(not await world.interiors.enter(0,false),"Building entry cannot interrupt a ride")
	for i in range(150): service.advance(0.1)
	check(not service.alight(),"Cannot alight between stops")
	check(player.position.distance_to(before)>5,"Passenger moves with the actual train")
	check(wait_for_stop(service,0,city_transfer),"City Loop stops at YUST Gate")
	await press_f()
	check(service.rider<0 and service.on_platform(city_transfer),"F alights onto the YUST Gate platform")
	check(await walk_transfer(service,player,city_transfer,market_transfer),"Walk across the transfer ramps onto the Market Link platform")
	check(wait_for_stop(service,2,market_transfer),"Market Link stops at Central Avenue")
	await press_f()
	check(service.rider==2,"F boards the Market Link after transferring")
	check(wait_for_stop(service,2,market_halls),"Market Link reaches Market Halls")
	await press_f()
	check(service.rider<0 and service.on_platform(market_halls),"F alights at Market Halls")
	check(await walk_to(player,service.stations[market_halls].upper),"Walk to the Market Halls lift")
	await press_f()
	check(service.lift_station==market_halls,"F takes the lift down")
	for i in range(100): service.advance(0.1)
	await frames(10)
	check(player.position.distance_to(service.stations[market_halls].ground)<0.6 and player.is_on_floor(),"Return safely to market street")
	await press_f()
	for i in range(100): service.advance(0.1)
	check(await walk_to(player,service.stations[market_halls].platform),"Walk from lift onto Market Link platform")
	check(wait_for_stop(service,2,market_halls),"Wait for the Market Link return train")
	await press_f()
	check(service.rider==2,"Board the Market Link return train")
	check(wait_for_stop(service,2,market_transfer),"Ride the Market Link back to Central Avenue")
	await press_f()
	check(await walk_transfer(service,player,market_transfer,city_transfer),"Walk the transfer ramps in the reverse direction")
	check(wait_for_stop(service,0,city_transfer),"Wait for the City Loop connection")
	await press_f()
	check(service.rider>=0 and service.trains[service.rider].line=="C","F boards the City Loop after transferring")
	var d: float=service.trains[0].distance
	player.paused=true
	service._physics_process(1)
	check(service.trains[0].distance==d,"Pause freezes train operation safely")
	player.paused=false
	print("SKYTRAIN_CHECK ","PASS" if failures==0 else "FAIL"," failures=",failures," stops_visited=",visited.size())
	if DisplayServer.get_name()=="headless": quit(failures)
	else: await world._quit_cleanly()

