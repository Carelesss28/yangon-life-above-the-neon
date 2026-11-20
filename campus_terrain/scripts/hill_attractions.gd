extends RefCounted
## Hill attractions, each on its own flat platform (terrain_layout.HILL_PADS), well apart:
## 0 YUST field-training grounds  1 sky-terrace resort + hot spring  2 meditation garden & lantern park
## 3 hill village & tea plantation  4 campground (+ zipline over the reservoir, stargazing deck)
## 5 civic-defence sensor station. A cable car links the village up to the resort.
## Activity spots (press Q) are registered in world.activity_spots; activities.gd holds their actions.
const Layout=preload("res://scripts/terrain_layout.gd")
const CABLE_LOWER=Vector2(80.99,655)
const CABLE_UPPER=Vector2(105.63,915)
const CABLE_HANG=3.6
var world
var root: Node3D
var movers: Array=[]
var counts={"sites":0,"spots":0}
var white: StandardMaterial3D
var dark: StandardMaterial3D
var concrete: StandardMaterial3D
var parked_mecha: Node3D
var mecha_home: Vector3
var training_bounds: Rect2
var cable_curve=Curve3D.new()

func setup(owner_world) -> void:
	world=owner_world
	root=Node3D.new()
	root.name="HillAttractions"
	world.add_child(root)
	white=world._mat("f2f0e8",0.5)
	dark=world._mat("2a2c33",0.6)
	concrete=world.mats.concrete
	for i in range(Layout.HILL_PADS.size()):
		var pad: Vector3=Layout.HILL_PADS[i]
		world.grass_exclusions.append(Rect2(pad.x-pad.z,pad.y-pad.z,pad.z*2,pad.z*2))
	_training(0)
	_resort(1)
	_garden(2)
	_village(3)
	_camp(4)
	_defence(5)
	_cable_car()
	_zipline()
	var mover=Node.new()
	mover.name="HillMovers"
	mover.set_script(load("res://scripts/hill_movers.gd"))
	mover.set("items",movers)
	root.add_child(mover)
	print("HILL_ATTRACTIONS_READY ",counts)

# ---------------------------------------------------------------- helpers
func centre(i: int) -> Vector3:
	var p: Vector3=Layout.HILL_PADS[i]
	return Vector3(p.x,Layout.pad_height(i),p.y)

func box(at: Vector3,size: Vector3,mat: Material,solid=false,title="Hill") -> MeshInstance3D:
	return world._box(at,size,mat,title,solid)

func cyl(at: Vector3,r: float,h: float,mat: Material) -> MeshInstance3D:
	return world._cylinder(at,r,h,mat,"HillCylinder")

func label(at: Vector3,text: String,colour: String,size=0.02,yaw=0.0) -> void:
	var l=Label3D.new()
	l.text=text
	l.font_size=72
	l.pixel_size=size
	l.position=at
	l.rotation.y=yaw
	l.billboard=BaseMaterial3D.BILLBOARD_FIXED_Y
	l.modulate=Color(colour)
	l.outline_size=8
	l.outline_modulate=Color("15121c")
	l.shaded=false
	root.add_child(l)

func paved(i: int,radius: float,mat: Material) -> void:
	var c=centre(i)
	world._surface(Rect2(c.x-radius,c.z-radius,radius*2,radius*2),mat,"HillPlaza",false,func(x: float,z: float)->float: return Layout.height_at(x,z)+0.06,2.0)

func lamp(at: Vector3,colour="ffd09a") -> void:
	box(at+Vector3(0,1.6,0),Vector3(0.12,3.2,0.12),dark,true)
	box(at+Vector3(0,3.25,0),Vector3(0.4,0.25,0.4),world._mat(colour,0.3,3.0))
	var l=OmniLight3D.new()
	l.position=at+Vector3(0,3.0,0)
	l.light_color=Color(colour)
	l.omni_range=10
	l.light_energy=0.0
	l.set_meta("night_energy",1.6)
	l.shadow_enabled=false
	root.add_child(l)
	world.lamps.append(l)

