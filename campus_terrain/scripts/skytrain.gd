extends Node3D
## Elevated city loop and market shuttle. Distances/metres, speeds/metres per second.
const Layout=preload("res://scripts/terrain_layout.gd")
const Roads=preload("res://scripts/road_layout.gd")
const DWELL=10.0
const MAX_SPEED=24.0
const ACCEL=3.0
const BRAKE=4.0
var world
var b
var lines={}
var stations: Array=[]
var trains: Array=[]
var rider=-1
var lift_station=-1
var lift_clock=0.0
var lift_up=true
var lift_from=Vector3.ZERO
var lift_to=Vector3.ZERO
var lift_phase=0
var lift_call_origin=Vector3.ZERO
var lift_was_camera={}
var prompt: Label
var route_panel: PanelContainer
var route_text: Label
var update_clock=0.0
var steel: Material
var concrete: Material
var glass: Material
var cyan: Material
var amber: Material
var white: Material
var dark: Material
var support_count=0
var sim_clock=0.0
var arrival_sound: AudioStreamWAV
var ride_zoom=1.0
var transfer_stations: Dictionary={}
var transfer_landing: Vector3

func _ready() -> void:
	name="SkytrainService"
	b=load("res://scripts/reference_buildings.gd").new()
	b.world=world
	steel=world._mat("435f6c",0.45)
	concrete=world._mat("899e9e")
	glass=world._mat("284e66",0.23)
	cyan=world._mat("64d6d1",0.4,1.0)
	amber=world._mat("ffd093",0.5,1.0)
	white=world._mat("c2d0cb",0.4)
	dark=world._mat("273c48")
	if DisplayServer.get_name()!="headless": arrival_sound=make_chime()
	# The city loop runs above the coastal boulevard, the east harbour street, Central Avenue and the
	# west lane, about 8 m over the road. The campus-market line rides higher (14 m) where it crosses.
	var city=lower_guideway(rounded_loop([Vector3(42.25,0,235),Vector3(809.86,0,235),Vector3(809.86,0,560),Vector3(42.25,0,560)],30),8.0)
	var market=Curve3D.new()
	market.bake_interval=1.0
	for point in [Vector3(577.46,0,262),Vector3(577.46,0,420),Vector3(577.46,0,560),Vector3(577.46,0,720),Vector3(577.46,0,900)]: market.add_point(point)
	market=lower_guideway(market,14.0)
	lines={"C":{"name":"CITY LOOP","curve":city,"length":city.get_baked_length(),"stops":[],"closed":true,"colour":cyan},"M":{"name":"MARKET LINK","curve":market,"length":market.get_baked_length(),"stops":[],"closed":false,"colour":amber}}
	track("C")
	track("M")
	add_station("C1","Seafront Central","C",Vector3(422.54,0,235))
	add_station("C2","Harbour","C",Vector3(676.06,0,235))
	add_station("C3","Harbour East","C",Vector3(809.86,0,400))
	var loop_transfer=add_station("C4","YUST Gate","C",Vector3(633.8,0,560),-1)
	add_station("C5","Market North","C",Vector3(394.37,0,560))
	add_station("C6","Home Terraces","C",Vector3(140.85,0,560))
	add_station("C7","Canal West","C",Vector3(42.25,0,400))
	add_station("C8","Promenade West","C",Vector3(183.1,0,235))
	add_station("M1","Downtown East","M",Vector3(577.46,0,300))
	add_station("M2","YUST Campus","M",Vector3(577.46,0,640))
	add_station("M3","Market Halls","M",Vector3(577.46,0,760))
	add_station("M4","South Terminus","M",Vector3(577.46,0,880))
	var market_transfer=add_station("M5","Central Avenue","M",Vector3(577.46,0,490),1,-1)
	build_transfer(loop_transfer,market_transfer)
	for key in lines:
		lines[key].stops.sort_custom(func(a,c):return a.distance<c.distance)
	spawn_train("C",0,1)
	spawn_train("C",4,1)
	spawn_train("M",0,1)
	_ui()
	print("SKYTRAIN_READY stations=",stations.size()," trains=",trains.size()," supports=",support_count," city_m=",int(lines.C.length)," market_m=",int(lines.M.length))

func rounded_loop(vertices: Array,radius: float) -> Curve3D:
	var curve=Curve3D.new()
	curve.bake_interval=1.0
	for i in range(vertices.size()):
		var previous: Vector3=vertices[(i-1+vertices.size())%vertices.size()]
		var here: Vector3=vertices[i]
		var next: Vector3=vertices[(i+1)%vertices.size()]
		var incoming=(here-previous).normalized()
		var outgoing=(next-here).normalized()
		curve.add_point(here-incoming*radius,Vector3.ZERO,incoming*radius*0.5523)
		curve.add_point(here+outgoing*radius,-outgoing*radius*0.5523,Vector3.ZERO)
	curve.add_point(curve.get_point_position(0),Vector3.ZERO,curve.get_point_out(0))
	return curve

