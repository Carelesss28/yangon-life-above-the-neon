extends Node3D
## Regular electric buses on the existing road graph; all trips happen in-world.
const Roads=preload("res://scripts/road_layout.gd")
const Layout=preload("res://scripts/terrain_layout.gd")
const MAX_SPEED=14.0
const ACCEL=2.4
const BRAKE=4.2
const DWELL=8.0
var world
var b
var routes={}
var stops: Array=[]
var vehicles: Array=[]
var rider=-1
var saved_zoom=1.0
var reservations={}
var prompt: Label
var route_panel: PanelContainer
var route_text: Label
var ui_clock=0.0
var sim_clock=0.0
var white: Material
var glass: Material
var metal: Material
var amber: Material
var cyan: Material

func _ready() -> void:
	name="RegularBusService"
	b=load("res://scripts/reference_buildings.gd").new()
	b.world=world
	white=world._mat("b8c9c3",0.55)
	glass=world._mat("294f62",0.3)
	metal=world._mat("3a515a")
	amber=world._mat("ffd29b",0.5,1.6)
	cyan=world._mat("8adfd7",0.5,1.2)
	add_route("B1","SEAFRONT CIRCUIT",chain([Vector2(42.25,235),Vector2(809.86,235),Vector2(809.86,560),Vector2(42.25,560)]),"57ae91")
	add_route("B2","DOWNTOWN - MARKET",chain([Vector2(302.82,235),Vector2(302.82,920),Vector2(577.46,920),Vector2(577.46,235)]),"d3a163")
	add_route("B3","HOME TERRACES",chain([Vector2(42.25,320),Vector2(169.01,320),Vector2(169.01,480),Vector2(42.25,480)]),"9683b3")
	add_route("B4","CAMPUS - HARBOUR",chain([Vector2(577.46,560),Vector2(809.86,560),Vector2(809.86,920),Vector2(577.46,920)]),"e0708a")
	add_stop("B1","Promenade West",Vector2(211.27,235),"Beach / Skytrain C8")
	add_stop("B1","Seafront Central",Vector2(457.75,235),"Ferris wheel / Skytrain C1")
	add_stop("B1","Harbour",Vector2(640.85,235),"Piers / ferry / Skytrain C2")
	add_stop("B1","Harbour East",Vector2(809.86,440),"Docks / Skytrain C3")
	add_stop("B1","YUST Gate",Vector2(669.01,560),"Campus gate / Skytrain C4")
	add_stop("B1","Market North",Vector2(422.54,560),"Market halls / Skytrain C5")
	add_stop("B1","Home Terraces",Vector2(105.63,560),"Botanical garden / Skytrain C6")
	add_stop("B1","Canal West",Vector2(42.25,440),"Home district / Skytrain C7")
	add_stop("B2","Downtown West",Vector2(302.82,280),"Library / city hall")
	add_stop("B2","Central Park",Vector2(302.82,440),"Park / hospital")
	add_stop("B2","Market West",Vector2(302.82,620),"Market halls")
	add_stop("B2","Hill Gate",Vector2(302.82,770),"Hill park / reservoir trail")
	add_stop("B2","Market South",Vector2(436.62,920),"Night market")
	add_stop("B2","Campus West",Vector2(577.46,840),"YUST labs / Skytrain M4")
	add_stop("B2","Downtown East",Vector2(577.46,360),"Offices / Skytrain M1")
	add_stop("B3","Family Cafe",Vector2(105.63,320),"Rooftop cafe / tea shops")
	add_stop("B3","Canal Bridge",Vector2(130.0,320),"Home canal")
	add_stop("B3","Upper Terraces",Vector2(105.63,480),"Apartments / school")
	add_stop("B3","West Lane",Vector2(42.25,400),"Corner shops")
	add_stop("B4","Campus North",Vector2(760.56,560),"Dorms / pond")
	add_stop("B4","Campus East",Vector2(809.86,740),"Dorms / clubs")
	add_stop("B4","Campus South",Vector2(704.23,920),"Student union")
	add_stop("B4","Launch Bay",Vector2(577.46,700),"Mecha launch bay")
	for line in routes:
		routes[line].stops.sort_custom(func(a,c):return a.distance<c.distance)
		var count=2 if line in ["B3","B4"] else 4
		for i in range(count): spawn_bus(line,float(i)/count*routes[line].length)
	_ui()
	print("BUS_SERVICE_READY routes=",routes.size()," stops=",stops.size()," buses=",vehicles.size())

