extends RefCounted
## Whole-town, real-scale set dressing for the selected updated masterplan.
const Layout=preload("res://scripts/terrain_layout.gd")
const Roads=preload("res://scripts/road_layout.gd")
var world
var root: Node3D
var b
var rng=RandomNumberGenerator.new()
var leaves: Array=[]
var trunks: Array=[]
var fronds: Array=[]
var palm_trunks: Array=[]
var flower_canopies: Array=[]
var metal: Material
var amber: Material
var timber: Material
var teal: Material
var forest_count=0
var palm_count=0
var parked_cars=0

func setup(owner_world) -> void:
	world=owner_world
	root=Node3D.new()
	root.name="MasterplanDressing"
	world.add_child(root)
	rng.seed=2026111901
	b=load("res://scripts/reference_buildings.gd").new()
	b.world=world
	b.frame=world._mat("8b9a98")
	b.roof_material=world._mat("40545b")
	b.blue_roof=world._mat("385e76",0.35)
	b.glass=world._mat("31596b",0.28)
	b.facade=world._mat("99a9a1")
	b.warm=world._mat("aa855d")
	b.window_light=world._mat("ffbe70",0.5,0.8)
	b.accents=[world._mat("427f83"),world._mat("b58a63"),world._mat("7c7096"),world._mat("65865d")]
	metal=world._mat("3f555e",0.55)
	amber=world._mat("ffd197",0.4,2.2)
	timber=world._mat("876c4a")
	teal=world._mat("3d8189",0.65)
	_boulevards()
	_block_landscape()
	_public_spaces()
	_market_stalls()
	_forest()
	_gardens()
	_district_groves()
	_waterfront()
	_flush_vegetation()
	root.set_meta("forest_trees",forest_count)
	root.set_meta("palms",palm_count)
	root.set_meta("parked_cars",parked_cars)
	print("MASTERPLAN_DRESSING_READY forest=",forest_count," palms=",palm_count," parked_cars=",parked_cars)

func at(x: float,z: float,up=0.0) -> Vector3:
	return Vector3(x,Layout.height_at(x,z)+up,z)

func box(pos: Vector3,size: Vector3,mat: Material,title: String,solid=false) -> MeshInstance3D:
	return b.box(root,pos,size,mat,title,solid)

func light_at(pos: Vector3,actual=false,towards=Vector3.FORWARD) -> void:
	if not world.dressing_clearance.reserve(Vector2(pos.x,pos.z),1.55,"lamp"): return
	box(pos+Vector3(0,2.9,0),Vector3(0.14,5.8,0.14),metal,"BoulevardLamp")
	var head=pos+Vector3.UP*5.9+towards*1.0
	b.beam(root,pos+Vector3.UP*5.5,head,0.10,metal,"StreetlightArm")
	var emitter=box(head,Vector3(0.65,0.18,0.8),amber,"emit_lantern")
	emitter.add_to_group("city_lamp_emitters")
	if actual:
		var lamp=OmniLight3D.new()
		lamp.position=head-Vector3.UP*0.2
		lamp.light_color=Color("ffc17f")
		lamp.omni_range=19
		lamp.omni_attenuation=1.25
		lamp.set_meta("night_energy",2.4)
		lamp.light_energy=2.4 if world.night else 0
		root.add_child(lamp)
		world.lamps.append(lamp)

func palm(pos: Vector3,height=10.0) -> void:
	if not world.dressing_clearance.reserve(Vector2(pos.x,pos.z),6.7,"tree"): return
	palm_trunks.append(Transform3D(Basis().scaled(Vector3(0.36,height,0.36)),pos+Vector3.UP*height/2))
	for i in range(7):
		var angle=TAU*i/7+rng.randf_range(-0.15,0.15)
		fronds.append(Transform3D(Basis(Vector3.UP,angle).scaled(Vector3.ONE*rng.randf_range(0.9,1.2)),pos+Vector3.UP*height))
	palm_count+=1