func spot(at: Vector3,title: String) -> void:
	world.activity_spots.append({"pos":at,"title":title})
	box(at+Vector3(0,0.6,0),Vector3(0.7,1.2,0.25),dark,true)
	box(at+Vector3(0,1.0,0.14),Vector3(0.55,0.5,0.04),world._mat("2fe6e0",0.3,2.5))
	counts.spots+=1

func water(at: Vector3,size: Vector2,title: String) -> void:
	var plane=PlaneMesh.new()
	plane.size=size
	world._mesh_node(plane,world.mats.water,title).position=at

func steam(at: Vector3) -> void:
	var p=CPUParticles3D.new()
	p.position=at
	p.amount=14
	p.lifetime=3.0
	p.direction=Vector3(0,1,0)
	p.spread=20
	p.initial_velocity_min=0.3
	p.initial_velocity_max=0.7
	p.gravity=Vector3(0,0.15,0)
	p.scale_amount_min=1.0
	p.scale_amount_max=2.0
	var q=QuadMesh.new()
	q.size=Vector2(1.2,1.2)
	p.mesh=q
	var m=StandardMaterial3D.new()
	m.albedo_color=Color(0.95,0.97,1.0,0.14)
	m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode=BaseMaterial3D.BILLBOARD_PARTICLES
	p.material_override=m
	root.add_child(p)

# ---------------------------------------------------------------- 1 mecha training grounds
func _training(i: int) -> void:
	var c=centre(i)
	paved(i,36,world._mat("b8a07a",0.95))
	var orange=world._mat("ff7a1a",0.5)
	# Running track ring and obstacle walls.
	for k in range(24):
		var a=TAU*k/24
		var p=c+Vector3(cos(a)*30,0.08,sin(a)*30)
		var seg=box(p,Vector3(8.2,0.04,3.0),world._mat("c86b4a",0.95))
		seg.rotation.y=-a-PI/2
	for k in range(5):
		var wall=box(c+Vector3(-16+k*8,0.75,-12),Vector3(6,1.5,0.6),concrete,true)
		box(wall.position+Vector3(0,0.78,0),Vector3(6,0.06,0.62),world.mats.hazard)
	# Climbing ramp and firing range with target frames.
	var ramp=box(c+Vector3(18,1.6,6),Vector3(5,0.4,12),concrete,true)
	ramp.rotation.x=-0.28
	for k in range(4):
		box(c+Vector3(-22+k*4,2.0,18),Vector3(0.2,4.0,2.6),orange,true)
		box(c+Vector3(-22+k*4,0.03,10),Vector3(1.2,0.04,14),world.mats.paint)
	# Observation tower with hazard bands.
	var t=c+Vector3(26,0,-22)
	box(t+Vector3(0,7,0),Vector3(3,14,3),concrete,true)
	box(t+Vector3(0,14.6,0),Vector3(6,2.4,6),world._mat("3b2f5a"),true)
	box(t+Vector3(0,14.6,3.02),Vector3(5.4,1.2,0.06),world._mat("ffd6a0",0.3,2.0))
	for k in range(6): box(t+Vector3(0,1+k*2.2,1.52),Vector3(3,0.5,0.06),world.mats.hazard if k%2==0 else world.mats.hazard_dark)
	# A parked YUST training frame beside its gantry.
	mecha(c+Vector3(-24,0,-24),0.5)
	box(c+Vector3(-30,6,-24),Vector3(0.8,12,0.8),world.mats.hazard)
	box(c+Vector3(-27,11.5,-24),Vector3(6,0.6,0.8),world.mats.hazard)
	label(c+Vector3(0,6.0,-30),"YUST FIELD TRAINING GROUNDS","ffd06a",0.022)
	for k in range(4): lamp(c+Vector3(-32+k*21,0,32))
	spot(c+Vector3(4,0,24),"YUST FIELD TRAINING GROUNDS")
	spot(c+Vector3(-18,0,-16),"TRAINING FRAME")
	training_bounds=Rect2(c.x-34,c.z-34,68,68)
	counts.sites+=1