func lower_guideway(source: Curve3D,clearance: float=8.0) -> Curve3D:
	var curve=Curve3D.new()
	curve.bake_interval=0.75
	var length=source.get_baked_length()
	var count=ceili(length/4)
	var points: Array[Vector3]=[]
	var heights: Array[float]=[]
	for i in range(count+1):
		var distance=minf(length,float(i)/count*length)
		var point=source.sample_baked(distance,true)
		var ground=Layout.height_at(point.x,point.z)
		var road=Roads.sample(point.x,point.z)
		if not road.is_empty(): ground=maxf(ground,road.y+0.1)
		points.append(point)
		heights.append(ground+clearance)
	# A clearance envelope smooths upwards around raised crossings; averaging
	# would dip through the narrow pedestrian ramps at the riverfront.
	var closed=points[0].distance_to(points.back())<0.1
	for pass_index in range(3):
		if closed:
			heights[0]=maxf(heights[0],heights.back())
			heights[count]=heights[0]
		for i in range(1,count+1): heights[i]=maxf(heights[i],heights[i-1]-points[i].distance_to(points[i-1])*0.06)
		for i in range(count-1,-1,-1): heights[i]=maxf(heights[i],heights[i+1]-points[i].distance_to(points[i+1])*0.06)
	for i in range(count+1):
		var point=points[i]
		point.y=heights[i]
		curve.add_point(point)
	return curve

func closest_offset_xz(curve: Curve3D,point: Vector3) -> float:
	var closest=0.0
	var best=INF
	for i in range(ceili(curve.get_baked_length())):
		var p=curve.sample_baked(i,true)
		var distance=Vector2(p.x-point.x,p.z-point.z).length_squared()
		if distance<best: best=distance; closest=float(i)
	return closest

func sample(line: String,distance: float) -> Vector3:
	var data: Dictionary=lines[line]
	return data.curve.sample_baked(fposmod(distance,data.length) if data.closed else clampf(distance,0,data.length),true)

func tangent(line: String,distance: float) -> Vector3:
	return (sample(line,distance+0.5)-sample(line,distance-0.5)).normalized()

func box(parent: Node3D,at: Vector3,size: Vector3,material: Material,title: String,solid=false) -> MeshInstance3D:
	return b.box(parent,at,size,material,title,solid)

func text(parent: Node3D,value: String,at: Vector3,size=0.02) -> Label3D:
	var label=Label3D.new()
	label.text=value
	label.position=at
	label.font_size=40
	label.pixel_size=size
	label.modulate=Color("def8ea")
	parent.add_child(label)
	return label

func track(line: String) -> void:
	var data: Dictionary=lines[line]
	var group=Node3D.new()
	group.name=line+"_ElevatedGuideway"
	add_child(group)
	var decks=[]
	var rails=[]
	var parapets=[]
	for i in range(ceili(data.length/4.0)):
		var d=i*4.0
		var p=sample(line,d)
		var q=sample(line,minf(d+4,data.length-0.01))
		if p.distance_to(q)<0.01: continue
		var basis=Basis.looking_at((q-p).normalized(),Vector3.UP)
		decks.append(Transform3D(local_scale(basis,Vector3(4.2,0.8,p.distance_to(q)+0.08)),(p+q)/2-Vector3.UP*0.55))
		for sign_value in [-1,1]:
			rails.append(Transform3D(local_scale(basis,Vector3(0.12,0.16,p.distance_to(q)+0.08)),(p+q)/2+basis.x*sign_value*0.8))
			parapets.append(Transform3D(local_scale(basis,Vector3(0.16,0.6,p.distance_to(q)+0.08)),(p+q)/2+basis.x*sign_value*1.95))
		if i%8==0: support(group,p,basis.x)
	batch_boxes(group,"ViaductDeck",concrete,decks)
	batch_boxes(group,"Rails",steel,rails)
	batch_boxes(group,"Parapets",steel,parapets)

func batch_boxes(parent: Node3D,title: String,material: Material,values: Array) -> void:
	var mesh=BoxMesh.new()
	mesh.size=Vector3.ONE
	var multi=MultiMesh.new()
	multi.transform_format=MultiMesh.TRANSFORM_3D
	multi.mesh=mesh
	multi.instance_count=values.size()
	for i in range(values.size()): multi.set_instance_transform(i,values[i])
	var node=MultiMeshInstance3D.new()
	node.name=title
	node.multimesh=multi
	node.material_override=material
	parent.add_child(node)

