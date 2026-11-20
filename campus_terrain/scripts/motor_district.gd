extends Node
## Motor District (200 x 200 m, east of the harbour and campus): car showroom, bike & scooter showroom,
## service garage with chargers, a test track and a delivery lot. Also the player's garage:
## buy a vehicle (Q at a showroom), then C to get in / out, G to call your last vehicle to you.
const Layout=preload("res://scripts/terrain_layout.gd")
const OwnedVehicle=preload("res://scripts/owned_vehicle.gd")
const LOT=Vector2(915.49,722)
const CATALOG=[
	{"id":"bicycle","name":"City bicycle","kind":"bicycle","price":8000,"shop":"BIKE"},
	{"id":"superCub","name":"Honda Super Cub","kind":"bike","price":25000,"shop":"BIKE"},
	{"id":"cubC70","name":"Super Cub C70 custom","kind":"bike","price":30000,"shop":"BIKE"},
	{"id":"yz250","name":"Yamaha YZ250 dirt bike","kind":"bike","price":45000,"shop":"BIKE"},
	{"id":"superDuke","name":"KTM Super Duke","kind":"bike","price":70000,"shop":"BIKE"},
	{"id":"t_wagonr","name":"Suzuki Wagon R","kind":"car","price":90000,"shop":"CAR"},
	{"id":"t_fit","name":"Honda Fit","kind":"car","price":120000,"shop":"CAR"},
	{"id":"t_markii","name":"Toyota Mark II","kind":"car","price":160000,"shop":"CAR"},
	{"id":"t_tucson","name":"Hyundai Tucson","kind":"car","price":200000,"shop":"CAR"},
	{"id":"t_hilux","name":"Toyota Hilux","kind":"car","price":240000,"shop":"CAR"},
	{"id":"hover","name":"Neon hover car","kind":"hover","price":400000,"shop":"CAR"},
]
var world
var root: Node3D
var owned: Dictionary={}       # id -> OwnedVehicle node
var current=null               # vehicle being driven
var last_used: String=""
var mecha=null
var frames: Dictionary={}     # hangar bay index -> piloted frame
var saved_zoom=1.0
var turntables: Array=[]
var counts={"buildings":0,"displays":0}

func _ready() -> void:
	name="MotorDistrict"
	root=Node3D.new()
	root.name="MotorDistrictSite"
	world.add_child(root)
	world.grass_exclusions.append(Layout.MOTOR.grow(-8.0))
	_build()
	print("MOTOR_DISTRICT_READY ",counts)

func info(id: String) -> Dictionary:
	for c in CATALOG:
		if c.id==id: return c
	return {}

# ---------------------------------------------------------------- site
func h(x: float,z: float) -> float:
	return Layout.height_at(x,z)

func box(at: Vector3,size: Vector3,mat: Material,solid=false) -> MeshInstance3D:
	return world._box(at,size,mat,"Motor",solid)

func _pavilion(x0: float,z0: float,w: float,d: float,title: String,neon: String) -> Vector3:
	# Open glass showroom: columns, roof with neon fascia, glass back wall, polished floor.
	var c=Vector3(x0+w*0.5,h(x0+w*0.5,z0+d*0.5),z0+d*0.5)
	world._surface(Rect2(x0,z0,w,d),world._mat("d9dde0",0.2),"ShowroomFloor",false,func(px: float,pz: float)->float: return h(px,pz)+0.12,2.0)
	for cx in [-0.5,0.5]:
		for cz in [-0.5,0.5]: box(c+Vector3(cx*(w-1),3.5,cz*(d-1)),Vector3(0.6,7,0.6),world._mat("2a2c33",0.5),true)
	box(c+Vector3(0,7.2,0),Vector3(w+1.5,0.6,d+1.5),world._mat("1f2230",0.5))
	box(c+Vector3(0,6.8,d*0.5+0.76),Vector3(w,0.25,0.12),world._mat(neon,0.3,4.0))
	var glass=world._mat("2a5f78",0.15)
	box(c+Vector3(0,3.5,-d*0.5),Vector3(w,7,0.15),glass,true)
	var l=Label3D.new()
	l.text=title
	l.font_size=96
	l.pixel_size=0.022
	l.position=c+Vector3(0,8.4,d*0.5+0.8)
	l.modulate=Color(neon).lightened(0.4)
	l.outline_size=10
	l.outline_modulate=Color("101018")
	l.shaded=false
	l.billboard=BaseMaterial3D.BILLBOARD_FIXED_Y
	root.add_child(l)
	counts.buildings+=1
	return c