func mecha(at: Vector3,yaw: float) -> void:
	# Chunky 9 m utility training frame (original design): white armour, orange trim, cyan visor.
	var m=mecha_model()
	m.name="TrainingFrame"
	m.position=at
	m.rotation.y=yaw
	root.add_child(m)
	parked_mecha=m
	mecha_home=at+Vector3(0,0.3,0)
	_add_mecha_body(m)

func mecha_model() -> Node3D:
	var m=Node3D.new()
	var w=world._mat("eceae2",0.45)
	var o=world._mat("ff7a1a",0.45)
	var d=world._mat("33363f",0.6)
	var v=world._mat("2fe6e0",0.3,4.0)
	var parts=[
		[Vector3(-1.1,0.4,0.3),Vector3(1.4,0.8,2.4),d],[Vector3(1.1,0.4,0.3),Vector3(1.4,0.8,2.4),d],
		[Vector3(-1.1,2.2,0),Vector3(1.1,2.8,1.2),w],[Vector3(1.1,2.2,0),Vector3(1.1,2.8,1.2),w],
		[Vector3(-1.1,2.6,-0.62),Vector3(0.9,1.2,0.1),o],[Vector3(1.1,2.6,-0.62),Vector3(0.9,1.2,0.1),o],
		[Vector3(-1.1,4.6,0),Vector3(1.0,2.2,1.0),d],[Vector3(1.1,4.6,0),Vector3(1.0,2.2,1.0),d],
		[Vector3(0,5.9,0),Vector3(3.0,1.0,1.6),d],
		[Vector3(0,7.3,0),Vector3(3.4,2.2,2.2),w],[Vector3(0,7.5,-1.12),Vector3(2.2,1.2,0.1),o],
		[Vector3(-2.3,8.1,0),Vector3(1.4,1.2,1.6),o],[Vector3(2.3,8.1,0),Vector3(1.4,1.2,1.6),o],
		[Vector3(-2.4,6.6,0),Vector3(0.8,2.2,0.8),d],[Vector3(2.4,6.6,0),Vector3(0.8,2.2,0.8),d],
		[Vector3(-2.4,5.1,-0.2),Vector3(0.9,1.4,1.0),w],[Vector3(2.4,5.1,-0.2),Vector3(0.9,1.4,1.0),w],
		[Vector3(0,8.9,0),Vector3(1.3,1.1,1.3),w],[Vector3(0,8.95,-0.66),Vector3(1.0,0.3,0.06),v],
		[Vector3(0.45,9.7,0.2),Vector3(0.12,0.9,0.12),o]]
	for p in parts:
		var node=MeshInstance3D.new()
		var mesh=BoxMesh.new()
		mesh.size=p[1]
		node.mesh=mesh
		node.material_override=p[2]
		node.position=p[0]
		m.add_child(node)
	return m

func _add_mecha_body(m: Node3D) -> void:
	var body=StaticBody3D.new()
	var shape=CollisionShape3D.new()
	var b=BoxShape3D.new()
	b.size=Vector3(4.6,9.6,2.6)
	shape.shape=b
	shape.position=Vector3(0,4.8,0)
	body.add_child(shape)
	m.add_child(body)