func local_scale(basis: Basis,size: Vector3) -> Basis:
	return Basis(basis.x*size.x,basis.y*size.y,basis.z*size.z)

func support(group: Node3D,point: Vector3,side: Vector3) -> void:
	var selected=point
	var found=false
	for shift in [0.0,6.5,-6.5,10.0,-10.0]:
		var candidate=point+side*shift
		if not Layout.in_world(candidate.x,candidate.z): continue
		if not Roads.sample(candidate.x,candidate.z).is_empty(): continue
		var blocked=false
		for building in world.get_node("PrototypeBuildings").get_children():
			var plot: Rect2=building.get_meta("reserved_plot")
			if plot.grow(2).has_point(Vector2(candidate.x,candidate.z)): blocked=true; break
		if blocked: continue
		selected=candidate
		found=true
		break
	if not found: return
	var ground=Layout.height_at(selected.x,selected.z)
	var height=point.y-1-ground
	if height<3: return
	box(group,Vector3(selected.x,ground+height/2,selected.z),Vector3(1.1,height,1.1),concrete,"ViaductPier",true)
	box(group,Vector3(selected.x,ground+0.1,selected.z),Vector3(2.3,0.2,2.3),concrete,"PierFooting")
	if selected.distance_to(point)>2:
		var beam=box(group,(Vector3(selected.x,point.y-1,selected.z)+point-Vector3.UP)/2,Vector3(0.7,0.7,selected.distance_to(point)+4),concrete,"PierCrosshead")
		beam.basis=Basis.looking_at((point-selected).normalized(),Vector3.UP)
	support_count+=1