func tree(pos: Vector3,height: float,radius: float,flower=false) -> bool:
	# Species vary the crown: umbrella rain tree, dense round crown, tall narrow crown.
	if not world.dressing_clearance.reserve(Vector2(pos.x,pos.z),radius*1.50,"tree"): return false
	var species=rng.randi_range(0,2)
	var lean=Vector3(rng.randf_range(-0.12,0.12),0,rng.randf_range(-0.12,0.12))
	var trunk_height=height*(0.62 if species==0 else 0.55 if species==1 else 0.45)
	trunks.append(Transform3D(Basis().scaled(Vector3(0.6,trunk_height,0.6)),pos+Vector3.UP*trunk_height*0.5))
	var hue=rng.randf_range(0.21,0.34)
	var tint=Color.from_hsv(hue,rng.randf_range(0.5,0.68),rng.randf_range(0.5,0.7))
	var flower_hue=[0.02,0.05,0.07,0.12,0.94][rng.randi_range(0,4)]
	var lobes=[]
	match species:
		0:
			for i in range(5):
				var angle=TAU*i/5.0+rng.randf_range(-0.4,0.4)
				lobes.append([Vector3(cos(angle)*radius*0.62,trunk_height+rng.randf_range(-0.2,0.5),sin(angle)*radius*0.62),radius*0.78,0.42])
			lobes.append([Vector3(0,trunk_height+radius*0.28,0),radius*0.86,0.4])
		1:
			for i in range(5):
				var angle=TAU*i/5.0+rng.randf_range(-0.5,0.5)
				var ring=0.38 if i<4 else 0.0
				lobes.append([Vector3(cos(angle)*radius*ring,trunk_height+0.15*height*(i/2),sin(angle)*radius*ring),radius*(0.82-0.05*i),0.72])
		_:
			for i in range(4):
				var shrink=1.0-i*0.22
				lobes.append([Vector3(rng.randf_range(-0.4,0.4),trunk_height+i*height*0.17,rng.randf_range(-0.4,0.4)),radius*0.62*shrink,0.95])
	for i in range(lobes.size()):
		var lobe=lobes[i]
		var rise=float(i)/maxf(1.0,lobes.size()-1.0)
		var colour=tint.lightened(0.08+0.22*rise)
		colour.h=fposmod(colour.h+rng.randf_range(-0.012,0.012),1.0)
		var scale=Vector3(lobe[1],lobe[1]*lobe[2],lobe[1])
		var value={"t":Transform3D(Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(scale),pos+lobe[0]+lean*height*rise),"colour":colour}
		if flower and i>=lobes.size()-3:
			value.colour=Color.from_hsv(flower_hue,0.62,rng.randf_range(0.88,1.0))
			flower_canopies.append(value)
		else: leaves.append(value)
	return true

func _boulevards() -> void:
	for edge in Roads.EDGES:
		if Roads.is_mountain(edge): continue
		var a: Vector3=Roads.NODES[edge[0]]
		var end: Vector3=Roads.NODES[edge[1]]
		var length=Vector2(a.x-end.x,a.z-end.z).length()
		var side=Vector3(-(end-a).z,0,(end-a).x).normalized()
		var half=Roads.width(edge)/2
		for i in range(1,int(length/23)):
			var p: Vector3=Roads.point(a,end,float(i)/int(length/23))
			for sign_value in [-1,1]:
				var x=p+side*(half+3.35)*sign_value
				# Lamps stand on the road deck grade even beside elevated approaches.
				x.y=maxf(x.y,Layout.height_at(x.x,x.z))
				light_at(x,(i+(1 if sign_value>0 else 0))%2==0,-side*sign_value)
				if i%2==0 and edge[0] not in ["ramp_w_top","ramp_e_bottom","ramp_e_top"]:
					var plant=p+side*(half+5.8)*sign_value
					if Layout.in_world(plant.x,plant.z): palm(at(plant.x,plant.z),rng.randf_range(8,12))
	# Static curbside vehicles indicate scale without implying traffic simulation.
	for entry in [Vector3(320,0,95),Vector3(320,0,210),Vector3(592,0,180),Vector3(30,0,400),Vector3(30,0,490),Vector3(260,0,400),Vector3(200,0,-660),Vector3(410,0,-660)]:
		car(at(entry.x,entry.z),rng.randf_range(-0.1,0.1))