func chain(corners: Array) -> Array:
	# Expands a closed list of axis-aligned corner points into consecutive road-graph node keys.
	var keys: Array=[]
	for i in range(corners.size()):
		var a: Vector2=corners[i]
		var b: Vector2=corners[(i+1)%corners.size()]
		var found: Array=[]
		for key in Roads.NODES:
			var p: Vector3=Roads.NODES[key]
			var q=Vector2(p.x,p.z)
			var on_line=(absf(a.x-b.x)<0.5 and absf(q.x-a.x)<0.5 and q.y>=minf(a.y,b.y)-0.5 and q.y<=maxf(a.y,b.y)+0.5) or (absf(a.y-b.y)<0.5 and absf(q.y-a.y)<0.5 and q.x>=minf(a.x,b.x)-0.5 and q.x<=maxf(a.x,b.x)+0.5)
			if on_line: found.append([q.distance_to(a),key])
		found.sort_custom(func(m,n): return m[0]<n[0])
		for j in range(found.size()-1):
			if keys.is_empty() or keys.back()!=found[j][1]: keys.append(found[j][1])
	return keys

func road_width(a: String,c: String) -> float:
	for edge in Roads.EDGES:
		if edge==[a,c] or edge==[c,a]: return Roads.width(edge)
	return 0.0

func add_route(code: String,title: String,nodes: Array,colour: String) -> void:
	var curve=Curve3D.new()
	curve.bake_interval=0.5
	for i in range(nodes.size()):
		var previous: Vector3=Roads.NODES[nodes[posmod(i-1,nodes.size())]]
		var point: Vector3=Roads.NODES[nodes[i]]
		var next: Vector3=Roads.NODES[nodes[(i+1)%nodes.size()]]
		var incoming=(point-previous); incoming.y=0; incoming=incoming.normalized()
		var outgoing=(next-point); outgoing.y=0; outgoing=outgoing.normalized()
		var in_right=Vector3(-incoming.z,0,incoming.x)
		var out_right=Vector3(-outgoing.z,0,outgoing.x)
		var in_width=road_width(nodes[posmod(i-1,nodes.size())],nodes[i])
		var out_width=road_width(nodes[i],nodes[(i+1)%nodes.size()])
		assert(in_width>0 and out_width>0,"Bus routes must follow connected road edges")
		if incoming.dot(outgoing)>0.99:
			curve.add_point(point+out_right*out_width*0.25+Vector3.UP*0.12)
		else:
			var corner_trim=3.0 if nodes[i]=="s" else 7.5
			var trim_in=minf(corner_trim,Vector2(point.x-previous.x,point.z-previous.z).length()*0.25)
			var trim_out=minf(corner_trim,Vector2(next.x-point.x,next.z-point.z).length()*0.25)
			var entry=point-incoming*trim_in+in_right*in_width*0.25+Vector3.UP*0.12
			var exit=point+outgoing*trim_out+out_right*out_width*0.25+Vector3.UP*0.12
			var intersection=Geometry2D.line_intersects_line(Vector2(entry.x,entry.z),Vector2(incoming.x,incoming.z),Vector2(exit.x,exit.z),Vector2(outgoing.x,outgoing.z))
			var reach_in=trim_in
			var reach_out=trim_out
			if intersection!=null:
				reach_in=Vector2(entry.x,entry.z).distance_to(intersection)
				reach_out=Vector2(exit.x,exit.z).distance_to(intersection)
			curve.add_point(entry,Vector3.ZERO,incoming*reach_in*0.55)
			curve.add_point(exit,-outgoing*reach_out*0.55,Vector3.ZERO)
	curve.add_point(curve.get_point_position(0),Vector3.ZERO,curve.get_point_out(0))
	routes[code]={"name":title,"curve":curve,"length":curve.get_baked_length(),"stops":[],"nodes":nodes,"material":world._mat(colour)}

func base_position(line: String,distance: float) -> Vector3:
	var data: Dictionary=routes[line]
	var p: Vector3=data.curve.sample_baked(fposmod(distance,data.length),true)
	var road=Roads.sample(p.x,p.z)
	if not road.is_empty(): p.y=road.y+0.12
	return p

func base_forward(line: String,distance: float) -> Vector3:
	var direction=base_position(line,distance+0.5)-base_position(line,distance-0.5)
	direction.y=0
	return direction.normalized()