func add_station(code: String,title: String,line: String,rail_point: Vector3,transfer_end: int=0,platform_side: int=1) -> int:
	var distance: float=closest_offset_xz(lines[line].curve,rail_point)
	var point=sample(line,distance)
	var forward=tangent(line,distance)
	forward.y=0
	forward=forward.normalized()*platform_side
	var outward=-Vector3(forward.z,0,-forward.x)
	var platform=point+outward*4+Vector3.UP*0.8
	var basis=Basis.looking_at(forward,Vector3.UP)
	var station=Node3D.new()
	station.name=code+"_"+title.replace(" ","_")
	station.position=platform
	station.basis=basis
	add_child(station)
	box(station,Vector3(0,-0.18,0),Vector3(5,0.36,36),concrete,"Platform",true)
	box(station,Vector3(-1.95,0.03,0),Vector3(0.18,0.05,35),amber,"TactileBoardingLine")
	# Cutaway roof exposes the platform from the fixed high game camera.
	box(station,Vector3(1,4.3,0),Vector3(3,0.2,37),white,"PlatformCanopy")
	for z in [-15,-5,5,15]:
		box(station,Vector3(1.8,2.1,z),Vector3(0.18,4.2,0.18),steel,"CanopyColumn")
		box(station,Vector3(0.5,4.1,z),Vector3(2,0.08,0.12),amber,"emit_platform_light")
	for z in [-17.8,17.8]:
		if z*transfer_end>0:
			for x in [-2,2]: box(station,Vector3(x,0.9,z),Vector3(1,1.8,0.12),glass,"EndSafetyBarrier",true)
		else: box(station,Vector3(0,0.9,z),Vector3(5,1.8,0.12),glass,"EndSafetyBarrier",true)
	# The outer railing has a gap for the lift walkway, away from the track edge.
	for z in [-10,10]: box(station,Vector3(2.45,0.9,z),Vector3(0.12,1.8,16),glass,"OuterSafetyBarrier",true)
	for z in [-11,11]:
		box(station,Vector3(1.1,0.55,z),Vector3(1.3,0.18,3.5),white,"PlatformBench")
		box(station,Vector3(1.8,0.9,z),Vector3(0.12,0.8,3.5),white,"BenchBack")
	var gates=[]
	for z in [-8.5,-3.1,3.1,8.5]:
		var gate=Node3D.new()
		gate.position=Vector3(-2.45,0,z)
		gate.set_meta("service",line)
		station.add_child(gate)
		box(gate,Vector3(0,1,0),Vector3(0.12,2,1.8),glass,"PlatformScreenDoor")
		gates.append(gate)
	# A continuous safety collider makes boarding an explicit F interaction.
	var safety=box(station,Vector3(-2.5,0.9,0),Vector3(0.12,1.8,36),glass,"TrackSafetyScreen",true)
	safety.visible=false
	for z in [-16,-12,-6,0,6,12,16]: box(station,Vector3(-2.45,1,z),Vector3(0.15,2,0.12),steel,"ScreenPost")
	var header=text(station,code+"  "+title+"\n"+lines[line].name,Vector3(0,5.2,0),0.018)
	header.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	var led=text(station,"Next train",Vector3(-1.5,2.7,-12),0.012)
	led.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	var shaft=platform+outward*5
	var ground=Layout.height_at(shaft.x,shaft.z)
	var lift=Node3D.new()
	lift.name="AccessibleLift"
	lift.position=Vector3(shaft.x,ground+0.2,shaft.z)
	lift.basis=Basis.looking_at(-outward,Vector3.UP)
	add_child(lift)
	box(lift,Vector3(0,0.05,0),Vector3(3.5,0.15,3.5),white,"CabinFloor")
	box(lift,Vector3(0,1.4,-1.55),Vector3(3.3,2.8,0.1),glass,"LiftBack")
	for x in [-1.55,1.55]: box(lift,Vector3(x,1.4,0),Vector3(0.1,2.8,3),glass,"LiftSide")
	box(lift,Vector3(0,3,0),Vector3(3.5,0.15,3.5),white,"LiftRoof")
	for x in [-1.8,1.8]:
		for z in [-1.8,1.8]: box(self,Vector3(shaft.x+x,(platform.y+ground)/2,shaft.z+z),Vector3(0.18,platform.y-ground+4,0.18),steel,"LiftTowerRail")
	var upper=Vector3(shaft.x,platform.y+0.1,shaft.z)
	var walkway_start=platform-outward*1.75
	if transfer_end!=0:
		# Keep the lift rails outside the through route along the transfer platform.
		walkway_start=platform+outward*2.35
	var walkway_end=upper+outward*1.75
	var walkway_center=(walkway_start+walkway_end)/2
	var walkway_length=walkway_start.distance_to(walkway_end)
	var connector=box(self,walkway_center-Vector3.UP*0.2,Vector3(3.5,0.4,walkway_length),concrete,"LiftPlatformWalkway",true)
	connector.basis=Basis.looking_at((walkway_start-walkway_end).normalized(),Vector3.UP)
	var link_basis=connector.basis
	for side in [-1,1]:
		var railing=box(self,walkway_center+Vector3.UP*0.9+link_basis.x*side*1.7,Vector3(0.12,1.6,walkway_length-0.5),glass,"LiftWalkwaySafetyRail",true)
		railing.basis=link_basis
	var end_rail=box(self,upper+(upper-platform).normalized()*1.6+Vector3.UP*0.8,Vector3(3.5,1.6,0.12),glass,"LiftLandingSafetyRail",true)
	end_rail.basis=link_basis
	var button=Vector3(shaft.x,ground+0.12,shaft.z)+outward*3.5
	box(self,Vector3(button.x,ground+0.03,button.z),Vector3(6,0.06,6),white,"StationEntrancePaving")
	var entrance=text(self,code+"  "+title+"\nSKYTRAIN  /  LIFT [F]",button+Vector3.UP*3,0.02)
	entrance.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	var index=stations.size()
	var transfer_exit=station.to_global(Vector3(0,0,transfer_end*17.5))
	stations.append({"code":code,"title":title,"line":line,"root":station,"platform":platform+Vector3.UP*0.1,"ground":button,"upper":upper,"lift":lift,"lift_low":lift.position,"lift_high":upper,"gates":gates,"led":led,"transfer_exit":transfer_exit})
	lines[line].stops.append({"station":index,"distance":distance})
	world.grass_exclusions.append(Rect2(Vector2(button.x-3,button.z-3),Vector2(6,6)))
	return index