func car(pos: Vector3,angle: float) -> void:
	var car_root=Node3D.new()
	car_root.name="ParkedElectricCar"
	car_root.position=pos
	car_root.rotation.y=angle
	root.add_child(car_root)
	var paint=b.accents[parked_cars%4]
	b.box(car_root,Vector3(0,0.7,0),Vector3(1.9,0.65,3.9),paint,"Body")
	b.box(car_root,Vector3(0,1.2,-0.15),Vector3(1.6,0.6,2.1),b.glass,"Cabin")
	for x in [-0.95,0.95]:
		for z in [-1.2,1.2]:
			var wheel=b.cylinder(car_root,Vector3(x,0.4,z),0.36,0.2,metal,"Wheel")
			wheel.rotation.z=PI/2
	for x in [-0.55,0.55]: b.box(car_root,Vector3(x,0.7,2),Vector3(0.4,0.16,0.1),amber,"emit_headlight")
	parked_cars+=1

func court(rect: Rect2,tennis: bool) -> void:
	var c=rect.get_center()
	var ground=Layout.height_at(c.x,c.y)+0.04
	var pos=Vector3(c.x,ground,c.y)
	box(pos,Vector3(rect.size.x,0.08,rect.size.y),teal,"TennisCourt" if tennis else "CampusSportsCourt",true)
	world.grass_exclusions.append(rect)
	var line=world._mat("c4d3c5")
	for sign_value in [-1,1]:
		box(pos+Vector3(sign_value*(rect.size.x/2-2),0.1,0),Vector3(0.15,0.02,rect.size.y-4),line,"CourtLine")
		box(pos+Vector3(0,0.1,sign_value*(rect.size.y/2-2)),Vector3(rect.size.x-4,0.02,0.15),line,"CourtLine")
	box(pos+Vector3(0,0.1,0),Vector3(0.16,0.02,rect.size.y-4),line,"CentreLine")
	if tennis:
		for i in range(16): box(pos+Vector3(0,0.7,-rect.size.y/2+2+i*(rect.size.y-4)/15),Vector3(0.04,1.2,0.035),metal,"TennisNet")
		box(pos+Vector3(0,1.3,0),Vector3(0.1,0.07,rect.size.y-4),line,"NetTape")
	else:
		for side in [-1,1]:
			box(pos+Vector3(side*(rect.size.x/2-3),2,0),Vector3(0.18,4,0.18),metal,"HoopPost")
			box(pos+Vector3(side*(rect.size.x/2-3.3),3.8,0),Vector3(0.15,1.2,2),b.facade,"Backboard")
	# Mesh fence remains permeable visually; collider only around the play surface.
	for i in range(int(rect.size.x/4)+1):
		for side in [-1,1]: box(pos+Vector3(-rect.size.x/2+i*4,1.7,side*rect.size.y/2),Vector3(0.08,3.4,0.08),metal,"CourtFencePost")
	for y in [0.7,1.7,2.7]:
		for side in [-1,1]: box(pos+Vector3(0,y,side*rect.size.y/2),Vector3(rect.size.x,0.03,0.03),metal,"FenceWire")