func position_on_route(line: String,distance: float) -> Vector3:
	var data: Dictionary=routes[line]
	var p=base_position(line,distance)
	var forward=base_forward(line,distance)
	var right=Vector3(-forward.z,0,forward.x)
	var closest=INF
	var shift=0.0
	for stop in data.stops:
		var offset=absf(fposmod(stop.distance-distance+data.length/2,data.length)-data.length/2)
		if offset<closest:
			closest=offset
			shift=stop.dock_shift*(1.0-smoothstep(8.0,35.0,offset))
	p+=right*shift
	var road=Roads.sample(p.x,p.z)
	if not road.is_empty(): p.y=road.y+0.12
	return p

func closest_offset(line: String,point: Vector2) -> float:
	var best=INF
	var result=0.0
	for i in range(ceili(routes[line].length)):
		var p=base_position(line,i)
		var distance=Vector2(p.x,p.z).distance_squared_to(point)
		if distance<best: best=distance; result=float(i)
	return result

func box(parent: Node3D,p: Vector3,size: Vector3,mat: Material,title: String,solid=false) -> MeshInstance3D:
	return b.box(parent,p,size,mat,title,solid)

func label(parent: Node3D,value: String,p: Vector3,pixel_size=0.015) -> Label3D:
	var text=Label3D.new()
	text.text=value
	text.position=p
	text.font_size=32
	text.pixel_size=pixel_size
	text.modulate=Color("e2f2e8")
	parent.add_child(text)
	return text

func _stop_spot_ok(line: String,distance: float) -> bool:
	if distance<0.0 or distance>routes[line].length: return false
	var road_point=base_position(line,distance)
	var forward=base_forward(line,distance)
	var right=Vector3(-forward.z,0,forward.x)
	var road=Roads.sample(road_point.x,road_point.z)
	if road.is_empty() or road.get("mountain",false): return false
	var half: float=road.half
	for along in [-9.0,-4.5,0.0,4.5,9.0,13.0,17.0]:
		# Level across the pavement (a gentle slope along the street is fine).
		var kerb=road_point+forward*along+right*(half+0.4)
		var ref=Layout.height_at(kerb.x,kerb.z)
		for side in [0.4,1.9,3.3]:
			var p=road_point+forward*along+right*(half+side)
			if Layout.wet(p.x,p.z) or not Layout.channel_sample(p.x,p.z).is_empty(): return false
			if absf(Layout.height_at(p.x,p.z)-ref)>0.35: return false
			if side>1.0 and not Roads.sample(p.x,p.z).is_empty(): return false   # keep clear of junctions
			for entry in world.building_plots:
				if Rect2(entry.plot).has_point(Vector2(p.x,p.z)): return false
	return true