func build_transfer(city_index: int,market_index: int) -> void:
	transfer_stations={city_index:market_index,market_index:city_index}
	var bridge=Node3D.new()
	bridge.name="CentralAvenueInterchange"
	add_child(bridge)
	var city_exit: Vector3=stations[city_index].transfer_exit
	var market_exit: Vector3=stations[market_index].transfer_exit
	# Keep the walkway north of the City Loop and east of the Market Link.
	# Split the rise between the two ramps at the level corner landing.
	var east_length=absf(city_exit.x-market_exit.x)
	var south_length=absf(city_exit.z-market_exit.z)
	var corner_height=lerpf(city_exit.y,market_exit.y,east_length/(east_length+south_length))
	transfer_landing=Vector3(market_exit.x,corner_height,city_exit.z)
	var width=3.0
	var half_width=width/2
	transfer_ramp(bridge,city_exit,transfer_landing+Vector3.RIGHT*half_width,width)
	transfer_ramp(bridge,transfer_landing+Vector3.FORWARD*half_width,market_exit,width)
	box(bridge,transfer_landing-Vector3.UP*0.2,Vector3(width,0.4,width),concrete,"TransferLanding",true)
	box(bridge,transfer_landing+Vector3(-half_width,0.65,0),Vector3(0.12,1.3,width),steel,"LandingRail",true)
	box(bridge,transfer_landing+Vector3(0,0.65,half_width),Vector3(width,1.3,0.12),steel,"LandingRail",true)
	for index in transfer_stations:
		var station: Dictionary=stations[index]
		var connection: Dictionary=stations[transfer_stations[index]]
		var sign_position: Vector3=station.transfer_exit.move_toward(station.platform,2.0)+Vector3.UP*2.8
		var sign_label=text(bridge,"TRANSFER  /  "+lines[connection.line].name,sign_position,0.02)
		sign_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED

func transfer_ramp(parent: Node3D,start: Vector3,finish: Vector3,width: float) -> void:
	var basis=Basis.looking_at((finish-start).normalized(),Vector3.UP)
	var center=(start+finish)/2
	var length=start.distance_to(finish)
	var deck=box(parent,center-basis.y*0.2,Vector3(width,0.4,length+0.08),concrete,"TransferRamp",true)
	deck.basis=basis
	for side in [-1,1]:
		var edge=center+basis.x*side*(width/2)
		var rail=box(parent,edge+basis.y*0.65,Vector3(0.12,1.3,length),steel,"TransferRail",true)
		rail.basis=basis
		var strip=box(parent,edge-basis.y*0.14,Vector3(0.13,0.06,length),cyan,"TransferLight")
		strip.basis=basis
	for offset in [0.25,0.75]:
		support(parent,start.lerp(finish,offset),basis.x)

func spawn_train(line: String,stop_index: int,direction: int) -> void:
	var data: Dictionary=lines[line]
	var group=Node3D.new()
	group.name=line+"_Train_"+str(trains.size()+1)
	add_child(group)
	var cars=[]
	var doors=[]
	var roofs=[]
	for i in range(2):
		var car=Node3D.new()
		group.add_child(car)
		cars.append(car)
		box(car,Vector3(0,0.65,0),Vector3(2.8,0.3,10.5),steel,"CarFloor")
		for side in [-1,1]:
			box(car,Vector3(side*1.35,1.05,0),Vector3(0.15,0.7,10.5),white,"BodySide")
			box(car,Vector3(side*1.35,2.9,0),Vector3(0.15,0.35,10.5),white,"WindowHeader")
			box(car,Vector3(side*0.95,1.05,0),Vector3(0.6,0.18,6),steel,"PassengerSeat")
			box(car,Vector3(side*1.42,2.1,0),Vector3(0.08,1.2,9.8),glass,"WindowBand")
			box(car,Vector3(side*1.45,1.05,0),Vector3(0.08,0.25,10),data.colour,"LineStripe")
			for z in [-2.7,2.7]:
				for half in [-1,1]:
					var door=box(car,Vector3(side*1.49,1.8,z+half*0.4),Vector3(0.1,2.2,0.75),white,"SlidingTrainDoor")
					doors.append({"node":door,"z":door.position.z,"sign":half,"side":side})
		for z in [-5.3,5.3]:
			box(car,Vector3(0,1.1,z),Vector3(2.8,0.75,0.15),white,"CabLowerPanel")
			box(car,Vector3(0,2.2,z),Vector3(2.25,1.1,0.08),glass,"CabWindow")
			for x in [-0.8,0.8]: box(car,Vector3(x,1.1,z),Vector3(0.3,0.16,0.12),amber,"emit_headlight")
		roofs.append(box(car,Vector3(0,3.1,0),Vector3(2.9,0.3,10.6),white,"roof"))
		roofs.append(box(car,Vector3(0,3.4,0),Vector3(1.4,0.4,3),steel,"RoofAirConditioning"))
	var next_index=posmod(stop_index+direction,data.stops.size())
	var chime: AudioStreamPlayer3D
	if arrival_sound:
		chime=AudioStreamPlayer3D.new()
		chime.stream=arrival_sound
		chime.max_distance=45
		chime.unit_size=8
		chime.volume_db=-10
		cars[0].add_child(chime)
	trains.append({"line":line,"root":group,"cars":cars,"doors":doors,"roofs":roofs,"chime":chime,"distance":float(data.stops[stop_index].distance),"speed":0.0,"dwell":DWELL,"current_stop":stop_index,"next_stop":next_index,"direction":direction,"door_ratio":0.0})
	pose(trains.back())