func _public_spaces() -> void:
	court(Rect2(208,163,64,34),false)
	court(Rect2(366,471,52,34),true)
	_training_display(at(245,156))
	# Plant around the campus lawns and plazas.
	for pos in [Vector2(112,142),Vector2(184,151),Vector2(110,178),Vector2(184,190),Vector2(87,219),Vector2(410,205),Vector2(447,375),Vector2(480,472)]:
		tree(at(pos.x,pos.y),rng.randf_range(7,10),rng.randf_range(3,4),true)
	# Tech plaza: lightweight white tensile canopy over a social seating area.
	var plaza=at(438,183)
	for side in [-1,1]:
		box(plaza+Vector3(side*10,3.5,0),Vector3(0.17,7,0.17),b.frame,"PlazaMast")
	for side in [-1,1]:
		var shade=box(plaza+Vector3(side*5,6.15,0),Vector3(10.4,0.14,15),b.facade,"TechPlazaShade")
		shade.rotation.z=-side*0.18
	for i in range(3):
		b.terrace(root,root,plaza+Vector3(-7+i*7,0,0),5,4,false)
	for p in [Vector2(421,121),Vector2(448,123),Vector2(429,147),Vector2(453,149),
			Vector2(413,197),Vector2(437,215)]:
		var island=at(p.x,p.y)
		box(island+Vector3.UP*0.16,Vector3(9.3,0.32,5.8),b.facade,"TechPlazaPlanter")
		box(island+Vector3.UP*0.34,Vector3(8.8,0.09,5.3),world.mats.leaf,"PlazaGarden")
		tree(island+Vector3.UP*0.34,6.8,3.3,p.x<430)
		world._bench(p.x,p.y+4)
	# Recognisable playground slide, swings and sand area inside its reserved plot.
	var play=at(189,435)
	box(play,Vector3(16,0.15,8),world._mat("b79a6b"),"PlaygroundSurface")
	box(play+Vector3(-3,1.8,0),Vector3(2,0.2,2),b.accents[2],"SlidePlatform")
	var slide=box(play+Vector3(0,1.0,0),Vector3(5,0.18,1.6),b.accents[1],"PlaygroundSlide")
	slide.rotation.z=-0.32
	for x in [-4,-2]: box(play+Vector3(x,0.9,0),Vector3(0.12,1.8,0.12),metal,"SlideSupport")
	# Cultivated community gardens and a low solar greenhouse by the lake.
	for origin in [Vector2(185,580),Vector2(375,535)]:
		for i in range(4):
			var p=at(origin.x+i*7,origin.y)
			box(p+Vector3(0,0.3,0),Vector3(5,0.6,10),timber,"RaisedGardenBed")
			for j in range(5): b.garden(root,p+Vector3(0,0.6,-4+j*2),3.5)
	var greenhouse=at(400,550)
	box(greenhouse+Vector3(0,1.7,0),Vector3(12,3.4,9),b.glass,"CommunityGreenhouse")
	for x in [-6,-3,0,3,6]: box(greenhouse+Vector3(x,1.7,0),Vector3(0.13,3.6,9.2),b.frame,"GreenhouseFrame")
	b.solar(root,greenhouse+Vector3(0,3.6,0),12,9)

func _training_display(pos: Vector3) -> void:
	var shell=b.frame
	var joints=metal
	var torso=pos+Vector3.UP*5.2
	box(pos+Vector3.UP*0.15,Vector3(8,0.30,5),b.facade,"TrainingDisplayPlinth")
	box(torso,Vector3(2.7,2.45,1.6),shell,"TrainerTorso")
	box(torso+Vector3(0,1.62,0.18),Vector3(1.3,1.1,1.05),shell,"TrainerHead")
	box(torso+Vector3(0,1.69,0.73),Vector3(0.94,0.29,0.09),world.mats.cyan,"TrainerVisor")
	for side in [-1,1]:
		var hip=pos+Vector3(side*0.82,4.15,0)
		var knee=pos+Vector3(side*1.18,2.21,0.27)
		var ankle=pos+Vector3(side*1.42,0.67,0)
		b.beam(root,hip,knee,0.76,shell,"TrainerThigh")
		box(knee,Vector3(0.82,0.75,0.8),joints,"TrainerKnee")
		b.beam(root,knee,ankle,0.65,shell,"TrainerShin")
		box(ankle+Vector3(0,-0.1,0.34),Vector3(1,0.55,1.65),shell,"TrainerFoot")
		var shoulder=torso+Vector3(side*1.59,0.69,0)
		var elbow=torso+Vector3(side*2.09,-0.76,0.02)
		b.beam(root,shoulder,elbow,0.75,shell,"TrainerArm")
		b.beam(root,elbow,elbow+Vector3(side*0.12,-1.12,0.32),0.57,joints,"TrainerForearm")

