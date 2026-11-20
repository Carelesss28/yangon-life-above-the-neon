extends RefCounted
## Seaside town planting and street furniture: boulevard lamps, street trees, palms on the
## promenade, hill forest, park and campus trees, night-market stalls, courts and parked cars.
const Layout=preload("res://scripts/terrain_layout.gd")
const Roads=preload("res://scripts/road_layout.gd")
const Blocks=preload("res://scripts/reference_blocks.gd")
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
var tree_count=0
var counts_pocket={}

func setup(owner_world) -> void:
	world=owner_world
	root=Node3D.new()
	root.name="MasterplanDressing"
	world.add_child(root)
	rng.seed=2026111904
	b=load("res://scripts/reference_buildings.gd").new()
	b.world=world
	b.frame=world._mat("8b9a98")
	b.roof_material=world._mat("40545b")
	b.blue_roof=world._mat("385e76",0.35)
	b.glass=world._mat("31596b",0.28)
	b.facade=world._mat("d9d2c2")
	b.warm=world._mat("c8955e")
	b.window_light=world._mat("ffbe70",0.5,0.8)
	b.accents=[world._mat("4f9aa0"),world._mat("d08a5a"),world._mat("8a6fb5"),world._mat("6aa060")]
	metal=world._mat("3f555e",0.55)
	amber=world._mat("ffd197",0.4,2.2)
	timber=world._mat("876c4a")
	teal=world._mat("3d8189",0.65)
	_boulevards()
	_promenade_palms()
	_street_trees()
	_parks()
	_campus()
	_hill_forest()
	_night_market()
	_pocket_gardens()
	_cars()
	_flush_vegetation()
	root.set_meta("forest_trees",forest_count)
	root.set_meta("palms",palm_count)
	root.set_meta("parked_cars",parked_cars)
	print("MASTERPLAN_DRESSING_READY trees=",tree_count," forest=",forest_count," palms=",palm_count," parked_cars=",parked_cars," pocket=",counts_pocket)

func at(x: float,z: float,up=0.0) -> Vector3:
	return Vector3(x,Layout.height_at(x,z)+up,z)

func box(pos: Vector3,size: Vector3,mat: Material,title: String,solid=false) -> MeshInstance3D:
	return b.box(root,pos,size,mat,title,solid)

func free_spot(p: Vector2,radius: float) -> bool:
	if not Layout.in_world(p.x,p.y) or Layout.wet(p.x,p.y): return false
	if p.y<Layout.shore(p.x)+2.0: return false
	if not Layout.channel_sample(p.x,p.y).is_empty(): return false
	if not Roads.has_clearance(p,radius): return false
	for rect in world.grass_exclusions:
		if rect.has_point(p): return false
	for entry in world.building_plots:
		if Rect2(entry.plot).grow(radius+1.0).has_point(p): return false
	for route in world.grass_routes:
		if route.rect.has_point(p) and Layout.trail_distance(p,route.route)<radius+2.0: return false
	return true

func light_at(pos: Vector3,actual=false,towards=Vector3.FORWARD) -> void:
	if not world.dressing_clearance.reserve(Vector2(pos.x,pos.z),1.55,"lamp"): return
	box(pos+Vector3(0,2.9,0),Vector3(0.14,5.8,0.14),metal,"BoulevardLamp",true)
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
	if not world.dressing_clearance.reserve(Vector2(pos.x,pos.z),4.5,"tree"): return
	palm_trunks.append(Transform3D(Basis().scaled(Vector3(0.36,height,0.36)),pos+Vector3.UP*height/2))
	for i in range(7):
		var angle=TAU*i/7+rng.randf_range(-0.15,0.15)
		fronds.append(Transform3D(Basis(Vector3.UP,angle).scaled(Vector3.ONE*rng.randf_range(0.9,1.2)),pos+Vector3.UP*height))
	palm_count+=1