func _display(model: Node3D,at: Vector3) -> void:
	var plate=box(at+Vector3(0,0.1,0),Vector3(5.4,0.2,5.4),world._mat("eceae2",0.3))
	var spin=Node3D.new()
	spin.set_script(load("res://scripts/spin.gd"))
	spin.speed=0.35
	spin.position=at+Vector3(0,0.2,0)
	root.add_child(spin)
	spin.add_child(model)
	var light=SpotLight3D.new()
	light.position=at+Vector3(0,6.5,0)
	light.rotation_degrees=Vector3(-90,0,0)
	light.spot_range=9
	light.spot_angle=30
	light.light_energy=2.0
	light.shadow_enabled=false
	root.add_child(light)
	counts.displays+=1

func model_for(id: String) -> Node3D:
	if id=="bicycle": return bicycle()
	if id=="hover" and world.traffic:
		var hc: Node3D=world.traffic._hovercar("2fe6e0")
		hc.get_parent().remove_child(hc)    # _hovercar parents itself to the traffic node
		hc.position=Vector3(0,1.0,0)
		var holder=Node3D.new()
		holder.add_child(hc)
		return holder
	if world.traffic and world.traffic.scenes.has(id): return world.traffic.make_model(id)
	var n=Node3D.new()
	var m=MeshInstance3D.new()
	var mesh=BoxMesh.new()
	mesh.size=Vector3(1.8,1.4,4.2)
	m.mesh=mesh
	m.position.y=0.7
	m.material_override=world._mat("c8473d")
	n.add_child(m)
	return n

func bicycle() -> Node3D:
	var n=Node3D.new()
	var frame=world._mat("2fe6e0",0.4)
	var dark=world._mat("1e1f24",0.6)
	for z in [-0.55,0.55]:
		var wheel=MeshInstance3D.new()
		var t=TorusMesh.new()
		t.inner_radius=0.28
		t.outer_radius=0.34
		wheel.mesh=t
		wheel.material_override=dark
		wheel.rotation.z=PI/2
		wheel.position=Vector3(0,0.34,z)
		n.add_child(wheel)
	for p in [[Vector3(0,0.6,0),Vector3(0.06,0.06,1.0)],[Vector3(0,0.82,-0.35),Vector3(0.06,0.5,0.06)],[Vector3(0,0.9,0.4),Vector3(0.06,0.5,0.06)],
			[Vector3(0,1.15,0.4),Vector3(0.22,0.06,0.3)],[Vector3(0,1.1,-0.45),Vector3(0.5,0.05,0.05)]]:
		var m=MeshInstance3D.new()
		var b=BoxMesh.new()
		b.size=p[1]
		m.mesh=b
		m.material_override=frame if p[1].y<0.4 or p[1].x>0.3 else dark
		m.position=p[0]
		n.add_child(m)
	return n