# ---------------------------------------------------------------- 2 resort, hot spring, cable car top
func _resort(i: int) -> void:
	var c=centre(i)
	paved(i,38,world._mat("e6dcc8",0.85))
	var stone=world._mat("f4efe4",0.6)
	var glass=world._mat("2a5f78",0.2)
	var wood=world._mat("b48a5e",0.7)
	# Terraced hotel stepping down toward the sea (north), with glass balconies.
	for k in range(3):
		var y=k*4.2
		var z=-6.0+k*7.0
		var hotel=box(c+Vector3(0,y+2.1,z+18),Vector3(30-k*6,4.2,9),stone,true)
		box(c+Vector3(0,y+2.0,z+13.4),Vector3(28-k*6,2.6,0.1),glass)
		box(c+Vector3(0,y+4.35,z+13.0),Vector3(30-k*6,0.3,1.4),wood)
	label(c+Vector3(0,15.5,26),"SKY TERRACE RESORT","fff2d0",0.024,PI)
	# Infinity pool on the north edge, glowing at night.
	box(c+Vector3(0,0.4,-24),Vector3(26,0.8,10),stone,true)
	water(c+Vector3(0,0.82,-24),Vector2(24.5,8.5),"ResortPool")
	box(c+Vector3(0,0.2,-29.4),Vector3(26,0.4,0.8),world._mat("6fe8ff",0.3,2.0))
	for k in range(6):
		var l=box(c+Vector3(-12+k*4.8,0.35,-16.5),Vector3(0.8,0.2,2.0),wood)
		l.rotation.x=-0.15
	# Hot-spring pools with steam (east side).
	for k in range(3):
		var hp=c+Vector3(22,0,-8+k*9)
		cyl(hp+Vector3(0,0.35,0),3.2,0.7,world._mat("8a7f72",0.8))
		var pool=PlaneMesh.new()
		pool.size=Vector2(5.2,5.2)
		var wn=world._mesh_node(pool,world.mats.water,"HotSpring")
		wn.position=hp+Vector3(0,0.68,0)
		steam(hp+Vector3(0,0.9,0))
	label(c+Vector3(22,3.5,-14),"HOT SPRING","ffd6a0",0.016,PI)
	for k in range(5): lamp(c+Vector3(-30+k*15,0,-32),"ffcf8a")
	spot(c+Vector3(-10,0,4),"SKY TERRACE RESORT")
	spot(c+Vector3(17,0,6),"RESORT HOT SPRING")
	counts.sites+=1

func _cable_car() -> void:
	var low=Vector3(CABLE_LOWER.x,Layout.pad_height(3),CABLE_LOWER.y)
	var high=Vector3(CABLE_UPPER.x,Layout.pad_height(1),CABLE_UPPER.y)
	for st in [[low,"CABLE CAR · LOWER STATION"],[high,"CABLE CAR · UPPER STATION"]]:
		var p: Vector3=st[0]
		box(p+Vector3(0,0.15,0),Vector3(10,0.3,8),concrete,true)
		for x in [-4.5,4.5]: box(p+Vector3(x,3.5,0),Vector3(0.5,7,0.5),dark)
		box(p+Vector3(0,7.2,0),Vector3(10.5,0.5,8.5),world._mat("3b2f5a"))
		box(p+Vector3(0,6.8,4.2),Vector3(9,0.12,0.1),world._mat("ff3d9a",0.3,3.5))
		label(p+Vector3(0,8.2,4.4),st[1],"ffe9b8",0.016)
		spot(p+Vector3(3.5,0.3,2.5),st[1])
	# Pylons and the two ropes.
	var cable_path: Array[Vector3]=[]
	cable_path.append(low+Vector3.UP*7.0)
	# Shorter spans at the ends keep the rope clear of the ridge without raising the stations.
	for z in [681.0,724.0,767.0,810.0,853.0,891.0]:
		var p=low.lerp(high,inverse_lerp(low.z,high.z,z))
		var g=Layout.height_at(p.x,p.z)
		var hgt=13.0
		box(Vector3(p.x,g+hgt*0.5,p.z),Vector3(0.7,hgt,0.7),world.mats.metal)
		box(Vector3(p.x,g+hgt,p.z),Vector3(4.6,0.4,0.6),world.mats.metal)
		cable_path.append(Vector3(p.x,g+hgt,p.z))
	cable_path.append(high+Vector3.UP*7.0)
	for p in cable_path: cable_curve.add_point(p)
	for i in range(cable_path.size()-1):
		for side in [-1.6,1.6]:
			var offset=Vector3.RIGHT*side
			world._bar(cable_path[i]+offset,cable_path[i+1]+offset,0.05,dark)
	var paints=["ff3d9a","2fe6e0","f2c94c","b07dff"]
	for k in range(4):
		var cab=Node3D.new()
		cab.name="CableCarCabin"
		root.add_child(cab)
		var body=MeshInstance3D.new()
		var mesh=BoxMesh.new()
		mesh.size=Vector3(2.2,2.0,2.6)
		body.mesh=mesh
		body.material_override=world._mat(paints[k],0.4)
		body.position=Vector3(0,-1.8,0)
		cab.add_child(body)
		var win=MeshInstance3D.new()
		var wm=BoxMesh.new()
		wm.size=Vector3(2.25,0.8,2.0)
		win.mesh=wm
		win.material_override=world._mat("ffe2a8",0.3,1.6)
		win.position=Vector3(0,-1.5,0)
		cab.add_child(win)
		movers.append({"kind":"cable","node":cab,"curve":cable_curve,"offset":Vector3(1.6 if k%2==0 else -1.6,0,0),"t":float(k)/4.0,"dir":1.0 if k%2==0 else -1.0,"speed":0.012})

