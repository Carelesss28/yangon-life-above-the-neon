extends Node3D
## Town traffic: road cars and motorbikes (models from models/vehicles, CC-BY, see credits.json)
## driving on the right through the road graph; neon flying cars on sky lanes; ships at sea.
## Road vehicles keep their distance, stop for the player, and turn their lights on at night.
const Layout=preload("res://scripts/terrain_layout.gd")
const Roads=preload("res://scripts/road_layout.gd")
const CARS=["t_hilux","t_markii","t_tucson","t_hiace","t_crown","t_camry","t_wagonr","t_fit"]
const BIKES=["yz250","superDuke","cubC70","superCub"]
# Extra yaw (radians) per model so every model drives nose-first; filled in after the review shot.
const YAW_FIX={"t_hilux":PI,"t_markii":PI,"t_tucson":PI,"t_hiace":PI,"t_crown":PI,"t_camry":PI,"t_wagonr":PI,"t_fit":PI,"yz250":PI,"superDuke":PI,"cubC70":PI,"superCub":PI,"hdPolice":PI}
const LENGTHS={"hdPolice":2.4,"t_hilux":5.3,"t_markii":4.8,"t_tucson":4.5,"t_hiace":5.3,"t_crown":4.7,"t_camry":4.8,"t_wagonr":3.4,"t_fit":3.9,"yz250":2.2,"superDuke":2.1,"cubC70":1.9,"superCub":1.9}
var world
var rng=RandomNumberGenerator.new()
var scenes={}
var adjacency={}
var road: Array=[]
var flyers: Array=[]
var ships: Array=[]
var lights: Array=[]
var counts={"cars":0,"bikes":0,"flying":0,"ships":0,"signals":0,"police_posts":0,"cameras":0,"patrol":0,"fire":0}
# ---- rules of the road
const CYCLE=[["ns","green",13.0],["ns","yellow",4.0],["all","red",1.5],["ew","green",13.0],["ew","yellow",4.0],["all","red",1.5]]
const MAIN_LIMIT=13.9    # 50 km/h on 16 m avenues
const LOCAL_LIMIT=11.1   # 40 km/h on local streets
const HILL_LIMIT=8.3     # 30 km/h on the hill road
var signals={}
var sig_clock=0.0
var lamp_mats={}
var posts: Array=[]
var by_edge={}
var walkers: PackedVector3Array=PackedVector3Array()
var violations={"red light":0,"speeding":0}

func _ready() -> void:
	name="TownTraffic"
	rng.seed=2026112003
	for edge in Roads.EDGES:
		for i in [0,1]:
			var k: String=edge[i]
			if not adjacency.has(k): adjacency[k]=[]
			adjacency[k].append(edge[1-i])
	for n in CARS+BIKES:
		var path="res://models/vehicles/%s.glb"%n
		if ResourceLoader.exists(path): scenes[n]=load(path)
	if ResourceLoader.exists("res://models/vehicles/hdPolice.glb"): scenes["hdPolice"]=load("res://models/vehicles/hdPolice.glb")
	_build_signals()
	for i in range(34): _spawn_road(CARS[i%CARS.size()],false)
	for i in range(22): _spawn_road(BIKES[i%BIKES.size()],true)
	for i in range(3): _spawn_road("t_camry",false,"police")
	_spawn_road("fire_truck",false,"fire")
	_traffic_posts()
	_flying_cars(22)
	_ships()
	apply_mode(world.night)
	print("TRAFFIC_READY ",counts)

func apply_mode(night: bool) -> void:
	for l in lights:
		if is_instance_valid(l): l.visible=night

# ---------------------------------------------------------------- road traffic
func _edge_length(a: String,b: String) -> float:
	var p: Vector3=Roads.NODES[a]
	var q: Vector3=Roads.NODES[b]
	return Vector2(p.x-q.x,p.z-q.z).length()

var _widths={}
func _width(a: String,b: String) -> float:
	# Cached: this is asked several times per vehicle per frame.
	var key=a+"|"+b
	if _widths.has(key): return _widths[key]
	var w=10.0
	for edge in Roads.EDGES:
		if (edge[0]==a and edge[1]==b) or (edge[0]==b and edge[1]==a):
			w=Roads.width(edge)
			break
	_widths[key]=w
	return w