func add_stop(line: String,title: String,target: Vector2,connection: String) -> void:
	# Platform on the pavement just behind the kerb (roads are 8-10 m since the cozy re-layout). Slide
	# along the route to the nearest spot where the whole platform is flat, dry and clear of buildings.
	var base_distance=closest_offset(line,target)
	var distance=base_distance
	for k in range(31):
		var off=float((k+1)/2)*3.0*(1.0 if k%2==1 else -1.0)
		if _stop_spot_ok(line,base_distance+off):
			distance=base_distance+off
			break
	var road_point=base_position(line,distance)
	var forward=base_forward(line,distance)
	var right=Vector3(-forward.z,0,forward.x)
	var road=Roads.sample(road_point.x,road_point.z)
	var half: float=road.half
	var queue=road_point+right*(half+1.9)
	queue.y=Layout.height_at(queue.x,queue.z)+0.02   # flush with the pavement: no lip to step over
	var dock_shift=half-1.35-half*0.5
	for i in range(stops.size()):
		if stops[i].title==title and stops[i].queue.distance_to(queue)<3 or stops[i].queue.distance_to(queue)<18:
			stops[i].lines.append(line)
			routes[line].stops.append({"stop":i,"distance":distance,"dock_shift":dock_shift})
			return
	var stop=Node3D.new()
	stop.name="BusStop_"+str(stops.size()+1)
	stop.position=queue
	stop.basis=Basis.looking_at(forward,Vector3.UP)
	add_child(stop)
	for z in [-6,6]:
		var p=stop.to_global(Vector3(0,0,z))
		var ground=Layout.height_at(p.x,p.z)
		if queue.y-ground>0.4:
			box(self,Vector3(p.x,(queue.y+ground)/2,p.z),Vector3(0.35,queue.y-ground,0.35),metal,"BusBaySupport")
	box(stop,Vector3(0,-0.01,0),Vector3(3.5,0.06,16),white,"BoardingPlatform")   # flush paving slab, walk-through
	box(stop,Vector3(-1.55,0.04,0),Vector3(0.15,0.05,15),amber,"CurbSafetyLine")
	box(stop,Vector3(0.7,3.05,0),Vector3(3.6,0.18,14),routes[line].material,"BusShelterRoof")
	for z in [-6,6]: box(stop,Vector3(1.6,1.5,z),Vector3(0.14,3,0.14),metal,"ShelterColumn")
	for z in [-4,4]:
		box(stop,Vector3(1.6,1.4,z),Vector3(0.10,2.8,4),glass,"ShelterBack")
		box(stop,Vector3(0.9,0.55,z),Vector3(0.65,0.15,2.4),white,"BenchSeat")
		box(stop,Vector3(1.25,0.9,z),Vector3(0.1,0.8,2.4),white,"BenchBack")
	var sign=label(stop,"BUS  /  "+title,Vector3(-0.2,3.6,0),0.018)
	sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	var arrivals=label(stop,"Arrivals",Vector3(0.3,2.4,-5),0.012)
	arrivals.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	var emitter=box(stop,Vector3(0.5,2.9,0),Vector3(1.8,0.08,0.12),amber,"emit_shelter_light")
	emitter.add_to_group("city_lamp_emitters")
	var light=OmniLight3D.new()
	light.position=Vector3(0.4,2.7,0)
	light.omni_range=11
	light.light_color=Color("ffc98f")
	light.set_meta("night_energy",1.4)
	light.light_energy=1.4 if world.night else 0
	stop.add_child(light)
	world.lamps.append(light)
	# Connect raised road decks and their curb platforms to actual ground level.
	# The platform sits on the pavement, so the access path runs along the pavement (not into the plots).
	var start=queue+forward*8.0
	var run=6.0
	for i in range(4):
		var end=start+forward*run
		run=maxf(run,absf(start.y-Layout.height_at(end.x,end.z))*2.8+3.0)
	var access=start+forward*run
	var needs_ramp=false   # platforms sit on the pavement at ground level now
	access.y=Layout.height_at(access.x,access.z)+0.06
	if not needs_ramp:
		access=queue+forward*9.0
		access.y=Layout.height_at(access.x,access.z)+0.06
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps=ceili(run/0.75) if needs_ramp else 0
	for i in range(steps):
		var p=start.lerp(access,float(i)/steps)
		var q=start.lerp(access,float(i+1)/steps)
		p.y=lerpf(start.y,access.y,clampf((float(i)/steps*run-3.0)/(run-3.0),0,1))
		q.y=lerpf(start.y,access.y,clampf((float(i+1)/steps*run-3.0)/(run-3.0),0,1))
		p.y=maxf(p.y,Layout.height_at(p.x,p.z)+0.06)
		q.y=maxf(q.y,Layout.height_at(q.x,q.z)+0.06)
		for point in [p-right*1.4,p+right*1.4,q-right*1.4,p+right*1.4,q+right*1.4,q-right*1.4]:
			st.add_vertex(point)
	if needs_ramp:
		st.generate_normals()
		var ramp=world._mesh_node(st.commit(),world.mats.paving,"BusStopAccessRamp",true)
		ramp.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.grass_exclusions.append(Rect2(Vector2(queue.x-8,queue.z-8),Vector2(16,16)))
	var index=stops.size()
	stops.append({"title":title,"lines":[line],"queue":queue+Vector3.UP*0.06,"access":access+Vector3.UP*0.06,"root":stop,"arrivals":arrivals,"connection":connection})
	routes[line].stops.append({"stop":index,"distance":distance,"dock_shift":dock_shift})