# ---------------------------------------------------------------- 3 meditation garden & lantern park
func _garden(i: int) -> void:
	var c=centre(i)
	paved(i,22,world._mat("d8d2c4",0.9))
	var hedge=world._mat("4f8a4f",0.9)
	for r in [8.0,14.0]:
		for k in range(int(r*1.6)):
			var a=TAU*k/int(r*1.6)
			if k%int(r*0.4)==0: continue
			var h=box(c+Vector3(cos(a)*r,0.4,sin(a)*r),Vector3(1.6,0.8,0.8),hedge)
			h.rotation.y=-a-PI/2
	# Still water basin and a modern lantern sculpture: stacked glowing rings, white and cyan.
	cyl(c+Vector3(0,0.25,0),4.5,0.5,world._mat("d8d2c4",0.7))
	var basin=PlaneMesh.new()
	basin.size=Vector2(7.6,7.6)
	world._mesh_node(basin,world.mats.water,"MeditationBasin").position=c+Vector3(0,0.48,0)
	for k in range(6):
		var r=2.0-k*0.3
		cyl(c+Vector3(0,1.2+k*0.9,0),r,0.25,world._mat("eef8ff" if k%2==0 else "6fe8ff",0.3,2.5))
	box(c+Vector3(0,6.8,0),Vector3(0.2,1.4,0.2),world._mat("eef8ff",0.3,3.0))
	# Lantern park: a ring of low glowing lanterns among flowering padauk-yellow trees.
	for k in range(12):
		var a=TAU*k/12+0.13
		var p=c+Vector3(cos(a)*19,0,sin(a)*19)
		box(p+Vector3(0,0.6,0),Vector3(0.6,1.2,0.6),world._mat("fff2c8",0.3,2.2))
	label(c+Vector3(0,9.0,0),"MEDITATION GARDEN","eef8ff",0.018)
	spot(c+Vector3(0,0,10.5),"MEDITATION GARDEN")
	counts.sites+=1

# ---------------------------------------------------------------- 4 hill village & tea plantation
func _village(i: int) -> void:
	var c=centre(i)
	var walls=["f1e4c8","e9c9a8","d7e6d2","cfe0ea","f2d0c4"]
	# Six small homes around a little square (residential, not enterable).
	for k in range(6):
		var a=TAU*k/6+0.4
		var p=c+Vector3(cos(a)*20,0,sin(a)*16)
		if Vector2(p.x,p.z).distance_to(CABLE_LOWER)<12.0: continue
		box(p+Vector3(0,2.0,0),Vector3(6,4,5),world._mat(walls[k%5]),true)
		var roof=box(p+Vector3(0,4.3,0),Vector3(6.6,0.4,5.6),world._mat("4f6a7a"))
		box(p+Vector3(0,1.6,2.52),Vector3(1.2,2.2,0.06),world._mat("ffd6a0",0.3,1.2))
	# Mountain tea house in the middle with stools.
	box(c+Vector3(0,2.0,-2),Vector3(9,4,7),world._mat("e8d2b0"),true)
	box(c+Vector3(0,4.3,-2),Vector3(10,0.4,8),world._mat("3b2f5a"))
	box(c+Vector3(0,3.4,1.6),Vector3(8,0.6,0.2),dark)
	label(c+Vector3(0,3.4,1.75),"MOUNTAIN TEA HOUSE · လက်ဖက်ရည်","ffe9b8",0.011)
	for k in range(4):
		cyl(c+Vector3(-3+k*2,0.2,4.5),0.22,0.4,world._mat(["d8453f","3d7fd6","3fae6a","e2b33d"][k]))
	# Tea plantation terraces on the slope uphill (south-west) and a goat pen.
	var tea=world._mat("3f7a3a",0.9)
	for row in range(7):
		for k in range(3):
			var p=c+Vector3(-26+k*9,0,22+row*3)
			var y=Layout.height_at(p.x,p.z)
			box(Vector3(p.x,y+0.45,p.z),Vector3(7.5,0.9,1.2),tea)
	box(c+Vector3(24,0.5,4),Vector3(0.15,1.0,10),world.mats.wood)
	box(c+Vector3(32,0.5,4),Vector3(0.15,1.0,10),world.mats.wood)
	for k in range(5):
		var g=c+Vector3(26+k*1.4,0.5,1+k*1.5)
		box(g,Vector3(0.5,0.6,1.1),world._mat("f4f1e8"))
		box(g+Vector3(0,0.3,-0.65),Vector3(0.35,0.35,0.4),world._mat("f4f1e8"))
	label(c+Vector3(0,6.5,-2),"HILL VILLAGE","ffe9b8",0.02)
	for k in range(4): lamp(c+Vector3(-12+k*8,0,10))
	spot(c+Vector3(0,0,3.5),"MOUNTAIN TEA HOUSE")
	spot(c+Vector3(-14,0,18),"HILL TEA PLANTATION")
	spot(c+Vector3(22,0,10),"GOAT FARM")
	counts.sites+=1

