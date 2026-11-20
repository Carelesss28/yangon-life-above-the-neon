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
	add_route("B1","CITY CIRCUIT",["c","w","nw","n","ne_return","ne","e","se","s"],"57ae91")
	add_route("B2","MARKET EXPRESS",["c","w","nw","n","ne_return","market_return","market_sw","market_nw","market_ne","market_se","ne","e"],"d3a163")
	add_route("B3","HOME FEEDER",["home_nw","home_ne","home_e_mid","home_se","home_sw","home_w_mid"],"9683b3")
	for line in ["B1","B2"]:
		add_stop(line,"YUST Gate",Vector2(150,302),"Campus entrance")
		add_stop(line,"Campus West",Vector2(8,150),"Campus gardens")
		add_stop(line,"Tech Interchange",Vector2(610,150),"Skytrain C2 / Market Link")
	add_stop("B1","Lake Gardens",Vector2(610,450),"Skytrain C3")
	add_stop("B1","Riverfront",Vector2(450,616),"Promenade / Skytrain C4")
	add_stop("B1","Home Terraces",Vector2(302,480),"Home Feeder / Skytrain C5")
	add_stop("B2","Tech North",Vector2(550,8),"Student housing")
	add_stop("B2","Market South",Vector2(300,-360),"Market arrival plaza")
	add_stop("B2","Market Halls",Vector2(300,-680),"Northern market")
	add_stop("B2","Market East",Vector2(610,-500),"Market shops / skytrain")
	add_stop("B2","Tech Commons",Vector2(450,302),"Shops / tea / arcade")
	add_stop("B3","Home North",Vector2(150,365),"Local shops / tea")
	add_stop("B3","Home East",Vector2(270,450),"Residential courtyards")
	add_stop("B3","Home South",Vector2(150,550),"Gardens / City Circuit")
	add_stop("B3","Home West",Vector2(25,450),"Family rooftop cafe")
	for line in routes:
		routes[line].stops.sort_custom(func(a,c):return a.distance<c.distance)
		var count=2 if line=="B3" else 4
		for i in range(count): spawn_bus(line,float(i)/count*routes[line].length)
	_ui()
	print("BUS_SERVICE_READY routes=",routes.size()," stops=",stops.size()," buses=",vehicles.size())

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

func add_stop(line: String,title: String,target: Vector2,connection: String) -> void:
	var distance=closest_offset(line,target)
	var road_point=base_position(line,distance)
	var forward=base_forward(line,distance)
	var right=Vector3(-forward.z,0,forward.x)
	var road=Roads.sample(road_point.x,road_point.z)
	var half: float=road.half
	var queue=road_point+right*(half-half*0.5+1.5)
	var dock_shift=half-1.35-half*0.5
	for i in range(stops.size()):
		if stops[i].title==title and stops[i].queue.distance_to(queue)<3:
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
	box(stop,Vector3(0,-0.07,0),Vector3(3.5,0.14,16),white,"BoardingPlatform",true)
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
	var start=queue+right*1.0
	var run=10.0
	for i in range(4):
		var end=start+right*run
		run=maxf(run,absf(start.y-Layout.height_at(end.x,end.z))*2.8+3.0)
	var access=start+right*run
	access.y=Layout.height_at(access.x,access.z)+0.06
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps=ceili(run/0.75)
	for i in range(steps):
		var p=start.lerp(access,float(i)/steps)
		var q=start.lerp(access,float(i+1)/steps)
		p.y=lerpf(start.y,access.y,clampf((float(i)/steps*run-3.0)/(run-3.0),0,1))
		q.y=lerpf(start.y,access.y,clampf((float(i+1)/steps*run-3.0)/(run-3.0),0,1))
		p.y=maxf(p.y,Layout.height_at(p.x,p.z)+0.06)
		q.y=maxf(q.y,Layout.height_at(q.x,q.z)+0.06)
		for point in [p-forward*1.4,p+forward*1.4,q-forward*1.4,p+forward*1.4,q+forward*1.4,q-forward*1.4]:
			st.add_vertex(point)
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
		if Vector2(p.x-Roads.NODES[key].x,p.z-Roads.NODES[key].z).length()>58: reservations.erase(key)
	for key in Roads.NODES:
		if reservations.has(key): continue
		var nearest=-1
		var best=52.0
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
			for key in route.nodes:
				if not reservations.has(key) or reservations[key]==i: continue
				var to_node: Vector3=Roads.NODES[key]-bus.root.position
				if to_node.dot(forward)>0:
					var distance=Vector2(to_node.x,to_node.z).length()
					if distance<52: desired=minf(desired,sqrt(maxf(0,2*BRAKE*(distance-17))))
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