func _spawn_road(model: String,bike: bool,role: String="civil") -> void:
	if role!="fire" and not scenes.has(model): return
	var keys=Roads.NODES.keys()
	var a: String=keys[rng.randi_range(0,keys.size()-1)]
	var b: String=adjacency[a][rng.randi_range(0,adjacency[a].size()-1)]
	var root=Node3D.new()
	root.name=("Bike_" if bike else "Car_")+model
	add_child(root)
	var body=Node3D.new()
	root.add_child(body)
	var inst: Node3D=fire_truck() if role=="fire" else make_model(model)
	body.add_child(inst)
	var beacons: Array=[]
	if role=="police":
		beacons=light_bar(body,Vector3(0,1.55,0),"2a6bff","ff2a2a")
		var tag=Label3D.new()
		tag.text="POLICE"
		tag.font_size=40
		tag.pixel_size=0.012
		tag.rotation.x=-PI/2
		tag.position=Vector3(0,1.47,0.6)
		tag.modulate=Color("dfe9ff")
		body.add_child(tag)
		counts.patrol+=1
	elif role=="fire":
		beacons=light_bar(body,Vector3(0,3.35,-2.4),"ff2a2a","ff2a2a")
		counts.fire+=1
	for mi in inst.find_children("*","MeshInstance3D",true,false):
		mi.visibility_range_end=260.0
		mi.visibility_range_end_margin=20.0
	var length=2.0 if bike else (8.5 if role=="fire" else 4.6)
	# Lights: two warm headlights and two red tail lights (visible at night).
	var head=world._mat("fff2c8",0.3,6.0)
	var tail=world._mat("ff2a2a",0.3,4.0)
	for s in ([0.0] if bike else [-0.6,0.6]):
		var h=_lamp(body,Vector3(s,0.75 if bike else 0.7,-length*0.5),head)
		var t=_lamp(body,Vector3(s,0.75 if bike else 0.8,length*0.5),tail)
		lights.append(h)
		lights.append(t)
	var beam=SpotLight3D.new()
	beam.position=Vector3(0,0.9,-length*0.5-0.2)
	beam.rotation_degrees=Vector3(-12,0,0)
	beam.spot_range=16.0
	beam.spot_angle=28.0
	beam.light_color=Color("ffe9c0")
	beam.light_energy=1.4
	beam.shadow_enabled=false
	beam.distance_fade_enabled=true
	beam.distance_fade_begin=100.0
	beam.distance_fade_length=20.0
	body.add_child(beam)
	lights.append(beam)
	if not bike:
		# Solid body so the player cannot walk through a car.
		var col=AnimatableBody3D.new()
		col.sync_to_physics=false
		var shape=CollisionShape3D.new()
		var box=BoxShape3D.new()
		box.size=Vector3(2.4 if role=="fire" else 1.8,3.0 if role=="fire" else 1.5,length)
		shape.shape=box
		shape.position=Vector3(0,box.size.y*0.5,0)
		col.add_child(shape)
		body.add_child(col)
	# Most drivers keep 80-100% of the limit; about 1 in 10 is reckless (speeds, may run reds).
	var reckless=role=="civil" and rng.randf()<0.1
	var pace=rng.randf_range(1.25,1.4) if reckless else rng.randf_range(0.8,1.0)
	road.append({"root":root,"body":body,"a":a,"b":b,"d":rng.randf_range(0,_edge_length(a,b)),"speed":0.0,"pace":pace,"bike":bike,"length":length,
		"lane_jitter":rng.randf_range(-0.4,0.4),"reckless":reckless,"run_red":false,"role":role,"model":model,"state":"drive","shift":0.0,"timer":0.0,
		"flagged_edge":"","beacons":beacons,"flash":0.0,"next":""})
	var v_new=road.back()
	v_new.next=_choose_next(v_new.a,v_new.b)
	# Spread spawns out so nobody starts inside another car.
	for tries in range(20):
		var clash=false
		for o in road:
			if o!=v_new and o.a==v_new.a and o.b==v_new.b and absf(o.d-v_new.d)<10.0: clash=true
		if not clash: break
		v_new.d=rng.randf_range(0,_edge_length(v_new.a,v_new.b))
	counts["bikes" if bike else "cars"]+=1

func make_model(model: String) -> Node3D:
	# Normalise any imported model: length along Z, real-world length, centred, wheels on y=0,
	# then turn nose-first (-Z) with the per-model YAW_FIX.
	var fix=Node3D.new()
	fix.rotation.y=float(YAW_FIX.get(model,0.0))
	var holder=Node3D.new()
	fix.add_child(holder)
	var inst=scenes[model].instantiate() as Node3D
	holder.add_child(inst)
	var b: AABB=world._scene_bounds(holder)
	if b.size.x>b.size.z:
		holder.rotation.y=PI/2
		b=world._scene_bounds(holder)
	var s=float(LENGTHS.get(model,4.5))/maxf(b.size.z,0.01)
	holder.scale=Vector3.ONE*s
	b=world._scene_bounds(holder)
	holder.position=Vector3(-b.get_center().x,-b.position.y,-b.get_center().z)
	return fix

func _lamp(parent: Node3D,at: Vector3,mat: Material) -> MeshInstance3D:
	var m=MeshInstance3D.new()
	var mesh=BoxMesh.new()
	mesh.size=Vector3(0.28,0.14,0.06)
	m.mesh=mesh
	m.material_override=mat
	m.position=at
	parent.add_child(m)
	return m

func _lane_point(v: Dictionary,a: String,b: String,d: float) -> Vector3:
	var p: Vector3=Roads.NODES[a]
	var q: Vector3=Roads.NODES[b]
	var length=maxf(_edge_length(a,b),0.01)
	var t=clampf(d/length,0,1)
	var mountain=Roads.is_mountain([a,b])
	var pos=Roads.point(p,q,t,mountain)
	var dir=Vector2(q.x-p.x,q.z-p.z).normalized()
	# Drive on the right: lane centre a quarter of the road width right of the centre line.
	var right=Vector2(-dir.y,dir.x)
	var off=_width(a,b)*0.25+(v.lane_jitter if v.bike else 0.0)+float(v.get("shift",0.0))
	return Vector3(pos.x+right.x*off,pos.y+0.14,pos.z+right.y*off)