func _block_landscape() -> void:
	var plaza_material=world._mat("a6a79a",0.9)
	var garden_material=ShaderMaterial.new()
	garden_material.shader=load("res://shaders/courtyard_lawn.gdshader")
	for rect in [Rect2(100,82,101,124),Rect2(412,151,44,69),Rect2(143,425,114,20),
			Rect2(81,532,164,13),Rect2(343,456,81,106),Rect2(424,520,72,72),
			Rect2(24,-665,528,300)]:
		world._surface(rect,plaza_material,"DistrictPromenade",false,plaza_height,2.0,true)
	for rect in [Rect2(114,95,75,48),Rect2(119,159,77,40),Rect2(154,427,72,16),
			Rect2(367,514,48,45),Rect2(443,537,42,45)]:
		world._surface(rect,garden_material,"PlantedCourtyard",false,
			func(x: float,z: float)->float: return Layout.base_height_at(x,z)+0.061,2.0,true)
	for building in world.get_node("PrototypeBuildings").get_children():
		var plot: Rect2=building.get_meta("reserved_plot")
		# Give each plot a continuous sidewalk along its south frontage.
		world._surface(Rect2(plot.position.x,plot.end.y-4,plot.size.x,7),
			plaza_material,"FrontageSidewalk",false,plaza_height,2.0,true)
	for p in [Vector2(116,93),Vector2(188,101),Vector2(115,194),Vector2(161,196),
			Vector2(419,157),Vector2(455,211),Vector2(227,434),Vector2(152,437),
			Vector2(367,521),Vector2(414,553),Vector2(450,552),Vector2(476,577)]:
		tree(at(p.x,p.y),9.0,4.6,true)
		world._bench(p.x+3,p.y+2)
		light_at(at(p.x+4,p.y),true)

func plaza_height(x: float,z: float) -> float:
	return Layout.base_height_at(x,z)+0.049

func _market_stalls() -> void:
	var awnings: Array[Material]=[]
	for colour in ["cf657d","deab52","67bfa6","518ebf","b276b4"]:
		awnings.append(world._mat(colour,0.86))
	# Keep a central pedestrian aisle between the two front halls.
	for lane in [[136,-601,-416],[463,-603,-416],[296,-490,-414]]:
		for z in range(lane[1],lane[2],9):
			var x: int=lane[0]
			var p=at(x,z)
			var colour: Material=awnings[(absi(z)+x)%awnings.size()]
			var awning=box(p+Vector3(0,2.8,0),Vector3(6,0.17,6),colour,"MarketAwning")
			awning.rotation.x=0.075
			for side in [-1,1]:
				box(p+Vector3(side*2.5,1.4,-2.4),Vector3(0.11,2.8,0.11),metal,"StallFrame")
			box(p+Vector3(0,0.6,1.2),Vector3(4,1.2,1.05),timber,"ServingCounter")
			box(p+Vector3(0,2.52,1.5),Vector3(4.1,0.12,0.1),amber,"StallLight").add_to_group("city_lamp_emitters")
			for i in range(4):
				box(p+Vector3(-1.45+i*0.94,1.37,1.2),Vector3(0.7,0.3,0.6),
					awnings[(i+x)%awnings.size()],"MarketProduce")
			if z%4==0: light_at(p+Vector3(3.6,0,0),true)
	for x in [230,352]:
		b.terrace(root,root,at(x,-386),16,10,false)