func tree(pos: Vector3,height: float,radius: float,flower=false) -> bool:
	# Species vary the crown: umbrella rain tree, dense round crown, tall narrow crown.
	if not world.dressing_clearance.reserve(Vector2(pos.x,pos.z),radius*1.2,"tree"): return false
	var species=rng.randi_range(0,2)
	var lean=Vector3(rng.randf_range(-0.12,0.12),0,rng.randf_range(-0.12,0.12))
	var trunk_height=height*(0.62 if species==0 else 0.55 if species==1 else 0.45)
	trunks.append(Transform3D(Basis().scaled(Vector3(0.6,trunk_height,0.6)),pos+Vector3.UP*trunk_height*0.5))
	var hue=rng.randf_range(0.2,0.33)
	var tint=Color.from_hsv(hue,rng.randf_range(0.5,0.7),rng.randf_range(0.55,0.75))
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
	tree_count+=1
	return true

func _boulevards() -> void:
	# Lamp posts on both sides of every town road; warm light pools alternate.
	for edge in Roads.EDGES:
		if Roads.is_mountain(edge): continue
		var a: Vector3=Roads.NODES[edge[0]]
		var end: Vector3=Roads.NODES[edge[1]]
		var length=Vector2(a.x-end.x,a.z-end.z).length()
		var side=Vector3(-(end-a).z,0,(end-a).x).normalized()
		var half=Roads.width(edge)/2
		var spacing=26.0
		for i in range(1,int(length/spacing)):
			var p: Vector3=Roads.point(a,end,float(i)/int(length/spacing))
			for sign_value in [-1,1]:
				var x=p+side*(half+0.9)*sign_value
				x.y=Layout.height_at(x.x,x.z)+0.14
				if x.z<Layout.shore(x.x)+1.0: continue
				light_at(x,(i+(1 if sign_value>0 else 0))%2==0,-side*sign_value)

func _promenade_palms() -> void:
	var x=14.0
	while x<Layout.WORLD.end.x-10.0:
		var z=Layout.shore(x)+9.0
		if Layout.harbour_weight(x)<0.3 and absf(x-535.21)>18 and Layout.channel_sample(x,z).is_empty():
			palm(Vector3(x,Layout.PROMENADE_Y,z),rng.randf_range(8,11))
			if int(x)%3==0: world._bench(x+5,z+1.5)
		x+=rng.randf_range(16,24)

func _street_trees() -> void:
	# Trees in the grass verges and block interiors, never on paths, roads, plots or canals.
	var x=10.0
	while x<Layout.WORLD.end.x-10.0:
		var z=Layout.shore(x)+28.0
		while z<990.0:
			var p=Vector2(x+rng.randf_range(-4,4),z+rng.randf_range(-4,4))
			if not Layout.HILLS.has_point(p) and free_spot(p,3.0):
				if rng.randf()<0.55: tree(at(p.x,p.y),rng.randf_range(6.5,9.5),rng.randf_range(2.6,3.6),rng.randf()<0.18)
			z+=17.0
		x+=17.0

func _parks() -> void:
	for entry in world.parks:
		var rect: Rect2=entry.rect
		var x=rect.position.x+5
		while x<rect.end.x-4:
			var z=rect.position.y+5
			while z<rect.end.y-4:
				var p=Vector2(x+rng.randf_range(-3,3),z+rng.randf_range(-3,3))
				if absf(p.x-rect.get_center().x)>5 and absf(p.y-rect.get_center().y)>5 and free_spot(p,2.5):
					tree(at(p.x,p.y),rng.randf_range(7,10),rng.randf_range(3,4),rng.randf()<0.35)
				z+=13.0
			x+=13.0
		var c=rect.get_center()
		for s in [-1,1]:
			world._bench(c.x+s*9,c.y+4)
			world._bench(c.x+4,c.y+s*9)

func _campus() -> void:
	# Tree-lined campus walks, plus a basketball court and a tennis court near the dorms.
	for z in range(590,910,16):
		for x in [647.89,759.15]:
			var p=Vector2(x+rng.randf_range(-1,1),z)
			if free_spot(p,2.5): tree(at(p.x,p.y),rng.randf_range(7,9),3.0,rng.randf()<0.25)
	for x in range(592,803,13):
		var p=Vector2(x,648+rng.randf_range(-1,1)-14)
		if free_spot(p,2.5): tree(at(p.x,p.y),rng.randf_range(7,9),3.0,rng.randf()<0.3)