func _physics_process(delta: float) -> void:
	if world.player.paused: return
	advance(delta)

func advance(delta: float) -> void:
	sim_clock+=delta
	for train in trains:
		var data: Dictionary=lines[train.line]
		if train.dwell>0:
			train.dwell=maxf(0,train.dwell-delta)
			train.door_ratio=clampf(minf(DWELL-train.dwell,train.dwell)/0.7,0,1)
			train.speed=0.0
		else:
			train.door_ratio=0.0
			var target: float=data.stops[train.next_stop].distance
			var remaining=fposmod(target-train.distance,data.length) if data.closed else absf(target-train.distance)
			var desired=minf(MAX_SPEED,sqrt(maxf(0,2*BRAKE*remaining)))
			# Keep a safe following distance between the two loop trains.
			for other in trains:
				if other==train or other.line!=train.line: continue
				var gap=fposmod(other.distance-train.distance,data.length)
				desired=minf(desired,sqrt(maxf(0,2*BRAKE*(gap-40))))
			train.speed=move_toward(train.speed,desired,(BRAKE if desired<train.speed else ACCEL)*delta)
			var step=train.speed*delta
			if remaining<=maxf(step,0.03):
				train.distance=target
				train.current_stop=train.next_stop
				train.dwell=DWELL
				train.speed=0.0
				if train.chime: train.chime.play()
				if not data.closed and train.current_stop in [0,data.stops.size()-1]: train.direction=1 if train.current_stop==0 else -1
				train.next_stop=posmod(train.current_stop+train.direction,data.stops.size())
			else:
				train.distance=fposmod(train.distance+step*train.direction,data.length) if data.closed else train.distance+step*train.direction
		pose(train)
	if rider>=0:
		var car: Node3D=trains[rider].cars[0]
		world.player.global_position=car.global_position+Vector3.UP*0.85
		world.player.velocity=Vector3.ZERO
	if lift_station>=0: animate_lift(delta)

func pose(train: Dictionary) -> void:
	for i in range(train.cars.size()):
		var distance: float=train.distance+(-5.8 if i==0 else 5.8)
		var car: Node3D=train.cars[i]
		car.position=sample(train.line,distance)
		car.basis=Basis.looking_at(tangent(train.line,distance)*train.direction,Vector3.UP)
	var station: int=lines[train.line].stops[train.current_stop].station
	var platform_side=1 if train.cars[0].basis.x.dot(stations[station].platform-sample(train.line,train.distance))>0 else -1
	for door in train.doors: door.node.position.z=door.z+door.sign*train.door_ratio*0.7*(1 if door.side==platform_side else 0)

func stopped_at(train: Dictionary) -> int:
	if train.dwell<=0 or train.door_ratio<0.95: return -1
	return lines[train.line].stops[train.current_stop].station

func board(index: int) -> bool:
	if world.player.transit_mode: return false
	if rider>=0 or lift_station>=0 or world.interiors.inside or world.interiors.busy: return false
	var station=stopped_at(trains[index])
	if station<0 or not on_platform(station): return false
	rider=index
	ride_zoom=world.camera.zoom
	world.player.transit_mode=true
	world.player.velocity=Vector3.ZERO
	world.camera.overview=false
	world.camera.masterplan=false
	world.camera.zoom=0.7
	world.camera.target=world.player
	world.camera.instant=true
	for roof in trains[index].roofs: roof.visible=false
	advance(0.0)
	return true

func alight() -> bool:
	if rider<0: return false
	var train: Dictionary=trains[rider]
	var station=stopped_at(train)
	if station<0: return false
	for roof in train.roofs: roof.visible=true
	rider=-1
	world.player.transit_mode=false
	world.player.teleport(stations[station].platform)
	world.camera.zoom=ride_zoom
	world.camera.instant=true
	return true

func use_lift(index: int,up: bool) -> bool:
	if world.player.transit_mode: return false
	if rider>=0 or lift_station>=0 or world.interiors.inside or world.interiors.busy: return false
	var station: Dictionary=stations[index]
	var start: Vector3=station.ground if up else station.upper
	if world.player.global_position.distance_to(start)>4.3: return false
	lift_station=index
	lift_clock=0
	lift_up=up
	lift_from=station.lift_low if up else station.lift_high
	lift_to=station.lift_high if up else station.lift_low
	lift_call_origin=station.lift.position
	lift_phase=0 if lift_call_origin.distance_to(lift_from)>0.1 else 1
	world.player.transit_mode=true
	world.player.velocity=Vector3.ZERO
	world.camera.overview=false
	world.camera.masterplan=false
	world.camera.instant=true
	return true