func _forest() -> void:
	for parcel in [Layout.NORTH_HILLS,Layout.WEST_HILLS]:
		for x in range(int(parcel.position.x)+8,int(parcel.end.x)-5,11):
			for z in range(int(parcel.position.y)+8,int(parcel.end.y)-5,11):
				var xx=x+rng.randf_range(-3,3)
				var zz=z+rng.randf_range(-3,3)
				var trail=Layout.NORTH_TRAIL if zz<0 else Layout.WEST_TRAIL
				var trail_distance=Layout.trail_distance(Vector2(xx,zz),trail)
				if trail_distance<14: continue
				if zz<0 and absf(xx-Layout.north_stream_x(zz))<19: continue
				if not Roads.sample(xx,zz).is_empty(): continue
				if tree(at(xx,zz),rng.randf_range(12,17) if trail_distance<22 else rng.randf_range(12,23),rng.randf_range(4.5,6.0) if trail_distance<22 else rng.randf_range(5.4,8.4)):
					forest_count+=1
	# Small steel-and-composite viewing decks beside the waterfall trail.
	for p in [Vector2(240,-105),Vector2(205,-145),Vector2(-160,195)]:
		var pos=at(p.x,p.y,0.3)
		box(pos,Vector3(11,0.4,7),timber,"ForestViewingDeck")
		b.terrace(root,root,pos+Vector3(0,0.3,0),9,5,false)
	for fall in Layout.NORTH_FALLS:
		_waterfall(fall)
	for x in range(505,583,12):
		for z in range(-315,-12,12):
			var xx=x+rng.randf_range(-3.7,3.7)
			var zz=z+rng.randf_range(-3.7,3.7)
			if not Roads.sample(xx,zz).is_empty() or not Layout.channel_sample(xx,zz).is_empty(): continue
			tree(at(xx,zz),rng.randf_range(10,18),rng.randf_range(4.5,7.0))
	for x in range(-288,-12,13):
		for z in range(501,599,13):
			var xx=x+rng.randf_range(-4.3,4.3)
			var zz=z+rng.randf_range(-4.3,4.3)
			if not Roads.sample(xx,zz).is_empty() or world._inside_stair(xx,zz): continue
			tree(at(xx,zz),rng.randf_range(9,15),rng.randf_range(4.1,6.5))
	# Far-bank greenery frames the river view without hiding the promenade.
	for x in range(-285,605,14):
		var z=Layout.river_north_bank(x)+Layout.river_width(x)+20
		tree(at(x,z),rng.randf_range(8,14),rng.randf_range(3,5))
		if x%3==0: palm(at(x+5,z+5),10)

func _waterfall(fall: Vector2i) -> void:
	var surface=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(fall.x,fall.y):
		var x=Layout.north_stream_x(z)
		var next_x=Layout.north_stream_x(z+1)
		var y=Layout.north_water_y(z)+0.07
		var next_y=Layout.north_water_y(z+1)+0.07
		var a=Vector3(x-3.1,y,z)
		var b=Vector3(x+3.1,y,z)
		var c=Vector3(next_x-3.1,next_y,z+1)
		var d=Vector3(next_x+3.1,next_y,z+1)
		for p in [a,b,c,b,d,c]:
			surface.set_uv(Vector2((p.x-Layout.north_stream_x(p.z))/6.2+0.5,(p.z-fall.x)/(fall.y-fall.x)))
			surface.add_vertex(p)
		if z%3==0:
			for side in [-1,1]:
				var stone=boulder(Vector3(x+side*7.5,y-1.8,z),Vector3(5.5,4.4,4.5))
				stone.rotation.y=rng.randf_range(0,TAU)
	surface.generate_normals()
	var waterfall=MeshInstance3D.new()
	waterfall.name="WaterfallFoam"
	waterfall.mesh=surface.commit()
	var foam=ShaderMaterial.new()
	foam.shader=load("res://shaders/waterfall_foam.gdshader")
	waterfall.material_override=foam
	root.add_child(waterfall)