func court(rect: Rect2,tennis: bool) -> void:
	var pos=at(rect.get_center().x,rect.get_center().y,0.06)
	box(pos,Vector3(rect.size.x,0.06,rect.size.y),world._mat("4f8f7a" if tennis else "c86b4a"),"Court")

func _hill_forest() -> void:
	# Dense, mixed forest on the hills and the edge ridges, thinned along the trail and around the
	# reservoir so the water and the lookout stay visible from the high camera.
	var areas=[Layout.HILLS,Rect2(0,245,33.8,330),Rect2(309.86,935,535.21,62),Rect2(970.42,245,28.17,690)]
	for area in areas:
		var x=area.position.x+4.0
		while x<area.end.x-2.0:
			var z=area.position.y+4.0
			while z<area.end.y-2.0:
				var p=Vector2(x+rng.randf_range(-4,4),z+rng.randf_range(-4,4))
				if Layout.ellipse(p.x,p.y,Layout.RESERVOIR)<1.45: z+=12.0; continue
				if Layout.trail_distance(p,Layout.HILL_TRAIL)<6.0: z+=12.0; continue
				var g=Roads.mountain_sample(p.x,p.y)
				if not g.is_empty() and g.distance<g.half+5.0: z+=12.0; continue
				if free_spot(p,2.0) and rng.randf()<0.8:
					if tree(at(p.x,p.y),rng.randf_range(9,15),rng.randf_range(3.5,5.5),rng.randf()<0.08): forest_count+=1
				z+=12.0
			x+=12.0

func _pocket_gardens() -> void:
	# Cozy density: every leftover lawn behind and between buildings becomes a small tropical garden
	# (rain trees, palms, flowering trees, a few benches). Stays 7 m clear of roads so pavements and
	# door approaches remain open; the hills, campus and motor district keep their own planting.
	var skip=[Layout.HILLS,Layout.CAMPUS,Layout.MOTOR.grow(6.0)]
	for key in Blocks.LANDMARKS: skip.append(Rect2(Blocks.LANDMARKS[key]).grow(6.0))
	var planted=0
	var benches=0
	var z=Layout.shore(0)+30.0
	while z<930.0:
		var x=12.0
		while x<988.0:
			var p=Vector2(x+rng.randf_range(-2.0,2.0),z+rng.randf_range(-2.0,2.0))
			x+=6.5
			var skipped=false
			for r in skip:
				if r.has_point(p): skipped=true
			if skipped or p.y<Layout.shore(p.x)+28.0: continue
			if not Roads.has_clearance(p,7.0) or not free_spot(p,2.5): continue
			var roll=rng.randf()
			if roll<0.16:
				palm(at(p.x,p.y),rng.randf_range(7.0,10.0))
			elif roll<0.97:
				if tree(at(p.x,p.y),rng.randf_range(5.5,8.5),rng.randf_range(2.4,3.4),rng.randf()<0.3): planted+=1
			elif benches<160 and world.dressing_clearance.reserve(p,1.5,"bench"):
				world._bench(p.x,p.y)
				benches+=1
		z+=6.5
	counts_pocket={"trees":planted,"benches":benches}

func _night_market() -> void:
	# A covered night-market street of stalls between the southern market blocks.
	var awnings: Array[Material]=[]
	for colour in ["cf657d","deab52","67bfa6","518ebf","b276b4"]:
		awnings.append(world._mat(colour,0.86))
	var z=868.0
	var x=316.9
	var i=0
	while x<563.38:
		var p2=Vector2(x,z)
		if free_spot(p2,3.2) or true:
			var p=at(x,z)
			if Roads.has_clearance(p2,4.0):
				var colour: Material=awnings[i%awnings.size()]
				var awning=box(p+Vector3(0,2.8,0),Vector3(5,0.17,5),colour,"MarketAwning")
				awning.rotation.x=0.075
				for side in [-1,1]: box(p+Vector3(side*2.2,1.4,-2.1),Vector3(0.11,2.8,0.11),metal,"StallFrame")
				box(p+Vector3(0,0.6,1.1),Vector3(3.6,1.2,1.0),timber,"ServingCounter",true)
				box(p+Vector3(0,2.52,1.4),Vector3(3.7,0.12,0.1),amber,"StallLight").add_to_group("city_lamp_emitters")
				for k in range(4): box(p+Vector3(-1.3+k*0.86,1.37,1.1),Vector3(0.6,0.3,0.55),awnings[(k+i)%awnings.size()],"MarketProduce")
				if i%3==0: light_at(p+Vector3(3.2,0,0),true)
		x+=8.0
		i+=1