func spawn_bus(line: String,distance: float) -> void:
	var bus=AnimatableBody3D.new()
	bus.name="ElectricBus_"+str(vehicles.size()+1)
	bus.sync_to_physics=false
	add_child(bus)
	var collision=CollisionShape3D.new()
	var shape=BoxShape3D.new()
	shape.size=Vector3(2.4,2.7,8.6)
	collision.shape=shape
	collision.position.y=1.4
	bus.add_child(collision)
	box(bus,Vector3(0,0.45,0),Vector3(2.4,0.16,8.6),metal,"LowFloor")
	for side in [-1,1]:
		box(bus,Vector3(side*1.15,0.95,0),Vector3(0.12,0.85,8.6),routes[line].material,"BodySide")
		box(bus,Vector3(side*1.15,2.7,0),Vector3(0.12,0.25,8.6),white,"WindowHeader")
		box(bus,Vector3(side*1.21,1.9,0),Vector3(0.08,1.25,7.9),glass,"SideWindows")
		for z in [-2.5,2.5]:
			var wheel=b.cylinder(bus,Vector3(side*1.2,0.4,z),0.4,0.2,metal,"Wheel")
			wheel.rotation.z=PI/2
		for z in [-1,1,2.5]:
			box(bus,Vector3(side*0.8,0.95,z),Vector3(0.55,0.18,0.9),white,"PassengerSeat")
	for z in [-4.35,4.35]:
		box(bus,Vector3(0,1.9,z),Vector3(2.2,1.25,0.1),glass,"EndWindow")
		box(bus,Vector3(0,0.95,z),Vector3(2.4,0.7,0.1),routes[line].material,"EndBody")
	var doors=[]
	for side in [-1,1]:
		var door=box(bus,Vector3(1.27,1.6,-2.5+side*0.4),Vector3(0.1,2.1,0.75),white,"SlidingDoor")
		doors.append({"node":door,"z":door.position.z,"sign":side})
	var roof=box(bus,Vector3(0,2.95,0),Vector3(2.5,0.25,8.8),white,"roof")
	var battery=box(bus,Vector3(0,3.2,0.8),Vector3(1.5,0.3,3),metal,"RoofBattery")
	for x in [-0.85,0.85]: box(bus,Vector3(x,0.95,-4.45),Vector3(0.35,0.13,0.08),amber,"emit_headlight")
	var destination=label(bus,line,Vector3(0,2.4,-4.42),0.006)
	destination.rotation.y=PI
	var data: Dictionary=routes[line]
	var next=0
	for i in range(data.stops.size()):
		if data.stops[i].distance>distance: next=i; break
	vehicles.append({"root":bus,"line":line,"distance":distance,"speed":0.0,"next_stop":next,"current_stop":-1,"dwell":0.0,"door_ratio":0.0,"doors":doors,"roofs":[roof,battery],"destination":destination,"blocked":false})
	pose(vehicles.back())

func _physics_process(delta: float) -> void:
	if not world.player.paused: advance(delta)

func reserve_junctions() -> void:
	for key in reservations.keys():
		var owner: int=reservations[key]
		var p: Vector3=vehicles[owner].root.position
		if Vector2(p.x-Roads.NODES[key].x,p.z-Roads.NODES[key].z).length()>36: reservations.erase(key)
	for key in Roads.NODES:
		if reservations.has(key): continue
		var nearest=-1
		var best=30.0
		for i in range(vehicles.size()):
			var bus: Dictionary=vehicles[i]
			if key not in routes[bus.line].nodes: continue
			var p: Vector3=bus.root.position
			var distance=Vector2(p.x-Roads.NODES[key].x,p.z-Roads.NODES[key].z).length()
			if distance<best: best=distance; nearest=i
		if nearest>=0: reservations[key]=nearest