func boulder(pos: Vector3, dimensions: Vector3) -> MeshInstance3D:
	var rock=SphereMesh.new()
	rock.radial_segments=6
	rock.rings=3
	var piece=MeshInstance3D.new()
	piece.name="WaterfallCliff"
	piece.mesh=rock
	piece.material_override=world.mats.rock
	piece.position=pos
	piece.scale=dimensions
	root.add_child(piece)
	return piece

func _gardens() -> void:
	for building in world.get_node("PrototypeBuildings").get_children():
		var plot: Rect2=building.get_meta("reserved_plot")
		for corner in [plot.position+Vector2(2,2),Vector2(plot.end.x-2,plot.position.y+2)]:
			if not Roads.sample(corner.x,corner.y).is_empty(): continue
			palm(at(corner.x,corner.y),rng.randf_range(7,10))
	# Populate the landscape strips; explicitly reject routes, plots and water.
	for region in [Rect2(15,20,265,255),Rect2(350,20,230,255),Rect2(55,325,180,280),Rect2(355,325,235,280)]:
		for x in range(int(region.position.x),int(region.end.x),14):
			for z in range(int(region.position.y),int(region.end.y),14):
				if Layout.wet(x,z) or not Roads.sample(x,z).is_empty(): continue
				var excluded=false
				for rect in world.grass_exclusions:
					if rect.grow(3).has_point(Vector2(x,z)): excluded=true; break
				if excluded: continue
				for route in world.grass_routes:
					if route.rect.grow(3).has_point(Vector2(x,z)) and Layout.trail_distance(Vector2(x,z),route.route)<5: excluded=true; break
				if excluded: continue
				if rng.randf()<0.38: tree(at(x,z),rng.randf_range(6,10),rng.randf_range(2.5,3.8),rng.randf()<0.13)
				else:
					for i in range(3):
						var p=at(x+rng.randf_range(-2,2),z+rng.randf_range(-2,2),0.7)
						leaves.append({"t":Transform3D(Basis().scaled(Vector3(1.4,0.8,1.2)),p),"colour":Color(0.43,0.64,0.39)})
	for i in range(45):
		var a=TAU*i/45
		var p=Vector2(550+48*cos(a),548+45*sin(a))
		for j in range(3):
			var reed=box(at(p.x+j*0.35,p.y,0.8),Vector3(0.08,1.6,0.08),world.mats.leaf,"LakeReed")
			reed.rotation.z=rng.randf_range(-0.18,0.18)
	# Lakeside fishing pier and a warm covered lookout on the existing boardwalk.
	var pier=at(508,555,0.1)
	box(pier,Vector3(20,0.25,5),timber,"LakeFishingPier")
	b.terrace(root,root,pier+Vector3(0,0.15,0),10,4,false)

func _waterfront() -> void:
	for x in range(-285,605,18):
		var z=Layout.river_north_bank(x)-5
		light_at(Vector3(x,0.15,z),x%3==0)
		palm(Vector3(x,0.1,z-11),rng.randf_range(9,12))
		box(Vector3(x,0.85,z+2),Vector3(0.1,1.5,0.1),metal,"PromenadeRailPost")
		for y in [0.4,1.2]: box(Vector3(x+8.5,y,z+2),Vector3(17,0.05,0.05),metal,"PromenadeRail")
	for x in range(-280,600,8):
		# Hanging vegetation breaks up the ten-metre wall, outside stairs and ramps.
		if absf(x+30)<7 or absf(x-150)<7 or absf(x-520)<7: continue
		if (x>=-255 and x<=-85) or (x>=295 and x<=465): continue
		var height=rng.randf_range(1.4,4.2)
		box(Vector3(x,10-height/2,645.4),Vector3(1.1,height,0.5),world.mats.leaf,"RetainingWallVines")
	# A moored electric river ferry, with a visible boarding pier.
	var ferry=Vector3(90,-0.7,Layout.river_north_bank(90)+28)
	box(ferry,Vector3(5,0.9,16),b.accents[0],"FerryHull")
	box(ferry+Vector3(0,1.5,0),Vector3(4,2.4,11),b.glass,"FerryCabin")
	b.solar(root,ferry+Vector3(0,2.9,0),4.3,12)
	for z in [-3,0,3]: box(ferry+Vector3(2.05,1.5,z),Vector3(0.06,1.3,1.6),amber,"emit_ferry_window")