func _build() -> void:
	var r=Layout.MOTOR
	# District paving between the ring road sidewalks.
	world._surface(Rect2(r.position.x+16,r.position.y+16,r.size.x-32,r.size.y-32),world.mats.paving,"MotorPlaza",false,func(px: float,pz: float)->float: return h(px,pz)+0.07,2.0)
	var car_c=_pavilion(870,646,60,40,"CAR SHOWROOM","ff3d9a")
	var bike_c=_pavilion(934,646,42,40,"BIKE & SCOOTER SHOWROOM","2fe6e0")
	var gar_c=_pavilion(870,752,40,40,"MOTOR SERVICE GARAGE","ffb84a")
	var i=0
	for c in CATALOG:
		if c.shop=="CAR":
			_display(model_for(c.id),car_c+Vector3(-25+i*10,0,-6))
			i+=1
	i=0
	for c in CATALOG:
		if c.shop=="BIKE":
			_display(model_for(c.id),bike_c+Vector3(-16+i*8,0,-6))
			i+=1
	for k in range(4):
		box(gar_c+Vector3(-14+k*9,0.9,-14),Vector3(0.5,1.8,0.4),world._mat("e8e4dc",0.5),true)
		box(gar_c+Vector3(-14+k*9,1.35,-13.79),Vector3(0.36,0.5,0.04),world._mat("7dff9a",0.3,3.5))
	box(gar_c+Vector3(12,0.3,4),Vector3(4,0.6,6),world._mat("f0b429",0.6),true)    # vehicle lift
	# Test track: an oval of asphalt with red-and-white kerbs and a start line.
	var tc=Vector2(944,756)
	for k in range(48):
		var a=TAU*k/48
		var p=tc+Vector2(cos(a)*28,sin(a)*22)
		var y=h(p.x,p.y)+0.09
		var seg=box(Vector3(p.x,y,p.y),Vector3(6.5,0.06,5.2),world.mats.road)
		seg.rotation.y=-atan2(sin(a)*22.0,cos(a)*28.0)-PI/2
		var kerb_at=tc+Vector2(cos(a)*31,sin(a)*25)
		box(Vector3(kerb_at.x,h(kerb_at.x,kerb_at.y)+0.12,kerb_at.y),Vector3(1.4,0.2,0.6),world._mat("e2574c" if k%2==0 else "f2f0e8",0.6))
	box(Vector3(tc.x,h(tc.x,tc.y+22)+0.13,tc.y+22),Vector3(0.6,0.03,6.0),world.mats.paint)
	# Delivery lot where bought vehicles wait.
	box(Vector3(LOT.x,h(LOT.x,LOT.y)+0.08,LOT.y),Vector3(26,0.04,10),world._mat("3b4a5a",0.8))
	var l=Label3D.new()
	l.text="DELIVERY LOT"
	l.font_size=64
	l.pixel_size=0.02
	l.rotation.x=-PI/2
	l.position=Vector3(LOT.x,h(LOT.x,LOT.y)+0.12,LOT.y)
	l.modulate=Color("f2f0e8")
	root.add_child(l)
	world.activity_spots.append({"pos":car_c+Vector3(0,0,10),"title":"CAR SHOWROOM"})
	world.activity_spots.append({"pos":bike_c+Vector3(0,0,10),"title":"BIKE & SCOOTER SHOWROOM"})
	world.activity_spots.append({"pos":gar_c+Vector3(0,0,8),"title":"MOTOR SERVICE GARAGE"})
	world.activity_spots.append({"pos":Vector3(tc.x,h(tc.x,tc.y+26),tc.y+26),"title":"TEST TRACK"})

# ---------------------------------------------------------------- ownership and driving
func buy(id: String) -> bool:
	if owned.has(id): return false
	spawn_owned(id,Vector3(LOT.x-10+owned.size()*4.0,0,LOT.y),0.0)
	last_used=id
	return true

func spawn_owned(id: String,at: Vector3,yaw: float) -> void:
	var c=info(id)
	var v=OwnedVehicle.new()
	v.name="Owned_"+id
	world.add_child(v)
	v.setup(world,c.kind,id,c.name,model_for(id))
	v.global_position=Vector3(at.x,h(at.x,at.z)+0.3,at.z)
	v.heading=yaw
	owned[id]=v

func summon() -> bool:
	if last_used=="" or not owned.has(last_used) or current!=null: return false
	var v=owned[last_used]
	var p=world.player.global_position
	var fwd=Vector3(-sin(world.player.visual.rotation.y),0,-cos(world.player.visual.rotation.y))
	var at=p+fwd*3.5+Vector3(fwd.z,0,-fwd.x)*2.0
	v.global_position=Vector3(at.x,h(at.x,at.z)+0.4,at.z)
	v.speed=0.0
	v.heading=world.player.visual.rotation.y
	return true

func pilot_mecha(at: Vector3,bounds: Rect2) -> void:
	if mecha==null:
		var v=OwnedVehicle.new()
		v.name="TrainingFramePiloted"
		world.add_child(v)
		v.setup(world,"mecha","mecha","YUST training frame",world.hill.mecha_model())
		v.bounds=bounds
		mecha=v
		if world.hill.parked_mecha: world.hill.parked_mecha.visible=false
	mecha.global_position=at
	_enter(mecha)