func advance(delta: float) -> void:
	sim_clock+=delta
	reserve_junctions()
	for i in range(vehicles.size()):
		var bus: Dictionary=vehicles[i]
		var route: Dictionary=routes[bus.line]
		bus.blocked=false
		if bus.dwell>0:
			bus.dwell=maxf(0,bus.dwell-delta)
			bus.speed=0.0
			bus.door_ratio=clampf(minf(DWELL-bus.dwell,bus.dwell)/0.55,0,1)
		else:
			bus.door_ratio=0.0
			var target: float=route.stops[bus.next_stop].distance
			var remaining=fposmod(target-bus.distance,route.length)
			var desired=minf(MAX_SPEED,sqrt(maxf(0,2*BRAKE*remaining)))
			var forward=base_forward(bus.line,bus.distance)
			var ahead=base_forward(bus.line,bus.distance+12)
			if forward.dot(ahead)<0.95: desired=minf(desired,4.5)
			var right=Vector3(-forward.z,0,forward.x)
			# Junction reservations (sized for the 1000 m town's tighter grid). A bus held for more than
			# 5 s goes anyway, so two buses can never wait on each other's junction forever.
			for key in route.nodes:
				if bus.get("held",0.0)>5.0: break
				if not reservations.has(key) or reservations[key]==i: continue
				var to_node: Vector3=Roads.NODES[key]-bus.root.position
				if to_node.dot(forward)>0:
					var distance=Vector2(to_node.x,to_node.z).length()
					if distance<30: desired=minf(desired,sqrt(maxf(0,2*BRAKE*(distance-12))))
			var safe_step=INF
			for j in range(vehicles.size()):
				if j==i: continue
				var offset: Vector3=vehicles[j].root.position-bus.root.position
				var longitudinal=offset.dot(forward)
				if longitudinal>0 and absf(offset.dot(right))<2.7 and absf(offset.y)<1.7:
					safe_step=minf(safe_step,maxf(0,longitudinal-11))
					desired=minf(desired,sqrt(maxf(0,2*BRAKE*(longitudinal-12))))
			if not world.player.transit_mode:
				var offset: Vector3=world.player.position-bus.root.position
				var longitudinal=offset.dot(forward)
				if longitudinal>0 and absf(offset.dot(right))<1.8 and absf(offset.y)<2:
					desired=minf(desired,sqrt(maxf(0,2*BRAKE*(longitudinal-8))))
			bus.blocked=desired<0.1 and remaining>2
			bus["held"]=bus.get("held",0.0)+delta if bus.blocked else 0.0
			bus.speed=move_toward(bus.speed,desired,(BRAKE if desired<bus.speed else ACCEL)*delta)
			var step=minf(bus.speed*delta,safe_step)
			if remaining<=step+0.0001:
				bus.distance=target
				bus.current_stop=bus.next_stop
				bus.next_stop=(bus.next_stop+1)%route.stops.size()
				bus.dwell=DWELL
				bus.speed=0.0
			else: bus.distance=fposmod(bus.distance+step,route.length)
		pose(bus)
	if rider>=0:
		world.player.position=vehicles[rider].root.to_global(Vector3(0,0.55,0))
		world.player.velocity=Vector3.ZERO

func pose(bus: Dictionary) -> void:
	var p=position_on_route(bus.line,bus.distance)
	var forward=position_on_route(bus.line,bus.distance+0.5)-position_on_route(bus.line,bus.distance-0.5)
	bus.root.position=p
	bus.root.basis=Basis.looking_at(forward.normalized(),Vector3.UP)
	for door in bus.doors: door.node.position.z=door.z+door.sign*bus.door_ratio*0.65
	var stop: int=routes[bus.line].stops[bus.next_stop].stop
	bus.destination.text=bus.line+"  "+str(stops[stop].title).to_upper()

func stopped_at(bus: Dictionary) -> int:
	if bus.current_stop<0 or bus.dwell<=0 or bus.door_ratio<0.95: return -1
	return routes[bus.line].stops[bus.current_stop].stop

func candidate() -> int:
	var selected=-1
	var best=5.0
	for i in range(vehicles.size()):
		var stop=stopped_at(vehicles[i])
		if stop<0: continue
		var distance=world.player.position.distance_to(stops[stop].queue)
		if distance<best: selected=i; best=distance
	return selected

func board(index: int) -> bool:
	if rider>=0 or world.player.transit_mode or world.interiors.inside or world.interiors.busy: return false
	var stop=stopped_at(vehicles[index])
	if stop<0 or world.player.position.distance_to(stops[stop].queue)>5: return false
	rider=index
	saved_zoom=world.camera.zoom
	world.player.transit_mode=true
	world.player.velocity=Vector3.ZERO
	world.camera.overview=false
	world.camera.masterplan=false
	world.camera.target=world.player
	world.camera.zoom=0.6
	world.camera.instant=true
	for roof in vehicles[index].roofs: roof.visible=false
	advance(0)
	return true

func alight() -> bool:
	if rider<0: return false
	var stop=stopped_at(vehicles[rider])
	if stop<0: return false
	for roof in vehicles[rider].roofs: roof.visible=true
	rider=-1
	world.player.transit_mode=false
	world.player.teleport(stops[stop].queue)
	world.camera.zoom=saved_zoom
	world.camera.instant=true
	return true

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.physical_keycode==KEY_V:
		route_panel.visible=not route_panel.visible
		if route_panel.visible: world.skytrain.route_panel.visible=false
		get_viewport().set_input_as_handled()
		return
	if event.physical_keycode!=KEY_B or world.player.paused or world.interiors.inside or world.interiors.busy: return
	if rider>=0:
		alight(); get_viewport().set_input_as_handled(); return
	if world.player.transit_mode: return
	var bus=candidate()
	if bus>=0 and board(bus): get_viewport().set_input_as_handled()