func _physics_process(delta: float) -> void:
	if world.player==null: return
	var player_pos: Vector3=world.player.global_position
	sig_clock+=delta
	_update_signals(delta)
	by_edge.clear()
	for v in road:
		var k=v.a+"|"+v.b
		if not by_edge.has(k): by_edge[k]=[]
		by_edge[k].append(v)
	walkers.clear()
	if world.npcs:
		for group in [world.npcs.ambient,world.npcs.npcs]:
			for w in group:
				if w.node.visible and w.visual.visible: walkers.append(w.node.global_position)
	for v in road: _drive(v,delta,player_pos)
	for post in posts: _update_post(post,delta)
	_enforce_player(delta)
	for f in flyers: _fly(f,delta)
	for s in ships: _sail(s,delta)

func limit_for(a: String,b: String) -> float:
	if Roads.is_mountain([a,b]): return HILL_LIMIT
	return MAIN_LIMIT if _width(a,b)>=15.0 else LOCAL_LIMIT

func axis_of(a: String,b: String) -> String:
	var p: Vector3=Roads.NODES[a]
	var q: Vector3=Roads.NODES[b]
	return "ns" if absf(q.z-p.z)>absf(q.x-p.x) else "ew"

func junction_half(key: String) -> float:
	var half=4.0
	for o in adjacency.get(key,[]): half=maxf(half,_width(key,o)*0.5)
	return half

func signal_state(key: String,axis: String) -> String:
	var total=0.0
	for p in CYCLE: total+=p[2]
	var t=fposmod(sig_clock+float(signals[key].offset),total)
	for p in CYCLE:
		if t<p[2]: return p[1] if (p[0]==axis or p[0]=="all") else "red"
		t-=p[2]
	return "red"

func _drive(v: Dictionary,delta: float,player_pos: Vector3) -> void:
	var length=_edge_length(v.a,v.b)
	var here=_lane_point(v,v.a,v.b,v.d)
	var limit=limit_for(v.a,v.b)
	var target=limit*float(v.pace)
	var fwd3=(_lane_point(v,v.a,v.b,minf(v.d+1.0,length))-here)
	fwd3.y=0
	var fwd=Vector2(fwd3.x,fwd3.z).normalized()
	# Pulled over by traffic police: ease to the kerb, wait, then rejoin carefully.
	if v.state=="pulled":
		v.shift=move_toward(v.shift,_width(v.a,v.b)*0.25-1.0,delta*1.2)
		v.timer-=delta
		if v.timer<=0.0:
			v.state="drive"
			v.reckless=false
			v.run_red=false
			v.pace=rng.randf_range(0.8,0.95)
	else:
		v.shift=move_toward(v.shift,0.0,delta*0.8)
	# Keep a safe gap to the vehicle ahead in the same lane (pulled-over cars are passed).
	for o in by_edge.get(v.a+"|"+v.b,[])+by_edge.get(v.b+"|"+str(v.next),[]):
		if o==v or o.state=="pulled": continue
		var gap=-1.0
		if o.a==v.a and o.b==v.b: gap=o.d-v.d
		elif o.a==v.b and o.b==v.next: gap=(length-v.d)+o.d      # already on the street we turn into
		if gap>0 and gap<v.length+12.0: target=minf(target,maxf(0.0,(gap-v.length-2.5))*1.3)
	# Ease off approaching any junction, and never carry a faster limit into a slower street.
	if length-v.d<25.0:
		target=minf(target,limit_for(v.b,v.next)*float(v.pace) if v.next!="" else LOCAL_LIMIT)
		target=minf(target,maxf(LOCAL_LIMIT*0.75,limit_for(v.a,v.b)*0.75)*float(v.pace) if not v.reckless else target)
	# Stop for anyone on foot in the lane ahead: the player, townspeople and pedestrians.
	if _person_ahead(here,fwd,player_pos): target=0.0
	for wp in walkers:
		if _person_ahead(here,fwd,wp):
			target=0.0
			break
	# Traffic lights: stop at the line on red, and on amber unless too close to stop safely.
	var stop_at=length-(junction_half(v.b)+4.0)
	if signals.has(v.b) and v.state!="pulled":
		var light=signal_state(v.b,axis_of(v.a,v.b))
		var to_line=stop_at-v.d
		if to_line>-0.5 and light!="green":
			var can_stop=to_line>v.speed*v.speed/(2.0*5.0)+0.5
			var obey=not v.run_red and (light=="red" or can_stop)
			if obey and to_line<60.0:
				target=minf(target,maxf(0.0,to_line-0.3)*0.9)
				if to_line<0.6: target=0.0
				# Creeping up to the line: hold firmly behind it.
				if to_line<1.2 and v.speed<3.0:
					v.speed=0.0
					v.d=minf(v.d,stop_at-0.05)
					target=0.0
	elif length-v.d<10.0:
		target=minf(target,6.0)   # unsignalled bend or corner: slow down
	# Don't enter a junction box that is still occupied by a car turning in ahead of us.
	if v.next!="" and length-v.d<6.0:
		for o in by_edge.get(v.b+"|"+str(v.next),[]):
			if o!=v and o.a==v.b and o.b==v.next and o.d<o.length+3.0 and o.state!="pulled": target=minf(target,0.0 if o.speed<1.0 else target)
	if v.state=="pulled": target=0.0
	v.speed=move_toward(v.speed,target,(9.0 if target<v.speed else 3.2)*delta)
	var before=v.d
	v.d+=v.speed*delta
	# Enforcement: cameras at every signal, officers at the busiest junctions.
	if signals.has(v.b) and before<stop_at and v.d>=stop_at and signal_state(v.b,axis_of(v.a,v.b))=="red":
		_violation(v,"running a red light",v.b)
	if v.speed>limit*1.15 and v.flagged_edge!=v.a+v.b and v.state=="drive":
		for post in posts:
			if Vector2(post.at.x-here.x,post.at.z-here.z).length()<45.0:
				_violation(v,"speeding",post.key)
				break
	if v.d>=length:
		v.d-=length
		v.a=v.b
		v.b=v.next if v.next!="" else _choose_next(v.a,v.a)
		v.next=_choose_next(v.a,v.b)
		# Reckless drivers decide per junction whether to chance a red.
		v.run_red=v.reckless and rng.randf()<0.5
	var pos=_lane_point(v,v.a,v.b,v.d)
	var look=_lane_point(v,v.a,v.b,minf(v.d+2.0,_edge_length(v.a,v.b)))
	v.root.position=pos
	var dir=look-pos
	if Vector2(dir.x,dir.z).length()>0.05:
		var yaw=atan2(-dir.x,-dir.z)
		v.root.rotation.y=lerp_angle(v.root.rotation.y,yaw,clampf(delta*6.0,0,1))
		v.root.rotation.x=lerpf(v.root.rotation.x,atan2(dir.y,Vector2(dir.x,dir.z).length()),clampf(delta*6.0,0,1))
	_flash(v.beacons,v,delta)