# ---------------------------------------------------------------- 5 campground, zipline, stargazing
func _camp(i: int) -> void:
	var c=centre(i)
	var tents=["e2574c","f2c94c","4fa3c7","7ad08a","ef8fb0"]
	for k in range(5):
		var a=TAU*k/5
		var p=c+Vector3(cos(a)*12,0,sin(a)*10)
		var tent=MeshInstance3D.new()
		var prism=PrismMesh.new()
		prism.size=Vector3(3.2,2.0,3.6)
		tent.mesh=prism
		tent.material_override=world._mat(tents[k],0.8)
		tent.position=p+Vector3(0,1.0,0)
		tent.rotation.y=-a
		root.add_child(tent)
	# Campfire with flickering light, log seats and picnic tables.
	cyl(c+Vector3(0,0.15,0),1.2,0.3,world._mat("6a6a6a"))
	box(c+Vector3(0,0.55,0),Vector3(0.6,0.7,0.6),world._mat("ff8a2a",0.3,5.0))
	var fire=OmniLight3D.new()
	fire.position=c+Vector3(0,1.4,0)
	fire.light_color=Color("ff9a4a")
	fire.omni_range=12
	fire.light_energy=0.0
	fire.set_meta("night_energy",2.8)
	root.add_child(fire)
	world.lamps.append(fire)
	movers.append({"kind":"flicker","node":fire,"t":0.0})
	for k in range(4):
		var a=TAU*k/4+0.4
		var log_seat=cyl(c+Vector3(cos(a)*3.2,0.3,sin(a)*3.2),0.3,2.2,world.mats.dark_wood)
		log_seat.rotation=Vector3(PI/2,-a,0)
	label(c+Vector3(0,5.0,-14),"HILLTOP CAMPGROUND","ffe9b8",0.018)
	spot(c+Vector3(5,0,6),"HILLTOP CAMPGROUND")
	counts.sites+=1
	# Stargazing deck by the reservoir lookout, with telescopes.
	var deck=Vector3(205.63,Layout.height_at(205.63,690),690)
	box(deck+Vector3(0,0.3,0),Vector3(8,0.6,6),world.mats.wood,true)
	for k in range(3):
		var tp=deck+Vector3(-2.5+k*2.5,0.6,-1.5)
		box(tp+Vector3(0,0.7,0),Vector3(0.1,1.4,0.1),dark)
		var scope=box(tp+Vector3(0,1.5,0),Vector3(0.25,0.25,1.2),white)
		scope.rotation.x=0.6
	label(deck+Vector3(0,3.5,0),"STARGAZING DECK","bff4ff",0.014)
	spot(deck+Vector3(0,0.6,2.2),"STARGAZING DECK")