func animate_lift(delta: float) -> void:
	lift_clock+=delta
	var station: Dictionary=stations[lift_station]
	if lift_phase==0:
		var call_duration=maxf(1.0,lift_call_origin.distance_to(lift_from)/8.0)
		var call_ratio=clampf(lift_clock/call_duration,0,1)
		station.lift.position=lift_call_origin.lerp(lift_from,smoothstep(0,1,call_ratio))
		if call_ratio>=1: lift_phase=1; lift_clock=0
		return
	var duration=maxf(2.5,absf(lift_to.y-lift_from.y)/6.0)
	var ratio=clampf(lift_clock/duration,0,1)
	station.lift.position=lift_from.lerp(lift_to,smoothstep(0,1,ratio))
	world.player.global_position=station.lift.position+Vector3.UP*0.15
	if ratio>=1:
		world.player.transit_mode=false
		world.player.teleport(station.upper if lift_up else station.ground)
		lift_station=-1

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.physical_keycode==KEY_T:
		route_panel.visible=not route_panel.visible
		if route_panel.visible and world.buses: world.buses.route_panel.visible=false
		get_viewport().set_input_as_handled()
		return
	if event.physical_keycode!=KEY_F or world.player.paused or world.interiors.inside or world.interiors.busy: return
	if world.player.transit_mode and rider<0 and lift_station<0: return
	if rider>=0: alight(); get_viewport().set_input_as_handled(); return
	if lift_station>=0: return
	for i in range(stations.size()):
		if world.player.global_position.distance_to(stations[i].ground)<4.3:
			use_lift(i,true); get_viewport().set_input_as_handled(); return
		if world.player.global_position.distance_to(stations[i].upper)<2.5:
			use_lift(i,false); get_viewport().set_input_as_handled(); return
	var candidate=boarding_candidate()
	if candidate>=0 and board(candidate): get_viewport().set_input_as_handled()

func on_platform(index: int) -> bool:
	# Anywhere on the 36 m platform counts, not just its centre point.
	var local: Vector3=stations[index].root.to_local(world.player.global_position)
	return absf(local.x)<3.2 and absf(local.z)<18.5 and absf(local.y)<2.5

func boarding_candidate() -> int:
	var selected=-1
	var best=INF
	for i in range(trains.size()):
		var station=stopped_at(trains[i])
		if station<0 or not on_platform(station): continue
		var rail=sample(trains[i].line,trains[i].distance)
		var side: Vector3=rail-stations[station].platform
		side.y=0
		var point: Vector3=stations[station].platform+side.normalized()*1.1
		var score=world.player.global_position.distance_to(point)
		if score<best: selected=i; best=score
	return selected

func eta(station_index: int,line: String) -> float:
	var best=INF
	var data: Dictionary=lines[line]
	for train in trains:
		if train.line!=line: continue
		if stopped_at(train)==station_index: return 0.0
		var estimate=maxf(0,train.dwell)
		var previous: float=train.distance
		var cursor: int=train.next_stop
		var direction: int=train.direction
		for hop in range(data.stops.size()*2+1):
			var stop: Dictionary=data.stops[cursor]
			var distance=fposmod(stop.distance-previous,data.length) if data.closed else absf(stop.distance-previous)
			estimate+=distance/MAX_SPEED+2.0
			if stop.station==station_index: best=minf(best,estimate); break
			estimate+=DWELL
			previous=stop.distance
			if not data.closed and cursor in [0,data.stops.size()-1]: direction=1 if cursor==0 else -1
			cursor=posmod(cursor+direction,data.stops.size())
	return best