func _choose_next(a: String,b: String) -> String:
	var options: Array=adjacency[b].duplicate()
	if options.size()>1: options.erase(a)
	return options[rng.randi_range(0,options.size()-1)]

func _person_ahead(here: Vector3,fwd: Vector2,p: Vector3) -> bool:
	var rel=Vector2(p.x-here.x,p.z-here.z)
	var ahead=rel.dot(fwd)
	return ahead>0.0 and ahead<9.0 and absf(rel.cross(fwd))<1.9 and absf(p.y-here.y)<3.0

func _violation(v: Dictionary,kind: String,where: String) -> void:
	v.flagged_edge=v.a+v.b
	violations["red light" if "red" in kind else "speeding"]+=1
	var post: Dictionary={}
	for p in posts:
		if p.key==where or Vector2(p.at.x-v.root.position.x,p.at.z-v.root.position.z).length()<70.0: post=p
	if signals.has(where): signals[where].flash=0.25    # camera flash
	var near=world.player.global_position.distance_to(v.root.position)<120.0
	if not post.is_empty() and not post.busy:
		# The officer rides out, pulls the driver over and writes a ticket.
		v.state="pulled"
		v.timer=16.0
		post.busy=true
		post.target=v
		post.timer=16.0
		if near and world.npcs: world.npcs.show_toast("Traffic police stopped a driver for %s." % kind)
	elif near and world.npcs:
		world.npcs.show_toast("Traffic camera recorded a driver %s." % kind)

# ---------------------------------------------------------------- flying cars
func _flying_cars(count: int) -> void:
	# Sky lanes: rounded loops at different heights over the main avenues and along the coast.
	var lanes=[
		{"points":[Vector3(302.82,0,235),Vector3(809.86,0,235),Vector3(809.86,0,560),Vector3(302.82,0,560)],"h":34.0},
		{"points":[Vector3(42.25,0,320),Vector3(577.46,0,320),Vector3(577.46,0,900),Vector3(302.82,0,900),Vector3(302.82,0,480),Vector3(42.25,0,480)],"h":44.0},
		{"points":[Vector3(28.17,0,150),Vector3(985.92,0,150),Vector3(985.92,0,60),Vector3(28.17,0,60)],"h":26.0},
		{"points":[Vector3(169.01,0,560),Vector3(492.96,0,560),Vector3(492.96,0,235),Vector3(169.01,0,235)],"h":54.0},
	]
	var paints=["ff3d9a","2fe6e0","f2c94c","b07dff","f2f0e8","ff7a3d"]
	for i in range(count):
		var lane=lanes[i%lanes.size()]
		var curve=Curve3D.new()
		curve.bake_interval=2.0
		var pts: Array=lane.points
		for k in range(pts.size()+1):
			var p: Vector3=pts[k%pts.size()]
			var ground=Layout.height_at(clampf(p.x,0,1199),clampf(p.z,0,999)) if p.z>Layout.shore(p.x) else Layout.SEA_Y
			curve.add_point(Vector3(p.x,maxf(ground,4.0)+lane.h+rng.randf_range(-3,3),p.z))
		var car=_hovercar(paints[i%paints.size()])
		var dir=1 if i%2==0 else -1
		flyers.append({"node":car,"curve":curve,"length":curve.get_baked_length(),"d":rng.randf_range(0,curve.get_baked_length()),"speed":rng.randf_range(16,26)*dir,"bob":rng.randf_range(0,6)})
		counts.flying+=1