func _zipline() -> void:
	var start=Vector3(198.59,Layout.height_at(198.59,712),712)
	var finish=Vector3(98.59,Layout.height_at(98.59,705),705)
	world.grass_exclusions.append(Rect2(start.x-9.0,start.z-9.0,28,23))
	box(start+Vector3(0,5,0),Vector3(3,10,3),world.mats.hazard_dark,true)
	box(start+Vector3(0,10.2,0),Vector3(4,0.4,4),world.mats.wood,true)
	box(finish+Vector3(0,1.5,0),Vector3(2,3,2),world.mats.hazard_dark,true)
	world._bar(start+Vector3(0,10.5,0),finish+Vector3(0,3.0,0),0.04,dark)
	label(start+Vector3(0,12,0),"ZIPLINE","ffcf3a",0.016)
	spot(start+Vector3(2.6,0,0),"ZIPLINE TOWER")
	var rider=Node3D.new()
	rider.name="ZiplineSeat"
	root.add_child(rider)
	var seat=MeshInstance3D.new()
	var sm=BoxMesh.new()
	sm.size=Vector3(0.6,0.9,0.6)
	seat.mesh=sm
	seat.material_override=world._mat("ff3d9a",0.4)
	seat.position=Vector3(0,-1.0,0)
	rider.add_child(seat)
	movers.append({"kind":"zip","node":rider,"a":start+Vector3(0,10.5,0),"b":finish+Vector3(0,3.0,0),"t":0.0})

# ---------------------------------------------------------------- 6 civic-defence sensor station
func _defence(i: int) -> void:
	var c=centre(i)
	paved(i,20,world._mat("6a6e72",0.9))
	var armour=world._mat("4a4f5c",0.55)
	# Radar dome, rotating dish, antenna masts, perimeter fence and an armoured shelter door.
	var dome=MeshInstance3D.new()
	var s=SphereMesh.new()
	s.radius=6
	s.height=8
	s.is_hemisphere=true
	dome.mesh=s
	dome.material_override=world._mat("eceae2",0.5)
	dome.position=c+Vector3(-8,1.5,-4)
	root.add_child(dome)
	box(c+Vector3(-8,0.75,-4),Vector3(12.5,1.5,12.5),armour,true)
	var spin=Node3D.new()
	spin.set_script(load("res://scripts/spin.gd"))
	spin.speed=0.8
	spin.position=c+Vector3(9,8,-6)
	root.add_child(spin)
	box(c+Vector3(9,4,-6),Vector3(0.8,8,0.8),armour)
	var dish=MeshInstance3D.new()
	var dm=BoxMesh.new()
	dm.size=Vector3(7,3,0.3)
	dish.mesh=dm
	dish.material_override=world._mat("d8d4c8",0.5)
	dish.rotation.x=-0.4
	spin.add_child(dish)
	for k in range(3):
		box(c+Vector3(-16+k*3,6,10),Vector3(0.3,12-k*2,0.3),armour)
		box(c+Vector3(-16+k*3,12.2-k*2,10),Vector3(0.5,0.5,0.5),world._mat("ff3030",0.3,5.0))
	for k in range(16):
		var a=TAU*k/16
		box(c+Vector3(cos(a)*21,1.1,sin(a)*21),Vector3(0.12,2.2,0.12),world.mats.metal)
	box(c+Vector3(8,2.0,9),Vector3(10,4,4),armour,true)
	box(c+Vector3(8,1.6,11.02),Vector3(5,3.0,0.1),world._mat("6a5a7a",0.5))
	for k in range(10): box(c+Vector3(3.5+k,3.4,11.06),Vector3(1.0,0.4,0.04),world.mats.hazard if k%2==0 else world.mats.hazard_dark)
	label(c+Vector3(8,5.2,11.2),"SHELTER 07","f0b429",0.018)
	label(c+Vector3(0,12,0),"CIVIC DEFENCE SENSOR STATION","ffd06a",0.018)
	spot(c+Vector3(0,0,14),"CIVIC DEFENCE SENSOR STATION")
	counts.sites+=1