func _district_groves() -> void:
	for p in [Vector2(14,82),Vector2(15,200),Vector2(94,69),Vector2(111,84),Vector2(187,83),
			Vector2(194,111),Vector2(116,184),Vector2(177,202),Vector2(194,187),Vector2(200,266),
			Vector2(44,340),Vector2(112,434),Vector2(146,413),Vector2(148,478),Vector2(149,522),
			Vector2(191,541),Vector2(223,535),Vector2(163,577),Vector2(257,579),
			Vector2(364,393),Vector2(407,394),Vector2(523,395),Vector2(550,400)]:
		if not Layout.channel_sample(p.x,p.y).is_empty(): continue
		var blocked=false
		for structure in world.get_node("PrototypeBuildings").get_children():
			var plot: Rect2=structure.get_meta("reserved_plot")
			if plot.has_point(p): blocked=true; break
		if not blocked: tree(at(p.x,p.y),rng.randf_range(7,11),rng.randf_range(3,4.1),rng.randf()<0.45)
	for p in [Vector2(39,-67),Vector2(84,-145),Vector2(92,-220),Vector2(82,-284),
			Vector2(-61,54),Vector2(-149,101),Vector2(-202,205),Vector2(-187,289),
			Vector2(-147,361),Vector2(-112,481),Vector2(-150,566)]:
		light_at(at(p.x,p.y),true)

func instances(title: String,mesh: Mesh,material: Material,values: Array,colours=false) -> void:
	var multimesh=MultiMesh.new()
	multimesh.transform_format=MultiMesh.TRANSFORM_3D
	multimesh.use_colors=colours
	multimesh.mesh=mesh
	multimesh.instance_count=values.size()
	for i in range(values.size()):
		multimesh.set_instance_transform(i,values[i].t if colours else values[i])
		if colours: multimesh.set_instance_color(i,values[i].colour)
	var node=MultiMeshInstance3D.new()
	node.name=title
	node.multimesh=multimesh
	node.material_override=material
	root.add_child(node)

func _flush_vegetation() -> void:
	var canopy=SphereMesh.new()
	canopy.radius=1
	canopy.height=2
	canopy.radial_segments=12
	canopy.rings=5
	var leaf=ShaderMaterial.new()
	leaf.shader=load("res://shaders/canopy_breeze.gdshader")
	instances("BroadleafForestCanopies",canopy,leaf,leaves,true)
	instances("FloweringTrees",canopy,leaf,flower_canopies,true)
	var trunk=CylinderMesh.new()
	trunk.top_radius=0.35
	trunk.bottom_radius=0.5
	trunk.height=1
	trunk.radial_segments=8
	instances("ForestTrunks",trunk,timber,trunks)
	instances("PalmTrunks",trunk,timber,palm_trunks)
	var blade=SurfaceTool.new()
	blade.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(5):
		var z=i*1.1
		var zz=(i+1)*1.1
		var width=0.8*sin(PI*(i+0.5)/5)
		var y=sin(PI*i/5)*0.9-i*0.15
		var yy=sin(PI*(i+1)/5)*0.9-(i+1)*0.15
		for p in [Vector3(-width,y,z),Vector3(width,y,z),Vector3(0,yy,zz),Vector3(width,y,z),Vector3(width,yy,zz),Vector3(0,yy,zz)]: blade.add_vertex(p)
	blade.generate_normals()
	var palm_leaf=world._mat("42724d")
	palm_leaf.cull_mode=BaseMaterial3D.CULL_DISABLED
	instances("TropicalPalmFronds",blade.commit(),palm_leaf,fronds)