func _hovercar(paint: String) -> Node3D:
	var root=Node3D.new()
	root.name="FlyingCar"
	add_child(root)
	var body=world._mat(paint,0.35)
	var glass=world._mat("1d2a3a",0.15)
	var glow=world._mat(paint,0.3,4.0)
	_part(root,Vector3(0,0,0),Vector3(1.9,0.55,4.4),body)
	_part(root,Vector3(0,0.42,0.2),Vector3(1.5,0.45,2.2),glass)
	_part(root,Vector3(0,-0.1,1.9),Vector3(2.3,0.12,0.7),body)            # rear wing
	for s in [-1,1]:
		_part(root,Vector3(s*1.25,-0.15,-1.2),Vector3(0.5,0.3,1.0),body)    # thruster pods
		_part(root,Vector3(s*1.25,-0.32,-1.2),Vector3(0.38,0.06,0.8),glow)
		_part(root,Vector3(s*1.25,-0.15,1.3),Vector3(0.5,0.3,1.0),body)
		_part(root,Vector3(s*1.25,-0.32,1.3),Vector3(0.38,0.06,0.8),glow)
	var tail=world._mat("ff2a2a",0.3,5.0)
	_part(root,Vector3(0,0.05,2.22),Vector3(1.6,0.1,0.05),tail)
	var head=world._mat("e8fbff",0.3,5.0)
	_part(root,Vector3(0,0.05,-2.22),Vector3(1.4,0.1,0.05),head)
	var under=OmniLight3D.new()
	under.light_color=Color(paint)
	under.omni_range=9.0
	under.light_energy=1.5
	under.position=Vector3(0,-1.0,0)
	under.shadow_enabled=false
	under.distance_fade_enabled=true
	under.distance_fade_begin=180.0
	under.distance_fade_length=20.0
	root.add_child(under)
	lights.append(under)
	return root

func _part(parent: Node3D,at: Vector3,size: Vector3,mat: Material) -> MeshInstance3D:
	var m=MeshInstance3D.new()
	var mesh=BoxMesh.new()
	mesh.size=size
	m.mesh=mesh
	m.material_override=mat
	m.position=at
	m.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(m)
	return m

func _fly(f: Dictionary,delta: float) -> void:
	f.d=fposmod(f.d+f.speed*delta,f.length)
	f.bob+=delta
	var pos=f.curve.sample_baked(f.d,true)
	var ahead=f.curve.sample_baked(fposmod(f.d+signf(f.speed)*6.0,f.length),true)
	pos.y+=sin(f.bob*1.3)*0.4
	f.node.position=pos
	var dir=ahead-pos
	if dir.length()>0.1:
		var yaw=atan2(-dir.x,-dir.z)
		var turn=wrapf(yaw-f.node.rotation.y,-PI,PI)
		f.node.rotation.y=lerp_angle(f.node.rotation.y,yaw,clampf(delta*3.0,0,1))
		f.node.rotation.z=lerpf(f.node.rotation.z,clampf(-turn*1.5,-0.5,0.5),clampf(delta*3.0,0,1))

# ---------------------------------------------------------------- ships
func _ships() -> void:
	# Ferry runs from the terminal pier out past the breakwater and back; fishing boats potter
	# along the coast; a cargo ship crosses far out; speedboats loop near the beach.
	var ferry_pier=Vector3(739.44,Layout.SEA_Y,Layout.shore(739.44)-118)
	_ship("FerryBoat",[ferry_pier+Vector3(-14,0,0),Vector3(718.31,Layout.SEA_Y,30),Vector3(563.38,Layout.SEA_Y,-200),Vector3(718.31,Layout.SEA_Y,30)],5.0,"f2f0e8",Vector3(6,3,22),true)
	for i in range(3):
		var x=176.06+i*154.93
		_ship("FishingBoat",[Vector3(x,Layout.SEA_Y,120),Vector3(x+90,Layout.SEA_Y,90),Vector3(x+40,Layout.SEA_Y,40),Vector3(x-40,Layout.SEA_Y,80)],2.5,["4fa3c7","e2574c","f2c94c"][i],Vector3(3,1.6,9),false)
	_ship("CargoShip",[Vector3(-140.85,Layout.SEA_Y,-300),Vector3(1056.34,Layout.SEA_Y,-330)],6.0,"c8473d",Vector3(14,6,70),false,true)
	for i in range(2):
		var cx=267.61+i*211.27
		var loop=[]
		for k in range(8):
			var a=TAU*k/8
			loop.append(Vector3(cx+cos(a)*55,Layout.SEA_Y,95+sin(a)*28))
		_ship("Speedboat",loop,11.0,["f2f0e8","ff3d9a"][i],Vector3(2.2,1.0,6),false)

