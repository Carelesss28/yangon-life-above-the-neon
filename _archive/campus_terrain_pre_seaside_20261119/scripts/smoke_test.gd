extends SceneTree

var failures: int = 0
var world
var student

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in range(count): await physics_frame

func check(condition: bool, message: String) -> void:
	print(("PASS: " if condition else "FAIL: ") + message)
	if not condition: failures += 1

func route(start: Vector3, direction: Vector3, count: int, expected_height: float, label: String) -> void:
	student.test_direction = Vector3.ZERO
	student.teleport(start)
	await frames(30)
	student.test_direction = direction
	await frames(count)
	student.test_direction = Vector3.ZERO
	await frames(20)
	check(absf(student.position.y - expected_height) < 0.25, label + " position=" + str(student.position))

func run() -> void:
	world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await frames(5)
	var water_layout=load("res://scripts/terrain_layout.gd")
	for water_route in water_layout.WATER_ROUTES:
		var downhill=true
		for i in range(1,water_route.points.size()):
			if water_route.points[i].y>water_route.points[i-1].y+0.001: downhill=false
		check(downhill,"Water route never flows uphill: "+water_route.name)
	var network=world.get_node("TownWaterNetwork")
	check(network.open_samples>0 and network.covered_samples>0 and network.crossing_samples>0,"Open channels, culverts and collision decks built")
	student = world.player
	student.test_mode = true
	for cx in [50.0,150.0,250.0]:
		await route(Vector3(cx,2.1,86),Vector3(0,0,-1),130,4.0,"North stairs")
		await route(Vector3(cx,0.1,216),Vector3(0,0,-1),130,2.0,"South stairs")
		await route(Vector3(cx+28,2.1,102),Vector3(0,0,-1),460,4.0,"North ramp")
		await route(Vector3(cx+28,0.1,232),Vector3(0,0,-1),460,2.0,"South ramp")
	await route(Vector3(54,2.1,150),Vector3(1,0,0),250,2.0,"Garden bridge")
	check(student.position.x>77,"Bridge traversal")
	for index in range(8):
		world.visit_section(index)
		await frames(25)
		check(student.is_on_floor(),"Destination floor " + str(index))
	await route(Vector3(270,0.2,302),Vector3(1,0,0),620,0.0,"East west crossroads crossing")
	check(student.position.x>329,"Crossed road into east districts")
	await route(Vector3(150,0.1,375),Vector3(0,0,1),600,2.0,"Home first terrace ramp")
	check(student.position.z>430,"Home ramp traversal")
	await route(Vector3(430,0.1,400),Vector3(0,0,1),700,0.0,"Lakeside west approach")
	var layout=load("res://scripts/terrain_layout.gd")
	for trail in [layout.NORTH_TRAIL,layout.WEST_TRAIL,layout.MARKET_TRAIL]:
		var first: Vector2=trail[0]
		student.test_direction=Vector3.ZERO
		student.teleport(Vector3(first.x,layout.height_at(first.x,first.y)+0.2,first.y))
		await frames(30)
		for i in range(1,trail.size()):
			var goal: Vector2=trail[i]
			var reached=false
			for tick in range(1600):
				var delta=goal-Vector2(student.position.x,student.position.z)
				if delta.length()<0.6:
					reached=true
					break
				student.test_direction=Vector3(delta.x,0,delta.y).normalized()
				await physics_frame
			check(reached,"Hill trail waypoint " + str(goal))
			if not reached: break
		student.test_direction=Vector3.ZERO
		await frames(20)
		check(student.is_on_floor(),"Hill trail final ground contact")
	check(not layout.in_world(-100,-100),"Northwest gap stays outside parcels")
	await route(Vector3(607,0.2,-5),Vector3(0,0,-1),4000,18.0,"Market east access road")
	check(student.position.z < -390,"Access road reaches market")
	await route(Vector3(300,18.2,-420),Vector3(0,0,-1),600,20.0,"Market raised shopping core")
	check(student.position.z < -475,"Market core traversal")
	var lake_route=[]
	for i in range(17):
		var angle=TAU*i/16
		lake_route.append(Vector2(550+55*cos(angle),548+53*sin(angle)))
	var first: Vector2=lake_route[0]
	student.test_direction=Vector3.ZERO
	student.teleport(Vector3(first.x,layout.height_at(first.x,first.y)+0.2,first.y))
	await frames(30)
	for i in range(1,lake_route.size()):
		var goal: Vector2=lake_route[i]
		var reached=false
		for tick in range(700):
			var delta=goal-Vector2(student.position.x,student.position.z)
			if delta.length()<0.6:
				reached=true
				break
			student.test_direction=Vector3(delta.x,0,delta.y).normalized()
			await physics_frame
		check(reached,"Lakeside loop waypoint " + str(i))
		if not reached: break
	student.test_direction=Vector3.ZERO
	check(is_equal_approx(layout.RIVER_LAND_Y-layout.WATERFRONT_ROAD_Y,10),"Upper town 10 m above waterfront road")
	check(is_equal_approx(layout.height_at(200,630),10),"Upper town elevation")
	check(is_equal_approx(layout.height_at(200,655),0),"Lower road elevation")
	for cx in [-30.0,150.0,520.0]:
		await route(Vector3(cx,0.2,652),Vector3(0,0,-1),300,10.0,"Waterfront stairs ascent")
	for start_x in [-250.0,300.0]:
		await route(Vector3(start_x+1,10.2,638),Vector3(1,0,0),1620,0.0,"Vehicle ramp descent")
		check(student.position.x>start_x+159,"Vehicle ramp traversal")
	# Walk the complete north-bank route, including the west extension.
	student.test_direction=Vector3.ZERO
	var river_start=Vector2(-280,layout.river_north_bank(-280)-11)
	student.teleport(Vector3(river_start.x,layout.height_at(river_start.x,river_start.y)+0.2,river_start.y))
	await frames(30)
	for x in range(-260,601,20):
		var goal=Vector2(x,layout.river_north_bank(x)-11)
		var reached=false
		for tick in range(650):
			var delta=goal-Vector2(student.position.x,student.position.z)
			if delta.length()<0.6:
				reached=true
				break
			student.test_direction=Vector3(delta.x,0,delta.y).normalized()
			await physics_frame
		check(reached,"Riverbank route x="+str(x)+" pos="+str(student.position))
		if not reached: break
	student.test_direction=Vector3.ZERO
	await route(Vector3(150,layout.height_at(150,605)+0.2,605),Vector3(0,0,1),540,0.0,"Home riverfront approach")
	check(student.position.z>645,"Reached riverfront from homes")
	if not world.night: world.toggle_night()
	check(world.night,"Night lighting")
	print("SMOKE_TEST_COMPLETE failures="+str(failures))
	quit(1 if failures else 0)