func _process(delta: float) -> void:
	for station in stations:
		var canopy=station.root.get_node("PlatformCanopy")
		canopy.visible=world.player.global_position.distance_to(station.platform)>23
	if world.interiors.inside: prompt.text=""; return
	if world.player.transit_mode and rider<0 and lift_station<0: prompt.text=""
	elif lift_station>=0: prompt.text="SKYTRAIN LIFT  /  "+("Lift arriving" if lift_phase==0 else ("Up to platform" if lift_up else "Down to street"))
	elif rider>=0:
		var train: Dictionary=trains[rider]
		var current=stopped_at(train)
		var next_station: int=lines[train.line].stops[train.next_stop].station
		prompt.text=("[F] Alight at "+station_title(current)) if current>=0 else (lines[train.line].name+"  /  Next: "+station_title(next_station))
	else:
		prompt.text=""
		for i in range(stations.size()):
			var station: Dictionary=stations[i]
			if world.player.global_position.distance_to(station.ground)<5: prompt.text="[F] Lift to "+station.title+" skytrain platform"; break
			if world.player.global_position.distance_to(station.upper)<3: prompt.text="[F] Lift down to street"; break
			if on_platform(i):
				var candidate=boarding_candidate()
				prompt.text=("[F] Board "+lines[trains[candidate].line].name) if candidate>=0 else "Wait behind the yellow line"
				if transfer_stations.has(i):
					var connection: Dictionary=stations[transfer_stations[i]]
					prompt.text+="  /  Walk to "+lines[connection.line].name+" via transfer ramp"
				else:
					prompt.text+="  /  [T] Arrivals"
				break
	update_clock+=delta
	if update_clock<0.5: return
	update_clock=0
	var nearest=0
	var nearest_distance=INF
	for i in range(stations.size()):
		var offset: Vector3=stations[i].ground-world.player.global_position
		var distance=Vector2(offset.x,offset.z).length()
		if distance<nearest_distance: nearest_distance=distance; nearest=i
	var delta_to_lift: Vector3=stations[nearest].ground-world.player.global_position
	var direction=("east" if delta_to_lift.x>0 else "west") if absf(delta_to_lift.x)>absf(delta_to_lift.z) else ("south" if delta_to_lift.z>0 else "north")
	var route="SKYTRAIN  /  ELEVATED SERVICE\n[F] Lift / board / alight     [T] Close\n"
	route+="Nearest lift: "+stations[nearest].code+"  "+str(ceili(nearest_distance))+" m "+direction+"\n"
	for line in lines:
		route+="\n"+line+"  "+lines[line].name+("  (clockwise)" if lines[line].closed else "  (both directions)")+"\n"
		for stop in lines[line].stops:
			var index: int=stop.station
			var station: Dictionary=stations[index]
			var seconds=eta(index,line)
			var arrival="boarding" if seconds<0.5 else "~%ds"%ceili(seconds)
			station.led.text=line+": "+arrival
			route+=station.code+"  "+station_title(index)+"  "+arrival+"\n"
	route+="\nTransfer ramp: C4 YUST Gate ↔ M5 Central Avenue."
	route+="\nFree service. All stations have lifts.\nBoard only while doors are open.\n"
	for train in trains:
		var next_station: int=lines[train.line].stops[train.next_stop].station
		route+="\n"+("City train" if train.line=="C" else "Market shuttle")+" > "+stations[next_station].title
	route_text.text=route
	for i in range(stations.size()):
		for gate in stations[i].gates:
			var open=false
			for train in trains:
				if train.line==gate.get_meta("service") and stopped_at(train)==i: open=true
			gate.scale.z=0.12 if open else 1.0

func station_title(index: int) -> String:
	var title: String=stations[index].title
	return title+" (transfer)" if transfer_stations.has(index) else title

func _ui() -> void:
	var layer=CanvasLayer.new()
	layer.layer=35
	add_child(layer)
	prompt=Label.new()
	prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	prompt.position=Vector2(24,-150)
	prompt.add_theme_font_size_override("font_size",20)
	prompt.add_theme_color_override("font_color",Color("9de7df"))
	prompt.add_theme_color_override("font_shadow_color",Color("132532"))
	prompt.add_theme_constant_override("shadow_offset_x",2)
	prompt.add_theme_constant_override("shadow_offset_y",2)
	layer.add_child(prompt)
	route_panel=PanelContainer.new()
	route_panel.position=Vector2(30,110)
	route_panel.custom_minimum_size=Vector2(440,500)
	route_panel.visible=false
	var style=StyleBoxFlat.new()
	style.bg_color=Color(0.035,0.08,0.105,0.96)
	style.border_color=Color("527d88")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left=16
	style.content_margin_right=16
	style.content_margin_top=12
	style.content_margin_bottom=12
	route_panel.add_theme_stylebox_override("panel",style)
	layer.add_child(route_panel)
	route_text=Label.new()
	route_text.add_theme_font_size_override("font_size",17)
	route_panel.add_child(route_text)

func make_chime() -> AudioStreamWAV:
	var rate=22050
	var duration=0.44
	var data=PackedByteArray()
	data.resize(int(rate*duration)*2)
	for i in range(int(rate*duration)):
		var time=float(i)/rate
		var phase=fposmod(time,0.22)
		var frequency=660.0 if time<0.22 else 880.0
		var value=sin(TAU*frequency*time)*sin(PI*phase/0.22)*0.18
		data.encode_s16(i*2,int(value*32767))
	var sound=AudioStreamWAV.new()
	sound.format=AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate=rate
	sound.data=data
	return sound