func _ship(title: String,points: Array,speed: float,paint: String,size: Vector3,ferry: bool,one_way: bool=false) -> void:
	var root=Node3D.new()
	root.name=title
	add_child(root)
	var hull=world._mat(paint,0.6)
	_part(root,Vector3(0,size.y*0.25,0),Vector3(size.x,size.y*0.5,size.z),hull)
	var bow=_part(root,Vector3(0,size.y*0.25,-size.z*0.5-size.x*0.25),Vector3(size.x*0.55,size.y*0.5,size.x*0.6),hull)
	bow.rotation.y=PI/4
	_part(root,Vector3(0,size.y*0.75,size.z*0.15),Vector3(size.x*0.7,size.y*0.6,size.z*0.4),world.mats.coping)
	_part(root,Vector3(0,size.y*0.85,size.z*0.15-size.z*0.2),Vector3(size.x*0.66,size.y*0.18,0.06),world._mat("ffd6a0",0.3,2.0))
	if title=="CargoShip":
		var cmats=["3d7fd6","e2a33d","3fae6a","8a6fb5","c8473d"]
		for i in range(6):
			_part(root,Vector3(0,size.y*0.75,-size.z*0.35+i*size.z*0.09),Vector3(size.x*0.85,size.y*0.5,size.z*0.08),world._mat(cmats[i%5],0.6))
	var mast=world._mat("ff2a2a",0.3,5.0)
	var beacon=_part(root,Vector3(0,size.y*1.3,size.z*0.15),Vector3(0.3,0.3,0.3),mast)
	lights.append(beacon)
	# White wake behind the stern.
	var wake=world._mat("ffffff",0.9)
	wake.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	wake.albedo_color.a=0.55
	_part(root,Vector3(0,0.02,size.z*0.5+size.z*0.4),Vector3(size.x*0.8,0.02,size.z*0.8),wake)
	var curve=Curve3D.new()
	curve.bake_interval=2.0
	for p in points: curve.add_point(p+Vector3(0,0.1,0))
	if not one_way: curve.add_point(points[0]+Vector3(0,0.1,0))
	ships.append({"node":root,"curve":curve,"length":curve.get_baked_length(),"d":rng.randf_range(0,curve.get_baked_length()),"speed":speed,"one_way":one_way,"pause":0.0,"ferry":ferry})
	counts.ships+=1

func _sail(s: Dictionary,delta: float) -> void:
	if s.pause>0:
		s.pause-=delta
		return
	s.d+=s.speed*delta
	if s.d>=s.length:
		s.d=0.0 if s.one_way else fposmod(s.d,s.length)
		if s.ferry: s.pause=20.0   # dwell at the terminal
	var pos=s.curve.sample_baked(s.d,true)
	var ahead=s.curve.sample_baked(minf(s.d+4.0,s.length),true)
	pos.y+=sin(Time.get_ticks_msec()*0.0012+s.d*0.05)*0.12
	s.node.position=pos
	var dir=ahead-pos
	if Vector2(dir.x,dir.z).length()>0.1:
		s.node.rotation.y=lerp_angle(s.node.rotation.y,atan2(-dir.x,-dir.z),clampf(delta*1.5,0,1))


# ---------------------------------------------------------------- signals, cameras, police
func _lamp_mat(colour: String,on: bool) -> StandardMaterial3D:
	var key=colour+("1" if on else "0")
	if not lamp_mats.has(key):
		var c: String={"red":"ff2a20","yellow":"ffb31a","green":"2aff7a"}[colour]
		lamp_mats[key]=world._mat(c,0.3,6.0) if on else world._mat(Color(c).darkened(0.75).to_html(false),0.6)
	return lamp_mats[key]