func eta(stop_index: int,line: String) -> float:
	var best=INF
	var data: Dictionary=routes[line]
	for bus in vehicles:
		if bus.line!=line: continue
		if stopped_at(bus)==stop_index: return 0.0
		var time=maxf(0,bus.dwell)
		var previous: float=bus.distance
		for hop in range(data.stops.size()):
			var stop: Dictionary=data.stops[(bus.next_stop+hop)%data.stops.size()]
			time+=fposmod(stop.distance-previous,data.length)/11.0+4
			if stop.stop==stop_index: best=minf(best,time); break
			time+=DWELL
			previous=stop.distance
	return best

func _process(delta: float) -> void:
	prompt.text=""
	if rider>=0:
		var bus: Dictionary=vehicles[rider]
		var stop=stopped_at(bus)
		var next: int=routes[bus.line].stops[bus.next_stop].stop
		prompt.text=("[B] Alight at "+stops[stop].title) if stop>=0 else (bus.line+"  "+routes[bus.line].name+"  /  Next: "+stops[next].title+"  /  [V] Bus routes")
	elif not world.player.transit_mode and not world.interiors.inside:
		var selected=candidate()
		if selected>=0: prompt.text="[B] Board "+vehicles[selected].line+"  "+routes[vehicles[selected].line].name
		else:
			for stop in stops:
				if world.player.position.distance_to(stop.queue)<7: prompt.text="BUS  "+stop.title+"  /  [V] Arrivals  /  [B] Board when doors open"; break
	ui_clock+=delta
	if ui_clock<0.5: return
	ui_clock=0
	var nearest=0
	var nearest_distance=INF
	for i in range(stops.size()):
		var d=Vector2(stops[i].queue.x-world.player.position.x,stops[i].queue.z-world.player.position.z).length()
		if d<nearest_distance: nearest_distance=d; nearest=i
	var info="REGULAR ELECTRIC BUSES\n[B] Board / alight    [V] Close\nNearest stop: "+stops[nearest].title+"  "+str(ceili(nearest_distance))+" m\n"
	for line in routes:
		info+="\n"+line+"  "+routes[line].name+"\n"
		for entry in routes[line].stops:
			var seconds=eta(entry.stop,line)
			info+=stops[entry.stop].title+"  "+("boarding" if seconds<0.5 else "~%ds"%ceili(seconds))+"\n"
	for i in range(stops.size()):
		var text=[]
		for line in stops[i].lines:
			var seconds=eta(i,line)
			text.append(line+"  "+("boarding" if seconds<0.5 else "~%ds"%ceili(seconds)))
		stops[i].arrivals.text=" / ".join(text)
	info+="\nFree service. Use the stop's access path.\nGet off only while doors are open.\n[T] Skytrain map and connections"
	route_text.text=info

func _ui() -> void:
	var layer=CanvasLayer.new()
	layer.layer=36
	add_child(layer)
	prompt=Label.new()
	prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	prompt.position=Vector2(24,-150)
	prompt.add_theme_font_size_override("font_size",19)
	prompt.add_theme_color_override("font_color",Color("ffe1a7"))
	prompt.add_theme_color_override("font_shadow_color",Color("132532"))
	prompt.add_theme_constant_override("shadow_offset_x",2)
	prompt.add_theme_constant_override("shadow_offset_y",2)
	layer.add_child(prompt)
	route_panel=PanelContainer.new()
	route_panel.position=Vector2(30,105)
	route_panel.custom_minimum_size=Vector2(460,500)
	route_panel.visible=false
	var style=StyleBoxFlat.new()
	style.bg_color=Color(0.04,0.075,0.09,0.96)
	style.border_color=Color("8d9e87")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left=16
	style.content_margin_right=16
	style.content_margin_top=12
	style.content_margin_bottom=12
	route_panel.add_theme_stylebox_override("panel",style)
	layer.add_child(route_panel)
	var scroll=ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(450,620)
	route_panel.add_child(scroll)
	route_text=Label.new()
	route_text.add_theme_font_size_override("font_size",16)
	scroll.add_child(route_text)