func pilot_bay(i: int) -> void:
	var bay: Dictionary={}
	for b in world.hangar_bays:
		if int(b.index)==i: bay=b
	if bay.is_empty(): return
	if not frames.has(i):
		var holder=Node3D.new()
		var m=(load(bay.path) as PackedScene).instantiate() as Node3D
		m.rotation.y=PI     # models face +Z; vehicles drive toward -Z
		holder.add_child(m)
		load("res://scripts/mecha_rig.gd").attach(m,world,false)
		var v=OwnedVehicle.new()
		v.name="PilotedFrame_%d"%(i+1)
		world.add_child(v)
		v.setup(world,"mecha","frame_%d"%i,bay.name,holder)
		v.global_position=bay.home+Vector3(0,0.3,0)
		v.heading=PI       # walk out of the open hangar front (+Z)
		v.max_speed=5.5
		frames[i]=v
		bay.node.visible=false
		bay.body.collision_layer=0
	_enter(frames[i])

func recall_frames() -> void:
	if current!=null and str(current.id).begins_with("frame_"): _exit()
	for i in frames.keys():
		frames[i].queue_free()
		for b in world.hangar_bays:
			if int(b.index)==i:
				b.node.visible=true
				b.body.collision_layer=1
	frames.clear()

func nearby_hangar_bay() -> Dictionary:
	var position: Vector3=world.player.global_position
	for b in world.hangar_bays:
		if frames.has(int(b.index)) or absf(position.y-b.home.y)>2.0: continue
		if b.approach.has_point(Vector2(position.x,position.z)): return b
	return {}

func _nearest_owned():
	var best=null
	var d=4.0 if true else 0.0
	for v in owned.values()+([mecha] if mecha else [])+frames.values():
		var dist=v.global_position.distance_to(world.player.global_position)
		if dist<(7.0 if v.kind=="mecha" else d): best=v; d=dist
	return best

func _enter(v) -> void:
	current=v
	v.driving=true
	world.player.transit_mode=true
	world.player.visible=false
	world.camera.target=v
	world.camera.instant=true
	if not (v.id=="mecha" or str(v.id).begins_with("frame_")): last_used=v.id
	if v.kind=="mecha":
		saved_zoom=world.camera.zoom
		world.camera.zoom=maxf(world.camera.zoom,1.5)
	if world.npcs:
		var extra=", Space/X climb/descend" if v.kind=="hover" else (", Space boost dash" if v.kind=="mecha" else "")
		world.npcs.show_toast("%s %s  ·  W/S move, A/D turn%s, C to get out" % ["Piloting" if v.kind=="mecha" else "Driving",v.title,extra])

func _exit() -> void:
	var v=current
	current=null
	v.driving=false
	v.speed=0.0
	var side=Vector3(cos(v.heading),0,-sin(v.heading))*(2.2 if v.kind!="mecha" else 4.0)
	var out=v.global_position+side
	out.y=maxf(h(out.x,out.z),v.global_position.y-0.5)+0.3
	if v.kind=="hover": v.hover_height=0.0
	world.player.visible=true
	world.player.transit_mode=false
	world.player.teleport(out)
	world.camera.target=world.player
	world.camera.instant=true
	if v.kind=="mecha": world.camera.zoom=saved_zoom
	if v.id=="mecha":
		v.global_position=world.hill.mecha_home
		if world.hill.parked_mecha: world.hill.parked_mecha.visible=true
		v.queue_free()
		mecha=null

func _process(_delta: float) -> void:
	for t in turntables: pass
	if world.npcs and current==null and not world.player.transit_mode:
		var v=_nearest_owned()
		if v and world.npcs.prompt.text=="": world.npcs.prompt.text="[C] Get in %s" % v.title

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if world.interiors and world.interiors.inside: return
	if event.physical_keycode==KEY_C:
		if current!=null: _exit()
		elif not world.player.transit_mode:
			var bay=nearby_hangar_bay()
			if not bay.is_empty(): pilot_bay(bay.index)
			else:
				var v=_nearest_owned()
				if v: _enter(v)
		get_viewport().set_input_as_handled()
	elif event.physical_keycode==KEY_G and current==null and not world.player.transit_mode:
		if summon() and world.npcs: world.npcs.show_toast("Your %s is here." % info(last_used).name)
		get_viewport().set_input_as_handled()

func save_state() -> Dictionary:
	var out={}
	for id in owned:
		var v=owned[id]
		out[id]=[v.global_position.x,v.global_position.z,v.heading]
	return {"owned":out,"last":last_used}

func load_state(data: Dictionary) -> void:
	for id in data.get("owned",{}):
		var p=data.owned[id]
		if info(id).is_empty() or owned.has(id): continue
		spawn_owned(id,Vector3(float(p[0]),0,float(p[1])),float(p[2]))
	last_used=str(data.get("last",""))