func _cars() -> void:
	# Kerbside parking on the local east-west streets (never inside a junction).
	for entry in [Vector2(330.99,323.2),Vector2(394.37,403.2),Vector2(521.13,323.2),Vector2(605.63,403.2),Vector2(732.39,323.2),Vector2(211.27,403.2),Vector2(77.46,323.2),Vector2(464.79,683.2),Vector2(633.8,483.2),Vector2(781.69,483.2),Vector2(394.37,483.2),Vector2(535.21,803.2)]:
		var road=Roads.sample(entry.x,entry.y)
		if road.is_empty(): continue
		car(at(entry.x,entry.y),PI/2+rng.randf_range(-0.03,0.03))

func car(pos: Vector3,angle: float) -> void:
	var car_root=Node3D.new()
	car_root.name="ParkedElectricCar"
	car_root.position=pos
	car_root.rotation.y=angle
	root.add_child(car_root)
	var paint=b.accents[parked_cars%4]
	b.box(car_root,Vector3(0,0.7,0),Vector3(1.9,0.65,3.9),paint,"Body",true)
	b.box(car_root,Vector3(0,1.2,-0.15),Vector3(1.6,0.6,2.1),b.glass,"Cabin")
	for x in [-0.95,0.95]:
		for z in [-1.2,1.2]:
			var wheel=b.cylinder(car_root,Vector3(x,0.4,z),0.36,0.2,metal,"Wheel")
			wheel.rotation.z=PI/2
	for x in [-0.55,0.55]: b.box(car_root,Vector3(x,0.7,2),Vector3(0.4,0.16,0.1),amber,"emit_headlight")
	parked_cars+=1

func instances(title: String,mesh: Mesh,material: Material,values: Array,colours=false) -> void:
	# Godot culls each MultiMesh as a unit, so keep vegetation batches local.
	var tiles: Dictionary={}
	for value in values:
		var transform: Transform3D=value.t if colours else value
		var tile=Vector2i(floori(transform.origin.x/64.0),floori(transform.origin.z/64.0))
		if not tiles.has(tile): tiles[tile]=[]
		tiles[tile].append(value)
	for tile in tiles:
		var items: Array=tiles[tile]
		var multimesh=MultiMesh.new()
		multimesh.transform_format=MultiMesh.TRANSFORM_3D
		multimesh.use_colors=colours
		multimesh.mesh=mesh
		multimesh.instance_count=items.size()
		for i in range(items.size()):
			multimesh.set_instance_transform(i,items[i].t if colours else items[i])
			if colours: multimesh.set_instance_color(i,items[i].colour)
		var node=MultiMeshInstance3D.new()
		node.name="%s_%d_%d"%[title,tile.x,tile.y]
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
	instances("BroadleafCanopies",canopy,leaf,leaves,true)
	instances("FloweringTrees",canopy,leaf,flower_canopies,true)
	var trunk=CylinderMesh.new()
	trunk.top_radius=0.35
	trunk.bottom_radius=0.5
	trunk.height=1
	trunk.radial_segments=8
	instances("TreeTrunks",trunk,timber,trunks)
	instances("PalmTrunks",trunk,timber,palm_trunks)
	_trunk_bodies("TreeTrunkSolids",trunks,0.38)
	_trunk_bodies("PalmTrunkSolids",palm_trunks,0.25)
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
	var palm_leaf=world._mat("4f8a4f")
	palm_leaf.cull_mode=BaseMaterial3D.CULL_DISABLED
	instances("TropicalPalmFronds",blade.commit(),palm_leaf,fronds)


func _trunk_bodies(title: String,items: Array,radius: float) -> void:
	var body=StaticBody3D.new()
	body.name=title
	root.add_child(body)
	for t in items:
		var shape=CollisionShape3D.new()
		var cyl=CylinderShape3D.new()
		cyl.radius=radius
		cyl.height=maxf(t.basis.y.length(),1.0)
		shape.shape=cyl
		shape.position=t.origin
		body.add_child(shape)