func _build_signals() -> void:
	var dark=world._mat("2a2c33",0.6)
	for key in Roads.NODES:
		if key in Roads.MOUNTAIN_NODES: continue
		var nb: Array=adjacency.get(key,[])
		if nb.size()<3: continue
		var node: Vector3=Roads.NODES[key]
		var half=junction_half(key)
		var entry={"offset":rng.randf_range(0,35),"heads":[],"flash":0.0}
		for o in nb:
			if o in Roads.MOUNTAIN_NODES: continue
			var other: Vector3=Roads.NODES[o]
			var dir_in=Vector2(node.x-other.x,node.z-other.z).normalized()   # travel direction into the junction
			var right=Vector2(-dir_in.y,dir_in.x)
			var w=_width(o,key)
			var stop=Vector2(node.x,node.z)-dir_in*(half+4.0)
			var pole=stop+right*(w*0.5+0.9)
			var y=Layout.height_at(pole.x,pole.y)
			var root=Node3D.new()
			root.name="TrafficSignal"
			root.position=Vector3(pole.x,y,pole.y)
			# Local -X points over the lane, local +Z faces oncoming traffic.
			root.rotation.y=atan2(-dir_in.x,-dir_in.y)
			add_child(root)
			_part(root,Vector3(0,2.6,0),Vector3(0.18,5.2,0.18),dark)
			_solid_post(root,Vector3(0,2.6,0),Vector3(0.3,5.2,0.3))
			var arm=w*0.25+0.9
			# Local +X points to the kerb side, so the mast arm reaches over the lane along -X.
			_part(root,Vector3(-arm*0.5,5.1,0),Vector3(arm,0.14,0.14),dark)
			var head_at=Vector3(-arm,4.5,0)
			_part(root,head_at,Vector3(0.45,1.35,0.4),dark)
			var lamps={}
			var rep={}
			var i=0
			for colour in ["red","yellow","green"]:
				lamps[colour]=_part(root,head_at+Vector3(0,0.42-i*0.42,0.22),Vector3(0.3,0.3,0.06),_lamp_mat(colour,false))
				rep[colour]=_part(root,Vector3(0,2.9-i*0.26,0.12),Vector3(0.18,0.18,0.05),_lamp_mat(colour,false))
				i+=1
			# Stop line across this approach lane.
			var line_at=stop+right*(w*0.25)
			var line=_part(self,Vector3(line_at.x,Layout.height_at(line_at.x,line_at.y)+0.15,line_at.y),Vector3(w*0.5-0.4,0.02,0.4),world.mats.paint)
			line.rotation.y=atan2(dir_in.x,dir_in.y)
			entry.heads.append({"axis":axis_of(o,key),"lamps":lamps,"rep":rep,"state":"","root":root})
		# Red-light camera on one corner.
		var cam_at=Vector2(node.x,node.z)+Vector2(half+3.0,half+3.0)
		var cam=Node3D.new()
		cam.name="RedLightCamera"
		cam.position=Vector3(cam_at.x,Layout.height_at(cam_at.x,cam_at.y),cam_at.y)
		add_child(cam)
		_part(cam,Vector3(0,2.2,0),Vector3(0.14,4.4,0.14),dark)
		_solid_post(cam,Vector3(0,2.2,0),Vector3(0.3,4.4,0.3))
		_part(cam,Vector3(0,4.5,-0.2),Vector3(0.35,0.3,0.6),world._mat("e8e4dc",0.5))
		var flash=OmniLight3D.new()
		flash.light_color=Color("ffffff")
		flash.omni_range=14.0
		flash.light_energy=0.0
		flash.position=Vector3(0,4.4,-0.6)
		cam.add_child(flash)
		entry["flash_light"]=flash
		signals[key]=entry
		counts.signals+=1
		counts.cameras+=1

func _update_signals(delta: float) -> void:
	for key in signals:
		var entry=signals[key]
		for head in entry.heads:
			var st=signal_state(key,head.axis)
			if st==head.state: continue
			head.state=st
			for colour in ["red","yellow","green"]:
				head.lamps[colour].material_override=_lamp_mat(colour,colour==st)
				head.rep[colour].material_override=_lamp_mat(colour,colour==st)
		if entry.flash>0.0:
			entry.flash-=delta
			entry.flash_light.light_energy=8.0 if entry.flash>0.0 else 0.0

func _traffic_posts() -> void:
	# Officers with police motorbikes at the six busiest signalled junctions.
	var ranked: Array=[]
	for key in signals:
		ranked.append([adjacency[key].size()*10.0+junction_half(key),key])
	ranked.sort_custom(func(m,n): return m[0]>n[0])
	var Visual=preload("res://scripts/student_visual.gd")
	for i in range(mini(6,ranked.size())):
		var key: String=ranked[i][1]
		var node: Vector3=Roads.NODES[key]
		var half=junction_half(key)
		var corner=Vector2(node.x,node.z)+Vector2(-(half+3.2),half+3.2)
		var y=Layout.height_at(corner.x,corner.y)+0.12
		var officer=Node3D.new()
		officer.name="TrafficOfficer"
		officer.position=Vector3(corner.x,y,corner.y)
		add_child(officer)
		var body=Visual.new()
		body.palette={"jacket":"e9ff3a","sleeve":"2a3a6a","piping":"f2f0e8","trousers":"1e2640","hair":"1a1a1a","backpack":false}
		officer.add_child(body)
		body.rotation.y=PI*0.75
		var bike=Node3D.new()
		bike.name="PoliceBike"
		var home=Vector3(corner.x+1.6,y-0.12,corner.y+1.0)
		bike.position=home
		add_child(bike)
		if scenes.has("hdPolice"): bike.add_child(make_model("hdPolice"))
		var beacons=light_bar(bike,Vector3(0,1.45,0.6),"2a6bff","ff2a2a",0.5)
		for bl in beacons: bl.visible=false
		posts.append({"key":key,"at":Vector3(node.x,y,node.z),"officer":officer,"bike":bike,"home":home,"busy":false,"target":null,"timer":0.0,"beacons":beacons,"flash":0.0})
		counts.police_posts+=1

func _update_post(post: Dictionary,delta: float) -> void:
	var goal: Vector3=post.home
	var flashing=false
	if post.busy and post.target!=null:
		var v: Dictionary=post.target
		post.timer-=delta
		# Park the bike 6 m behind the stopped car, kerb side.
		goal=_lane_point(v,v.a,v.b,maxf(0.0,v.d-6.0))
		flashing=true
		if post.timer<=0.0 or v.state!="pulled":
			post.busy=false
			post.target=null
	var to: Vector3=goal-post.bike.position
	if to.length()>0.05:
		post.bike.position+=to.normalized()*minf(to.length(),14.0*delta)
		post.bike.rotation.y=lerp_angle(post.bike.rotation.y,atan2(-to.x,-to.z),clampf(delta*5.0,0,1))
	# The officer rides the bike while it is away from the post.
	post.officer.visible=post.bike.position.distance_to(post.home)<1.0
	post.flash+=delta
	for i in range(post.beacons.size()):
		post.beacons[i].visible=flashing and int(post.flash*6.0+i)%2==0

func _flash(beacons: Array,v: Dictionary,delta: float) -> void:
	if beacons.is_empty(): return
	v.flash+=delta
	for i in range(beacons.size()):
		beacons[i].visible=int(v.flash*5.0+i)%2==0

func light_bar(parent: Node3D,at: Vector3,a: String,b: String,width: float=1.2) -> Array:
	_part(parent,at,Vector3(width,0.14,0.32),world._mat("2a2c33",0.6))
	var l=_part(parent,at+Vector3(-width*0.28,0.1,0),Vector3(width*0.42,0.14,0.3),world._mat(a,0.3,6.0))
	var r=_part(parent,at+Vector3(width*0.28,0.1,0),Vector3(width*0.42,0.14,0.3),world._mat(b,0.3,6.0))
	return [l,r]

func fire_truck() -> Node3D:
	var root=Node3D.new()
	var red=world._mat("d8261c",0.45)
	var white=world._mat("f2f0e8",0.5)
	var chrome=world._mat("b9c0c4",0.25)
	var dark=world._mat("1e1f24",0.7)
	_part(root,Vector3(0,1.55,-2.9),Vector3(2.45,2.3,2.6),red)
	_part(root,Vector3(0,2.0,-4.21),Vector3(2.2,1.0,0.06),world._mat("1d2a3a",0.15))
	_part(root,Vector3(0,1.6,1.0),Vector3(2.5,2.4,5.4),red)
	_part(root,Vector3(0,1.2,1.0),Vector3(2.52,0.18,5.4),white)
	for i in range(4): _part(root,Vector3(0,1.75,-1.2+i*1.35),Vector3(2.53,1.5,0.06),chrome)
	_part(root,Vector3(0,3.05,0.9),Vector3(0.9,0.25,6.5),chrome)
	for i in range(9): _part(root,Vector3(0,3.2,-2.0+i*0.75),Vector3(1.0,0.06,0.08),chrome)
	_part(root,Vector3(0,0.55,-4.25),Vector3(2.3,0.35,0.2),chrome)
	for z in [-2.9,1.0,2.9]:
		for x in [-1.15,1.15]:
			_part(root,Vector3(x,0.5,z),Vector3(0.36,1.0,1.0),dark)
	var label=Label3D.new()
	label.text="FIRE & RESCUE"
	label.font_size=40
	label.pixel_size=0.012
	label.rotation.y=PI/2
	label.position=Vector3(1.27,1.85,1.0)
	label.modulate=Color("ffffff")
	root.add_child(label)
	return root


# ---------------------------------------------------------------- the player's driving
var player_inside: Dictionary={}
var fine_cooldown=0.0

func _enforce_player(delta: float) -> void:
	fine_cooldown=maxf(0.0,fine_cooldown-delta)
	var g=world.garage
	if g==null or g.current==null or g.current.kind in ["mecha","hover","bicycle"]: return
	var v=g.current
	var p=v.global_position
	var vel=Vector2(v.velocity.x,v.velocity.z)
	for key in signals:
		var node: Vector3=Roads.NODES[key]
		var half=junction_half(key)
		var inside=absf(p.x-node.x)<half and absf(p.z-node.z)<half
		var was=player_inside.get(key,false)
		player_inside[key]=inside
		if inside and not was and vel.length()>2.0:
			var axis="ns" if absf(vel.y)>absf(vel.x) else "ew"
			if signal_state(key,axis)=="red": _fine("ran a red light",5000)
	var road=Roads.sample(p.x,p.z)
	if not road.is_empty() and fine_cooldown<=0.0:
		var limit=MAIN_LIMIT if float(road.half)>=7.5 else LOCAL_LIMIT
		if vel.length()>limit*1.15:
			for post in posts:
				if Vector2(post.at.x-p.x,post.at.z-p.z).length()<45.0:
					_fine("speeding (%d km/h in a %d zone)" % [int(vel.length()*3.6),int(round(limit*3.6))],3000)
					break

func _fine(what: String,amount: int) -> void:
	if fine_cooldown>0.0: return
	fine_cooldown=12.0
	violations["red light" if "red" in what else "speeding"]+=1
	if world.npcs:
		world.npcs.kyat-=amount
		world.npcs.dirty=true
		world.npcs.show_toast("Traffic police fined you %s K: you %s." % [world.npcs._commas(amount),what])


func _solid_post(parent: Node3D,at: Vector3,size: Vector3) -> void:
	var body=StaticBody3D.new()
	var shape=CollisionShape3D.new()
	var box=BoxShape3D.new()
	box.size=size
	shape.shape=box
	shape.position=at
	body.add_child(shape)
	parent.add_child(body)
