extends RefCounted
## Builds the seaside town: terrain, sea, roads and markings, sidewalks, promenade, harbour,
## canal walks and footbridges, parks, campus grounds and landmarks. Buildings are placed by
## reference_buildings.gd from reference_blocks.gd. All lighting is real time; nothing is baked.
const Layout=preload("res://scripts/terrain_layout.gd")
const Roads=preload("res://scripts/road_layout.gd")
const Blocks=preload("res://scripts/reference_blocks.gd")
var world
var root: Node3D
var batches: Dictionary={}     # material key -> {"material":Material,"items":[Transform3D]}
var counts={"chunks":0,"crosswalks":0,"poles":0,"bridges":0,"piers":0}
var pole_points: Array=[]

func setup(owner_world) -> void:
	world=owner_world
	root=Node3D.new()
	root.name="SeasideTown"
	world.add_child(root)

func build_before_buildings() -> void:
	_register_plots()
	_ground()
	_water_bodies()
	_world_edges()
	_roads()
	_promenade()
	_harbour()
	_canal_walks()
	_parks()
	_campus_grounds()
	_plot_aprons()
	_hill_trail()
	_outskirts()
	_flush()
	print("SEASIDE_GROUND_READY ",counts)

func build_after_buildings() -> void:
	_launch_bay()
	_ferris_wheel()
	_flush()

func build_late() -> void:
	# Needs the transport clearance map (rails, stations, stops), so it runs after those exist.
	_utility_poles()
	_flush()
	print("SEASIDE_TOWN_READY ",counts)

# ---------------------------------------------------------------- batching
func queue(key: String,material: Material,at: Vector3,size: Vector3,yaw: float=0.0,pitch: float=0.0) -> void:
	if not batches.has(key): batches[key]={"material":material,"items":[]}
	var basis=Basis(Vector3.UP,yaw)*Basis(Vector3.RIGHT,pitch)
	batches[key].items.append(Transform3D(basis.scaled(size),at))

func queue_segment(key: String,material: Material,a: Vector3,b: Vector3,thickness: float) -> void:
	var length=a.distance_to(b)
	if length<0.01: return
	var forward=(b-a)/length
	var up=Vector3.UP if absf(forward.dot(Vector3.UP))<0.98 else Vector3.RIGHT
	var basis=Basis.looking_at(forward,up)
	if not batches.has(key): batches[key]={"material":material,"items":[]}
	batches[key].items.append(Transform3D(Basis(basis.x*thickness,basis.y*thickness,basis.z*length),(a+b)*0.5))

func _flush() -> void:
	var mesh=BoxMesh.new()
	mesh.size=Vector3.ONE
	for key in batches:
		var entry=batches[key]
		if entry.items.is_empty(): continue
		var multi=MultiMesh.new()
		multi.transform_format=MultiMesh.TRANSFORM_3D
		multi.mesh=mesh
		multi.instance_count=entry.items.size()
		for i in range(entry.items.size()): multi.set_instance_transform(i,entry.items[i])
		var node=MultiMeshInstance3D.new()
		node.name="Batch_"+key
		node.multimesh=multi
		node.material_override=entry.material
		root.add_child(node)
		_collide(key,entry.items)
	batches.clear()

# Batched props that people must not walk through get matching collision boxes.
const SOLID_KEYS=["rail_post","canal_post","pole","guard_post","beach_pole","bollard","guard_tower","lookout_post","volley_post","lounger","pole_transformer"]
const RAIL_KEYS=["rail_top","canal_rail"]

func _collide(key: String,items: Array) -> void:
	var rail=key in RAIL_KEYS
	if not (rail or key in SOLID_KEYS or key.begins_with("container_")): return
	var body=StaticBody3D.new()
	body.name="Solid_"+key
	root.add_child(body)
	for t in items:
		var basis: Basis=t.basis
		var size=Vector3(basis.x.length(),basis.y.length(),basis.z.length())
		var origin: Vector3=t.origin
		if rail:
			# A thin hand-rail becomes a full-height barrier from the walkway up to the rail.
			size=Vector3(0.3,1.4,size.z+0.1)
			origin.y-=0.6
		var shape=CollisionShape3D.new()
		var box=BoxShape3D.new()
		box.size=Vector3(maxf(size.x,0.25),maxf(size.y,0.25),maxf(size.z,0.25))
		shape.shape=box
		shape.transform=Transform3D(basis.orthonormalized(),origin)
		body.add_child(shape)

func h(x: float,z: float) -> float:
	return Layout.height_at(x,z)

# ---------------------------------------------------------------- plan registration
func _register_plots() -> void:
	for list in [Blocks.CAMPUS,Blocks.TECH,Blocks.HOMES,Blocks.LAKE,Blocks.MARKET]:
		for entry in list: world.building_plots.append({"plot":entry[0],"label":entry[1]})
	for entry in Blocks.HALLS: world.building_plots.append({"plot":entry[0],"label":entry[1]})
	for entry in Blocks.PARKS: world.parks.append({"name":entry[0],"rect":entry[1]})
	world.parks.append({"name":"YUST CENTRAL QUAD","rect":Rect2(665.49,655,63.38,75)})

# ---------------------------------------------------------------- terrain and water
func _ground() -> void:
	var chunk=100.0
	for cx in range(ceili(Layout.WORLD.size.x/chunk)):
		for cz in range(ceili(Layout.WORLD.size.y/chunk)):
			var rect=Rect2(cx*chunk,cz*chunk,minf(chunk,Layout.WORLD.end.x-cx*chunk),minf(chunk,Layout.WORLD.end.y-cz*chunk))
			# Finer sampling where canals or the sea wall need crisp edges.
			var fine=false
			for route in Layout.WATER_ROUTES:
				for p in route.points:
					if rect.grow(6).has_point(Vector2(p.x,p.z)): fine=true
			var step=1.0 if fine else 2.0
			if rect.position.y<260 and rect.end.y>140: step=1.0
			# Fine chunks match coarse neighbours on their borders (no T-junction cracks).
			var edge_matched=func(x: float,z: float) -> float:
				var on_x=is_equal_approx(x,rect.position.x) or is_equal_approx(x,rect.end.x)
				var on_z=is_equal_approx(z,rect.position.y) or is_equal_approx(z,rect.end.y)
				if step<2.0 and on_z and fposmod(x,2.0)>0.5: return (Layout.height_at(x-1.0,z)+Layout.height_at(x+1.0,z))*0.5
				if step<2.0 and on_x and fposmod(z,2.0)>0.5: return (Layout.height_at(x,z-1.0)+Layout.height_at(x,z+1.0))*0.5
				return Layout.height_at(x,z)
			var node=world._surface(rect,world.mats.grass,"Ground_%d_%d"%[cx,cz],true,edge_matched,step)
			if node: counts.chunks+=1

func _water_bodies() -> void:
	var sea=PlaneMesh.new()
	sea.size=Vector2(5200,2700)
	sea.subdivide_width=40
	sea.subdivide_depth=24
	var node=world._mesh_node(sea,world.mats.water,"Sea")
	node.position=Vector3(422.54,Layout.SEA_Y,-1080)
	var reservoir=world._mesh_node(null,world.mats.water,"Reservoir")
	reservoir.position=Vector3(Layout.RESERVOIR.x,Layout.RESERVOIR_Y,Layout.RESERVOIR.y)
	reservoir.scale=Vector3(Layout.RESERVOIR.z*1.02,1,Layout.RESERVOIR.w*1.02)
	var pond=world._mesh_node(null,world.mats.water,"CampusPond")
	pond.position=Vector3(Layout.POND.x,Layout.POND_Y,Layout.POND.y)
	pond.scale=Vector3(Layout.POND.z*1.02,1,Layout.POND.w*1.02)
	# Reservoir dam and spillway lip on the north (downhill) side.
	var dam=Vector3(Layout.RESERVOIR.x-5,Layout.RESERVOIR_Y,Layout.RESERVOIR.y-Layout.RESERVOIR.w-1)
	world._box(dam+Vector3(0,0.6,0),Vector3(34,2.0,3.2),world.mats.concrete,"ReservoirDam",true)
	world._box(dam+Vector3(0,1.75,0),Vector3(34,0.3,3.6),world.mats.coping,"DamWalk")
	for side in [-1,1]: world._box(dam+Vector3(side*17,2.3,0),Vector3(0.5,1.2,3.6),world.mats.hazard,"DamPier")

func _world_edges() -> void:
	# Invisible limits: map border and a line in the shallows so nobody walks off the shelf.
	var r=Layout.WORLD
	for wall in [[Vector3(r.get_center().x,20,r.position.y-1),Vector3(r.size.x,80,2)],[Vector3(r.get_center().x,20,r.end.y+1),Vector3(r.size.x,80,2)],
			[Vector3(r.position.x-1,20,r.get_center().y),Vector3(2,80,r.size.y)],[Vector3(r.end.x+1,20,r.get_center().y),Vector3(2,80,r.size.y)]]:
		world._box(wall[0],wall[1],world.mats.metal,"WorldEdge",true).visible=false
	var x=0.0
	while x<Layout.WORLD.end.x:
		var z=Layout.shore(x+6)-26
		if Layout.harbour_weight(x+6)>0.5: z=Layout.shore(x+6)-2.5
		var wall=world._box(Vector3(x+6,-1.0,z),Vector3(12.5,4.0,1.0),world.mats.metal,"ShallowsLimit",true)
		wall.visible=false
		x+=12.0

# ---------------------------------------------------------------- roads
func _edge_dirs() -> Dictionary:
	var dirs={}
	for edge in Roads.EDGES:
		for i in [0,1]:
			var key: String=edge[i]
			if not dirs.has(key): dirs[key]=[]
			dirs[key].append({"other":edge[1-i],"width":Roads.width(edge)})
	return dirs

func _roads() -> void:
	var dirs=_edge_dirs()
	var paint=world.mats.paint
	for edge in Roads.EDGES:
		var a: Vector3=Roads.NODES[edge[0]]
		var b: Vector3=Roads.NODES[edge[1]]
		var width=Roads.width(edge)
		var mountain=Roads.is_mountain(edge)
		var flat=Vector2(b.x-a.x,b.z-a.z)
		var length=flat.length()
		var count=ceili(length/2)
		var side=Vector3(-flat.y,0,flat.x).normalized()
		var yaw=atan2(flat.x,flat.y)
		var st=SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var trim_a=_junction_half(dirs,edge[0])+1.5
		var trim_b=_junction_half(dirs,edge[1])+1.5
		for i in range(count):
			var t0=float(i)/count
			var t1=float(i+1)/count
			var p=Roads.point(a,b,t0,mountain)+Vector3.UP*0.12
			var q=Roads.point(a,b,t1,mountain)+Vector3.UP*0.12
			var vertices=[p-side*width*0.5,p+side*width*0.5,q-side*width*0.5,q+side*width*0.5]
			for j in [0,2,1,1,2,3]: st.add_vertex(vertices[j])
			var along=t0*length
			if along<trim_a or along>length-trim_b: continue
			var mid=(p+q)*0.5+Vector3.UP*0.02
			# CityRT-style markings: dashed centre, solid edge lines on wider roads.
			if i%3==0: queue("road_paint",paint,mid,Vector3(0.18,0.02,1.6),yaw)
			if width>=10.0:
				for s in [-1,1]: queue("road_paint",paint,mid+side*s*(width*0.5-0.5),Vector3(0.14,0.02,2.02),yaw)
			if width>=15.0 and i%3==0:
				for s in [-1,1]: queue("road_paint",paint,mid+side*s*width*0.25,Vector3(0.14,0.02,1.2),yaw)
		st.generate_normals()
		world._mesh_node(st.commit(),world.mats.road,"MountainRoad" if mountain else "Road",true)
		world.grass_exclusions.append(Rect2(Vector2(a.x,a.z),Vector2.ZERO).expand(Vector2(b.x,b.z)).grow(width*0.5+0.3) if not mountain else Rect2(Vector2(a.x,a.z),Vector2.ONE*0.1))
		if not mountain: _sidewalks(a,b,width,trim_a,trim_b)
		else: _mountain_rails(a,b,width,side,length)
	for key in Roads.NODES:
		var p: Vector3=Roads.NODES[key]
		var half=_junction_half(dirs,key)
		var node=world._box(p+Vector3.UP*0.02,Vector3(half*2,0.22,half*2),world.mats.road,"RoadJunction",true)
		if key in Roads.MOUNTAIN_NODES: node.visible=true
		if dirs[key].size()>=3 and key not in Roads.MOUNTAIN_NODES: _crosswalks(key,dirs[key],half)

func _junction_half(dirs: Dictionary,key: String) -> float:
	var half=4.0
	for entry in dirs.get(key,[]): half=maxf(half,entry.width*0.5)
	return half

func _sidewalks(a: Vector3,b: Vector3,width: float,trim_a: float,trim_b: float) -> void:
	var horizontal=absf(b.z-a.z)<0.5
	var lo=minf(a.x,b.x) if horizontal else minf(a.z,b.z)
	var hi=maxf(a.x,b.x) if horizontal else maxf(a.z,b.z)
	var start_trim=trim_a if (a.x<b.x if horizontal else a.z<b.z) else trim_b
	var end_trim=trim_b if (a.x<b.x if horizontal else a.z<b.z) else trim_a
	lo+=start_trim-1.0
	hi-=end_trim-1.0
	if hi-lo<4: return
	var walk=3.6
	for s in [-1,1]:
		var offset=width*0.5+0.2
		var rect: Rect2
		if horizontal:
			var z=a.z+s*(offset+walk*0.5)
			rect=Rect2(lo,z-walk*0.5,hi-lo,walk)
		else:
			var x=a.x+s*(offset+walk*0.5)
			rect=Rect2(x-walk*0.5,lo,walk,hi-lo)
		# Sidewalks stop at the sea wall and never pave over open canals.
		world._surface(rect,world.mats.paving,"Sidewalk",false,func(x: float,z: float)->float: return Layout.height_at(x,z)+0.14,2.0,true)
		var curb_at=Vector3(rect.get_center().x,0,rect.get_center().y)
		if horizontal:
			var cz=a.z+s*(width*0.5+0.12)
			var steps=int((hi-lo)/4.0)
			for i in range(steps):
				var x=lo+(i+0.5)*(hi-lo)/steps
				queue("curb",world.mats.curb,Vector3(x,h(x,cz)+0.12,cz),Vector3((hi-lo)/steps+0.05,0.26,0.24))
		else:
			var cx=a.x+s*(width*0.5+0.12)
			var steps=int((hi-lo)/4.0)
			for i in range(steps):
				var z=lo+(i+0.5)*(hi-lo)/steps
				queue("curb",world.mats.curb,Vector3(cx,h(cx,z)+0.12,z),Vector3(0.24,0.26,(hi-lo)/steps+0.05))
		if width<=10.0 and s==1:
			# Concrete utility poles follow the local streets (power lines strung after buildings).
			var spacing=32.0
			var n=int((hi-lo)/spacing)
			for i in range(n+1):
				var u=lo+i*(hi-lo)/maxf(n,1)
				var p=Vector3(u,0,a.z+(width*0.5+walk+0.6)) if horizontal else Vector3(a.x+(width*0.5+walk+0.6),0,u)
				pole_points.append({"p":p,"line":str(a)+str(b)})

func _crosswalks(key: String,entries: Array,half: float) -> void:
	var p: Vector3=Roads.NODES[key]
	for entry in entries:
		var o: Vector3=Roads.NODES[entry.other]
		var dir=Vector2(o.x-p.x,o.z-p.z).normalized()
		var across=Vector2(-dir.y,dir.x)
		var centre=Vector2(p.x,p.z)+dir*(half+1.8)
		var w: float=entry.width
		var stripes=int(w/1.1)
		for i in range(stripes):
			var c=centre+across*(-w*0.5+0.6+i*(w-1.2)/maxf(stripes-1,1))
			queue("crosswalk",world.mats.paint,Vector3(c.x,h(c.x,c.y)+0.15,c.y),Vector3(0.55,0.02,2.8),atan2(dir.x,dir.y))
		counts.crosswalks+=1

func _mountain_rails(a: Vector3,b: Vector3,width: float,side: Vector3,length: float) -> void:
	var count=int(length/6)
	for i in range(1,count):
		var p=Roads.point(a,b,float(i)/count,true)
		for s in [-1,1]:
			var at=p+side*s*(width*0.5+0.5)
			queue("guard_post",world.mats.coping,at+Vector3.UP*0.45,Vector3(0.16,0.9,0.16))
			if i%2==0: queue("guard_reflector",world.mats.hazard,at+Vector3.UP*0.82,Vector3(0.18,0.1,0.18))

# ---------------------------------------------------------------- seafront
func _promenade() -> void:
	# Paved promenade ribbon from the sea wall to the boulevard sidewalk, with a railing and lamps.
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wall=SurfaceTool.new()
	wall.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step=3.0
	var x=0.0
	var inner_z=235.0-8.0-3.8
	while x<Layout.WORLD.end.x:
		var xx=minf(x+step,Layout.WORLD.end.x)
		var s0=Layout.shore(x)+0.15
		var s1=Layout.shore(xx)+0.15
		var y=Layout.PROMENADE_Y+0.06
		var v=[Vector3(x,y,s0),Vector3(xx,y,s1),Vector3(x,y,inner_z),Vector3(xx,y,inner_z)]
		for j in [0,1,2,1,3,2]:
			st.set_uv(Vector2(v[j].x,v[j].z)/4.0)
			st.add_vertex(v[j])
		var low=-2.2 if Layout.harbour_weight(x)>0.5 else 0.2
		var w=[Vector3(x,low,s0-0.05),Vector3(xx,low,s1-0.05),Vector3(x,y,s0-0.05),Vector3(xx,y,s1-0.05)]
		for j in [0,1,2,1,3,2]: wall.add_vertex(w[j])
		world.grass_exclusions.append(Rect2(x,s0-1,step,inner_z-s0+1))
		# Sea wall railing, broken by beach stairs every 150 m outside the harbour.
		var stair_gap=int(x)%150<6 and Layout.harbour_weight(x)<0.2
		if not stair_gap:
			queue_segment("rail_top",world.mats.coping,Vector3(x,y+1.0,s0+0.25),Vector3(xx,y+1.0,s1+0.25),0.09)
			queue("rail_post",world.mats.metal,Vector3(x,y+0.5,s0+0.25),Vector3(0.08,1.0,0.08))
		elif int(x)%150<3:
			_beach_stairs(x+3,Layout.shore(x+3))
		x=xx
	st.generate_normals()
	world._mesh_node(st.commit(),world.mats.paving,"SeafrontPromenade",true)
	wall.generate_normals()
	var face=world.mats.concrete.duplicate()
	face.cull_mode=BaseMaterial3D.CULL_DISABLED
	world._mesh_node(wall.commit(),face,"SeaWall",true)
	_beach()

func _beach_stairs(x: float,s: float) -> void:
	for i in range(8):
		var y=Layout.PROMENADE_Y-i*0.3
		world._box(Vector3(x,y-0.15,s-0.4-i*0.42),Vector3(4.6,0.3,0.44),world.mats.concrete,"BeachStair",true)

func _beach() -> void:
	var umbrella_mats=[world._mat("e2574c"),world._mat("f2c94c"),world._mat("4fa3c7"),world._mat("ef8fb0")]
	var x=40.0
	var i=0
	while x<591.55:
		var z=Layout.shore(x)-rng_range(i,10.0,18.0)
		var y=h(x,z)
		if y>-0.6:
			var pole=Vector3(x,y,z)
			queue("beach_pole",world.mats.coping,pole+Vector3.UP*1.2,Vector3(0.07,2.4,0.07))
			var top=world._cylinder(pole+Vector3.UP*2.4,1.5,0.12,umbrella_mats[i%4],"BeachUmbrella")
			top.mesh.top_radius=0.12
			for s in [-1,1]: queue("lounger",world.mats.coping,pole+Vector3(s*1.1,0.25,0.8),Vector3(0.65,0.12,1.8),0.0,-0.1)
			if i%2==0: world.activity_spots.append({"pos":pole+Vector3(0,0,2.0),"title":"BEACH"})
		x+=rng_range(i,22.0,46.0)
		i+=1
	# Lifeguard tower and a volleyball court on the widest stretch.
	var lx=366.2
	var lz=Layout.shore(lx)-14
	var base=Vector3(lx,h(lx,lz),lz)
	for c in [Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]:
		queue("guard_tower",world.mats.coping,base+Vector3(c.x*0.9,1.6,c.y*0.9),Vector3(0.14,3.2,0.14))
	world._box(base+Vector3(0,3.4,0),Vector3(2.4,0.2,2.4),world.mats.wood,"LifeguardDeck")
	world._box(base+Vector3(0,4.4,0),Vector3(2.0,1.6,2.0),world._mat("e2574c"),"LifeguardHut")
	var vx=232.39
	var vz=Layout.shore(vx)-15
	for s in [-1,1]: queue("volley_post",world.mats.metal,Vector3(vx+s*4.5,h(vx,vz)+1.2,vz),Vector3(0.1,2.4,0.1))
	world._box(Vector3(vx,h(vx,vz)+2.1,vz),Vector3(9,0.7,0.04),world.mats.coping,"VolleyNet")

func rng_range(i: int,a: float,b: float) -> float:
	return a+(b-a)*fposmod(sin(i*12.9898)*43758.5453,1.0)

# ---------------------------------------------------------------- harbour
func _harbour() -> void:
	var deck_y=Layout.PROMENADE_Y
	var container_mats=[world._mat("c8473d"),world._mat("3d7fd6"),world._mat("e2a33d"),world._mat("3fae6a"),world._mat("8a6fb5")]
	for px in [633.8,686.62,739.44]:
		var s=Layout.shore(px)
		var length=115.0
		var width=14.0
		var pier=world._box(Vector3(px,deck_y-0.3,s-length/2+1),Vector3(width,0.6,length),world.mats.concrete,"HarbourPier",true)
		world.grass_exclusions.append(Rect2(px-width/2,s-length,width,length))
		for side in [-1,1]:
			world._box(Vector3(px+side*(width/2+0.1),deck_y+0.7,s-length/2+1),Vector3(0.3,1.4,length),world.mats.metal,"PierEdgeBarrier",true).visible=false
		world._box(Vector3(px,deck_y+0.7,s-length+1.0),Vector3(width,1.4,0.3),world.mats.metal,"PierEdgeBarrier",true).visible=false
		for i in range(int(length/10)+1):
			for side in [-1,1]:
				queue("pier_pile",world.mats.hazard_dark,Vector3(px+side*(width/2-0.6),deck_y-3.5,s-i*10),Vector3(0.7,6.0,0.7))
				if i%2==0: queue("bollard",world.mats.hazard,Vector3(px+side*(width/2-0.5),deck_y+0.3,s-i*10-5),Vector3(0.4,0.6,0.4))
		# Hazard-striped quay edge.
		for i in range(int(length/2)):
			var z=s-1-i*2
			for side in [-1,1]:
				queue("quay_stripe_a" if i%2==0 else "quay_stripe_b",world.mats.hazard if i%2==0 else world.mats.hazard_dark,Vector3(px+side*(width/2-0.15),deck_y+0.04,z),Vector3(0.3,0.06,2.0))
		counts.piers+=1
		if px==686.62:
			# Container stacks and a gantry crane.
			for i in range(5):
				for j in range(1+i%3):
					queue("container_%d"%((i+j)%5),container_mats[(i+j)%5],Vector3(px-3.2,deck_y+1.3+j*2.6,s-20-i*7),Vector3(2.5,2.6,6.1))
			_crane(Vector3(px+2,deck_y,s-62))
			world.activity_spots.append({"pos":Vector3(px+4.5,deck_y,s-56),"title":"HARBOUR CRANE"})
		if px==739.44:
			_ferry_terminal(Vector3(px,deck_y,s-length+12))
		if px==633.8:
			_boat(Vector3(px-14,Layout.SEA_Y,s-40),0.0,world._mat("e8e2d4"))
			world.activity_spots.append({"pos":Vector3(px,deck_y,s-108),"title":"PIER END"})
			_boat(Vector3(px+14,Layout.SEA_Y,s-75),0.0,world._mat("4fa3c7"))
	_boat(Vector3(714.79,Layout.SEA_Y,Layout.shore(714.79)-60),0.0,world._mat("e2574c"))
	_breakwater()

func _crane(base: Vector3) -> void:
	var crane=Node3D.new()
	crane.name="HarbourGantryCrane"
	crane.position=base
	root.add_child(crane)
	for c in [Vector2(-4,-3),Vector2(4,-3),Vector2(-4,3),Vector2(4,3)]:
		world._box(Vector3(base.x+c.x,base.y+9,base.z+c.y),Vector3(0.7,18,0.7),world.mats.hazard,"CraneLeg")
	world._box(base+Vector3(0,18.4,0),Vector3(10,1.2,7),world.mats.hazard,"CraneBridge")
	world._box(base+Vector3(-14,18.8,0),Vector3(30,0.9,2.2),world.mats.hazard,"CraneBoom")
	world._box(base+Vector3(2,20.3,0),Vector3(4,2.2,3),world.mats.hazard_dark,"CraneCab")
	for i in range(8): queue("crane_stripe",world.mats.hazard_dark,base+Vector3(-26+i*3.5,18.8,1.12),Vector3(1.6,0.92,0.04))
	world._box(base+Vector3(-24,12,0),Vector3(0.08,13,0.08),world.mats.metal,"CraneCable")
	world._box(base+Vector3(-24,5.4,0),Vector3(2.6,0.6,6.2),world.mats.hazard_dark,"Spreader")

func _ferry_terminal(at: Vector3) -> void:
	var b=world._box(at+Vector3(0,3.2,0),Vector3(12,6,18),world._mat("e4ece9",0.4),"FerryTerminalHall",true)
	world._box(at+Vector3(0,6.5,0),Vector3(13.5,0.6,19.5),world.mats.hazard_dark,"FerryRoof")
	world._box(at+Vector3(0,3.0,9.05),Vector3(9,3.6,0.12),world._mat("2a4f65",0.25),"FerryGlass")
	var label=Label3D.new()
	label.text="FERRY  ·  ဆိပ်ကမ်း"
	label.font_size=72
	label.pixel_size=0.02
	label.position=at+Vector3(0,7.6,9.0)
	label.modulate=Color("ffe2a8")
	label.shaded=false
	root.add_child(label)
	_boat(at+Vector3(-12,Layout.SEA_Y-at.y,-4),0.0,world._mat("f2f0e8"),2.2)
	world.activity_spots.append({"pos":at+Vector3(0,0,10.5),"title":"FERRY TERMINAL"})

func _boat(at: Vector3,yaw: float,paint: Material,scale_value: float=1.0) -> void:
	var boat=Node3D.new()
	boat.name="MooredBoat"
	boat.position=at
	boat.rotation.y=yaw
	boat.scale=Vector3.ONE*scale_value
	root.add_child(boat)
	var hull=MeshInstance3D.new()
	var mesh=BoxMesh.new()
	mesh.size=Vector3(3.2,1.2,9)
	hull.mesh=mesh
	hull.material_override=paint
	hull.position=Vector3(0,0.3,0)
	boat.add_child(hull)
	var cabin=MeshInstance3D.new()
	var cm=BoxMesh.new()
	cm.size=Vector3(2.2,1.4,3)
	cabin.mesh=cm
	cabin.material_override=world.mats.coping
	cabin.position=Vector3(0,1.6,0.8)
	boat.add_child(cabin)

func _breakwater() -> void:
	var points=[Vector2(823.94,Layout.shore(823.94)-4),Vector2(809.86,110),Vector2(760.56,70),Vector2(676.06,52),Vector2(637.32,60)]
	var i=0
	for k in range(points.size()-1):
		var a: Vector2=points[k]
		var b: Vector2=points[k+1]
		var n=int(a.distance_to(b)/4.5)
		for j in range(n):
			var p=a.lerp(b,float(j)/n)
			var size=Vector3(rng_range(i,3.5,5.5),rng_range(i+7,2.6,4.2),rng_range(i+3,3.5,5.5))
			queue("breakwater_rock",world.mats.rock,Vector3(p.x,Layout.SEA_Y+0.2,p.y),size,rng_range(i+11,0,TAU))
			i+=1
	# Lighthouse at the breakwater head, with a sweeping beam.
	var base=Vector3(637.32,Layout.SEA_Y+1.4,60)
	world._cylinder(base+Vector3(0,0.6,0),5.0,1.6,world.mats.concrete,"LighthousePlinth")
	for j in range(6):
		var band=world._cylinder(base+Vector3(0,2.5+j*2.6,0),1.9-j*0.12,2.6,world._mat("f2efe6" if j%2==0 else "d8453f"),"LighthouseBand")
	world._cylinder(base+Vector3(0,18.6,0),1.5,2.2,world._mat("ffe9a8",0.3,3.0),"LighthouseLantern")
	world._cylinder(base+Vector3(0,20.0,0),1.8,0.6,world.mats.hazard_dark,"LighthouseCap")
	var spinner=Node3D.new()
	spinner.set_script(load("res://scripts/spin.gd"))
	spinner.speed=0.9
	spinner.position=base+Vector3(0,18.6,0)
	root.add_child(spinner)
	var beam=SpotLight3D.new()
	beam.light_color=Color("ffe7a0")
	beam.spot_range=180
	beam.spot_angle=9
	beam.light_energy=0.0
	beam.set_meta("night_energy",8.0)
	beam.rotation_degrees=Vector3(-6,0,0)
	beam.shadow_enabled=false
	spinner.add_child(beam)
	world.lamps.append(beam)

# ---------------------------------------------------------------- canals
func _canal_walks() -> void:
	# Paved canal-side walks with railings; they never pave the water or cross roads.
	for route in Layout.WATER_ROUTES:
		var pts: Array=route.points
		for k in range(pts.size()-1):
			var a: Vector3=pts[k]
			var b: Vector3=pts[k+1]
			var flat=Vector2(b.x-a.x,b.z-a.z)
			var length=flat.length()
			if length<4: continue
			var axis_x=absf(flat.x)<0.5
			var axis_z=absf(flat.y)<0.5
			var side=Vector2(-flat.y,flat.x).normalized()
			var n=int(length/2.5)
			for j in range(n):
				var c=Vector2(a.x,a.z).lerp(Vector2(b.x,b.z),(j+0.5)/n)
				if not Roads.sample(c.x,c.y).is_empty(): continue
				if not Roads.has_clearance(c,route.width*0.5+5.0): continue
				var water_y=lerpf(a.y,b.y,(j+0.5)/n)
				if Layout.trail_distance(c,Layout.HILL_TRAIL)<5.0: continue   # trail footbridge here
				for s in [-1,1]:
					var e=c+side*s*(route.width*0.5+0.35)
					var top=h(e.x,e.y)
					if top-water_y>2.3: continue
					queue_segment("canal_rail",world.mats.metal,Vector3(e.x,top+0.95,e.y)-Vector3(flat.x,0,flat.y).normalized()*1.25,Vector3(e.x,top+0.95,e.y)+Vector3(flat.x,0,flat.y).normalized()*1.25,0.06)
					if j%2==0: queue("canal_post",world.mats.metal,Vector3(e.x,top+0.48,e.y),Vector3(0.07,0.95,0.07))
			if axis_x or axis_z:
				for s in [-1,1]:
					var off=route.width*0.5+0.6
					var rect: Rect2
					if axis_x:
						rect=Rect2(a.x+s*(off+1.6)-1.6,minf(a.z,b.z),3.2,absf(b.z-a.z))
					else:
						rect=Rect2(minf(a.x,b.x),a.z+s*(off+1.6)-1.6,absf(b.x-a.x),3.2)
					_paved_clear(rect,"CanalWalk")
	_trail_bridges()
	# Footbridges across the canals mid-block (arched decks with rails).
	for spot in [[Vector2(429.58,360),true],[Vector2(429.58,440),true],[Vector2(105.63,360),true],[Vector2(105.63,440),true],
			[Vector2(760.56,360),true],[Vector2(760.56,440),true],[Vector2(232.39,540),false],[Vector2(338.03,540),false],[Vector2(105.63,280),true],[Vector2(429.58,280),true]]:
		_footbridge(spot[0],spot[1])

func _paved_clear(rect: Rect2,title: String) -> void:
	# Pave in short pieces, skipping any piece that would cover a road.
	var long_x=rect.size.x>rect.size.y
	var length=rect.size.x if long_x else rect.size.y
	var n=maxi(1,int(length/10.0))
	world.paved_areas.append([rect,title])
	for i in range(n):
		var piece: Rect2
		if long_x: piece=Rect2(rect.position.x+i*length/n,rect.position.y,length/n,rect.size.y)
		else: piece=Rect2(rect.position.x,rect.position.y+i*length/n,rect.size.x,length/n)
		var c=piece.get_center()
		if not Roads.has_clearance(c,minf(piece.size.x,piece.size.y)*0.5): continue
		if c.y<Layout.shore(c.x)+2: continue
		world._surface(piece,world.mats.paving,title,false,func(x: float,z: float)->float: return Layout.height_at(x,z)+0.06,2.0,true)

func _footbridge(c: Vector2,east_west: bool) -> void:
	var span=10.0
	var width=3.4
	var y0=h(c.x+(span*0.5+1.5 if east_west else 0),c.y+(0.0 if east_west else span*0.5+1.5))
	var y1=h(c.x-(span*0.5+1.5 if east_west else 0),c.y-(0.0 if east_west else span*0.5+1.5))
	var y=minf(y0,y1)
	var bridge=Node3D.new()
	bridge.name="CanalFootbridge"
	bridge.position=Vector3(c.x,y,c.y)
	if not east_west: bridge.rotation.y=PI/2
	root.add_child(bridge)
	var pieces=8
	for i in range(pieces):
		var u=(i+0.5)/pieces-0.5
		var lift=0.9*(1.0-4.0*u*u)
		var deck=MeshInstance3D.new()
		var mesh=BoxMesh.new()
		mesh.size=Vector3(span/pieces+0.08,0.25,width)
		deck.mesh=mesh
		deck.material_override=world.mats.wood
		deck.position=Vector3(u*span,lift+0.05,0)
		deck.rotation.z=-atan(8.0*u*0.9/span)
		bridge.add_child(deck)
		for s in [-1,1]:
			var post=MeshInstance3D.new()
			var pm=BoxMesh.new()
			pm.size=Vector3(0.1,1.0,0.1)
			post.mesh=pm
			post.material_override=world.mats.metal
			post.position=Vector3(u*span,lift+0.6,s*(width*0.5-0.1))
			bridge.add_child(post)
	# Arched walking surface: a convex hull that meets the ground at both ends (no step up).
	var body=StaticBody3D.new()
	var shape=CollisionShape3D.new()
	var hull=ConvexPolygonShape3D.new()
	var points=PackedVector3Array()
	for k in range(11):
		var u=float(k)/10.0-0.5
		var x=u*(span+3.0)
		var top=1.05*maxf(0.0,1.0-4.0*(x/(span+3.0))*(x/(span+3.0)))-0.06
		for zz in [-width*0.5,width*0.5]:
			points.append(Vector3(x,top,zz))
			points.append(Vector3(x,-0.6,zz))
	hull.points=points
	shape.shape=hull
	body.add_child(shape)
	bridge.add_child(body)
	var rect=Rect2(c.x-(span*0.5+1.5),c.y-width*0.5,span+3.0,width) if east_west else Rect2(c.x-width*0.5,c.y-(span*0.5+1.5),width,span+3.0)
	world.model_bridge_spans.append(rect.grow(0.4))
	counts.bridges+=1

# ---------------------------------------------------------------- parks and grounds
func _parks() -> void:
	for entry in world.parks:
		var rect: Rect2=entry.rect
		var c=rect.get_center()
		# Cross paths and a ring walk; the rest stays lawn and planting (dressing adds trees).
		_paved_clear(Rect2(rect.position.x,c.y-2,rect.size.x,4),"ParkPath")
		_paved_clear(Rect2(c.x-2,rect.position.y,4,rect.size.y),"ParkPath")
		if "BOTANICAL" in entry.name:
			# Flower beds and a glass greenhouse dome.
			var bed_mats=[world._mat("e86a8a"),world._mat("f2c94c"),world._mat("b07ad8"),world._mat("ff8a4a")]
			for i in range(10):
				var p=rect.position+Vector2(10+(i%5)*(rect.size.x-20)/4.0,12+(i/5)*(rect.size.y-24))
				world._box(Vector3(p.x,h(p.x,p.y)+0.2,p.y),Vector3(7,0.4,3.2),world.mats.dark_wood,"FlowerBedEdge")
				world._box(Vector3(p.x,h(p.x,p.y)+0.5,p.y),Vector3(6.4,0.35,2.6),bed_mats[i%4],"FlowerBed")
			var dome=MeshInstance3D.new()
			var sphere=SphereMesh.new()
			sphere.radius=9
			sphere.height=11
			sphere.is_hemisphere=true
			dome.mesh=sphere
			var glass=world._mat("bfe8e0",0.15)
			glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
			glass.albedo_color.a=0.45
			dome.material_override=glass
			dome.name="Greenhouse"
			var gp=Vector2(rect.end.x-16,rect.position.y+16)
			dome.position=Vector3(gp.x,h(gp.x,gp.y),gp.y)
			root.add_child(dome)
			world._label(entry.name,Vector3(c.x,h(c.x,c.y)+4,c.y))

func _campus_grounds() -> void:
	var campus: Rect2=Layout.CAMPUS
	# Main gate plaza, the central quad and walks linking every building.
	_paved_clear(Rect2(583.1,640,226.76,12),"CampusWalk")
	_paved_clear(Rect2(642.25,568,7.04,345),"CampusWalk")
	_paved_clear(Rect2(762.68,650,5.63,265),"CampusWalk")
	_paved_clear(Rect2(583.1,818,226.76,10),"CampusWalk")
	_paved_clear(Rect2(665.49,655,63.38,4),"CampusWalk")
	_paved_clear(Rect2(665.49,726,63.38,4),"CampusWalk")
	# Gate: two pylons with a hazard-striped beam and the YUST name.
	var g=Vector3(581.69,h(581.69,600),600)
	for s in [-1,1]:
		world._box(g+Vector3(0,4,s*7),Vector3(2,8,2),world._mat("3b2f5a"),"GatePylon",true)
		world._box(g+Vector3(0.9,4,s*7),Vector3(0.12,7.2,0.5),world._mat("b07dff",0.4,3.0),"GateNeon")
	world._box(g+Vector3(0,8.4,0),Vector3(2.2,1.2,16),world.mats.hazard_dark,"GateBeam")
	for i in range(8): queue("gate_stripe",world.mats.hazard,g+Vector3(1.12,8.4,-7+i*2),Vector3(0.04,1.0,1.0))
	var label=Label3D.new()
	label.text="YUST  ·  YANGON UNIVERSITY OF SCIENCE & TECHNOLOGY"
	label.font_size=56
	label.pixel_size=0.016
	label.position=g+Vector3(1.4,9.6,0)
	label.rotation_degrees.y=90
	label.modulate=Color("e9d6ff")
	label.shaded=false
	root.add_child(label)
	# Training ground: running track ring and target frames.
	var t: Rect2=Blocks.LANDMARKS.training_ground
	world._surface(t,world._mat("c86b4a",0.95),"TrainingTrack",false,func(x: float,z: float)->float: return Layout.height_at(x,z)+0.05,2.0)
	world._surface(t.grow(-6),world._mat("5aa055"),"TrainingField",false,func(x: float,z: float)->float: return Layout.height_at(x,z)+0.07,2.0)
	for i in range(4):
		var p=Vector2(t.position.x+12+i*18,t.get_center().y)
		world._box(Vector3(p.x,h(p.x,p.y)+2.2,p.y),Vector3(0.3,4.4,3.2),world.mats.hazard,"TrainingTargetFrame")

func _plot_aprons() -> void:
	# Each building gets a paved forecourt toward its south (front) street or plaza.
	for entry in world.building_plots:
		var p: Rect2=entry.plot
		var apron=Rect2(p.position.x-1.0,p.end.y-5.5,p.size.x+2.0,10.5)
		_paved_clear(apron,"Forecourt")

func _hill_trail() -> void:
	var route: Array=Layout.HILL_TRAIL
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dirt=world._mat("a98a62",0.95)
	for k in range(route.size()-1):
		var a: Vector2=route[k]
		var b: Vector2=route[k+1]
		var n=int(a.distance_to(b)/2.0)
		var side=Vector2(-(b-a).y,(b-a).x).normalized()*1.4
		for j in range(n):
			var p=a.lerp(b,float(j)/n)
			var q=a.lerp(b,float(j+1)/n)
			var v=[Vector3(p.x-side.x,h(p.x-side.x,p.y-side.y)+0.06,p.y-side.y),Vector3(p.x+side.x,h(p.x+side.x,p.y+side.y)+0.06,p.y+side.y),
				Vector3(q.x-side.x,h(q.x-side.x,q.y-side.y)+0.06,q.y-side.y),Vector3(q.x+side.x,h(q.x+side.x,q.y+side.y)+0.06,q.y+side.y)]
			for i in [0,2,1,1,2,3]: st.add_vertex(v[i])
	st.generate_normals()
	world._mesh_node(st.commit(),dirt,"HillTrail")
	var bounds=Rect2(route[0],Vector2.ZERO)
	for p in route: bounds=bounds.expand(p)
	world.grass_routes.append({"route":route,"rect":bounds.grow(3.0)})
	# Lookout pavilion over the reservoir.
	var lp=Vector2(193.66,700)
	var base=Vector3(lp.x,h(lp.x,lp.y),lp.y)
	world._box(base+Vector3(0,0.2,0),Vector3(9,0.4,7),world.mats.wood,"LookoutDeck",true)
	for c in [Vector2(-4,-3),Vector2(4,-3),Vector2(-4,3),Vector2(4,3)]: queue("lookout_post",world.mats.metal,base+Vector3(c.x,1.8,c.y),Vector3(0.18,3.2,0.18))
	world._box(base+Vector3(0,3.5,0),Vector3(10,0.3,8),world._mat("3b2f5a"),"LookoutRoof")

# ---------------------------------------------------------------- landmarks
func _launch_bay() -> void:
	# YUST mecha launch bay: armoured pit, split blast doors, gantry tower and warning beacons.
	var r: Rect2=Blocks.LANDMARKS.launch_bay
	var c=r.get_center()
	var y=h(c.x,c.y)
	var bay=Node3D.new()
	bay.name="MechaLaunchBay"
	bay.position=Vector3(c.x,y,c.y)
	root.add_child(bay)
	world.grass_exclusions.append(r)
	var armour=world._mat("4a4f5c",0.55)
	var deep=world._mat("1d2028",0.7)
	var w=r.size.x
	var d=r.size.y
	# Raised armoured rim with hazard chevrons around the shaft.
	for s in [-1,1]:
		_bay_box(bay,Vector3(0,0.9,s*(d/2-3)),Vector3(w,1.8,6),armour,true)
		_bay_box(bay,Vector3(s*(w/2-3),0.9,0),Vector3(6,1.8,d-12),armour,true)
	for i in range(int(w/2)):
		var mat=world.mats.hazard if i%2==0 else world.mats.hazard_dark
		for s in [-1,1]: _bay_box(bay,Vector3(-w/2+1+i*2,1.82,s*(d/2-6.2)),Vector3(2,0.04,0.8),mat,false)
	_bay_box(bay,Vector3(0,-0.08,0),Vector3(w-11.8,0.4,d-11.8),deep,false)
	# Blast doors slid partly open, numbered.
	for s in [-1,1]:
		var door=_bay_box(bay,Vector3(s*(w/4-1.5+4),1.5,0),Vector3(w/2-9,0.9,d-14),world._mat("6a5a7a",0.5),true)
		_bay_box(bay,Vector3(s*(w/4-1.5+4),1.98,0),Vector3(w/2-14,0.06,1.2),world.mats.hazard,false)
	var number=Label3D.new()
	number.text="BAY 01"
	number.font_size=180
	number.pixel_size=0.04
	number.rotation_degrees.x=-90
	number.position=Vector3(-w/4+2.5,2.05,0)
	number.modulate=Color("f0b429")
	number.shaded=false
	bay.add_child(number)
	# Gantry tower with a lift cage and a boom arm over the shaft.
	var tx=w/2+5
	for corner in [Vector2(-2,-2),Vector2(2,-2),Vector2(-2,2),Vector2(2,2)]:
		_bay_box(bay,Vector3(tx+corner.x,14,corner.y-d/4),Vector3(0.6,28,0.6),world.mats.hazard,false)
	for k in range(7): _bay_box(bay,Vector3(tx,3+k*4,-d/4),Vector3(4.6,0.3,4.6),world.mats.hazard_dark,false)
	_bay_box(bay,Vector3(tx-14,27,-d/4),Vector3(30,1.2,2.4),world.mats.hazard,false)
	_bay_box(bay,Vector3(tx,10,-d/4),Vector3(3,3,3),world._mat("ffd79b",0.4,1.5),false)
	var tower_body=StaticBody3D.new()
	var shape=CollisionShape3D.new()
	var box=BoxShape3D.new()
	box.size=Vector3(5,28,5)
	shape.shape=box
	shape.position=Vector3(tx,14,-d/4)
	tower_body.add_child(shape)
	bay.add_child(tower_body)
	# Rotating amber warning beacons at the corners.
	for corner in [Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]:
		var p=Vector3(corner.x*(w/2-3),2.4,corner.y*(d/2-3))
		_bay_box(bay,p,Vector3(0.7,0.9,0.7),world._mat("ffb02e",0.3,3.2),false)
		var spin=Node3D.new()
		spin.set_script(load("res://scripts/spin.gd"))
		spin.speed=3.2
		spin.position=p+Vector3.UP*0.2
		bay.add_child(spin)
		var beam=SpotLight3D.new()
		beam.light_color=Color("ffae3a")
		beam.spot_range=22
		beam.spot_angle=24
		beam.light_energy=0.0
		beam.set_meta("night_energy",3.0)
		beam.shadow_enabled=false
		beam.rotation_degrees=Vector3(-25,0,0)
		spin.add_child(beam)
		world.lamps.append(beam)
	var sign=Label3D.new()
	sign.text="YUST  MECHA LAUNCH BAY"
	sign.font_size=64
	sign.pixel_size=0.022
	sign.position=Vector3(0,4.2,d/2-1)
	sign.modulate=Color("ffd06a")
	sign.shaded=false
	bay.add_child(sign)

func _bay_box(parent: Node3D,at: Vector3,size: Vector3,material: Material,solid: bool) -> MeshInstance3D:
	var node=MeshInstance3D.new()
	var mesh=BoxMesh.new()
	mesh.size=size
	node.mesh=mesh
	node.material_override=material
	node.position=at
	parent.add_child(node)
	if solid:
		var body=StaticBody3D.new()
		var shape=CollisionShape3D.new()
		var box=BoxShape3D.new()
		box.size=size
		shape.shape=box
		body.add_child(shape)
		node.add_child(body)
	return node

func _ferris_wheel() -> void:
	var x=535.21
	var z=Layout.shore(x)+16.0
	var base=Vector3(x,Layout.PROMENADE_Y,z)
	var frame=world._mat("eae6d6",0.5)
	for s in [-1,1]:
		for lean in [-1,1]:
			world._bar(base+Vector3(lean*6,0,s*1.6),base+Vector3(0,15,s*1.6),0.35,frame)
	var wheel=Node3D.new()
	wheel.set_script(load("res://scripts/spin.gd"))
	wheel.axis=Vector3(0,0,1)
	wheel.speed=0.08
	wheel.position=base+Vector3(0,15,0)
	wheel.name="SeafrontFerrisWheel"
	root.add_child(wheel)
	var rim=world._mat("ff7ac0",0.4,1.6)
	var spoke=world._mat("dcd6ff",0.5)
	var cars=[world._mat("f2c94c"),world._mat("4fa3c7"),world._mat("e2574c"),world._mat("7ad08a")]
	for i in range(24):
		var a=TAU*i/24
		var b=TAU*(i+1)/24
		var p=Vector3(cos(a)*13,sin(a)*13,0)
		var q=Vector3(cos(b)*13,sin(b)*13,0)
		_wheel_bar(wheel,p,q,0.25,rim)
		if i%2==0:
			_wheel_bar(wheel,Vector3.ZERO,p,0.12,spoke)
			var car=MeshInstance3D.new()
			var mesh=BoxMesh.new()
			mesh.size=Vector3(1.8,1.6,1.8)
			car.mesh=mesh
			car.material_override=cars[(i/2)%4]
			car.position=p+Vector3(0,-1.2,0)
			wheel.add_child(car)
	world.grass_exclusions.append(Rect2(x-8,z-3,16,6))
	world.activity_spots.append({"pos":Vector3(x+4,Layout.PROMENADE_Y,z+5),"title":"FERRIS WHEEL"})

func _wheel_bar(parent: Node3D,a: Vector3,b: Vector3,thickness: float,material: Material) -> void:
	var node=MeshInstance3D.new()
	var mesh=BoxMesh.new()
	mesh.size=Vector3(thickness,thickness,a.distance_to(b))
	node.mesh=mesh
	node.material_override=material
	node.position=(a+b)*0.5
	node.basis=Basis.looking_at((b-a).normalized(),Vector3.FORWARD if absf((b-a).normalized().y)>0.95 else Vector3.UP)
	parent.add_child(node)

func _utility_poles() -> void:
	# Concrete poles with cross-arms and sagging cable bundles along every local street.
	var concrete=world._mat("b9b6ad",0.85)
	var dark=world._mat("1c1d22",0.9)
	var transformer=world._mat("6f7a72",0.6)
	var previous={}
	for entry in pole_points:
		var p: Vector3=entry.p
		if Layout.wet(p.x,p.z) or not Layout.channel_sample(p.x,p.z).is_empty(): continue
		if not world.dressing_clearance.clears_transport(Vector2(p.x,p.z),0.5): continue
		var blocked=false
		for plot in world.building_plots:
			if Rect2(plot.plot).grow(1.0).has_point(Vector2(p.x,p.z)): blocked=true; break
		if blocked: continue
		p.y=h(p.x,p.z)
		queue("pole",concrete,p+Vector3.UP*4.5,Vector3(0.32,9.0,0.32))
		queue("pole_arm",concrete,p+Vector3.UP*8.4,Vector3(2.6,0.16,0.16))
		if counts.poles%5==2:
			queue("pole_transformer",transformer,p+Vector3(0,6.6,0.45),Vector3(0.9,1.2,0.7))
		var line=entry.line
		if previous.has(line):
			var q: Vector3=previous[line]
			if q.distance_to(p)<45.0:
				for k in [-1.1,0.0,1.1]:
					_cable(p+Vector3(k,8.5,0),q+Vector3(k,8.5,0),dark)
		previous[line]=p
		counts.poles+=1

func _cable(a: Vector3,b: Vector3,material: Material) -> void:
	var sag=clampf(a.distance_to(b)*0.035,0.35,1.4)
	var prev=a
	for s in range(1,7):
		var t=float(s)/6
		var p=a.lerp(b,t)
		p.y-=sag*4.0*t*(1.0-t)
		queue_segment("power_line",material,prev,p,0.05)
		prev=p


# ---------------------------------------------------------------- outskirts
func _outskirts() -> void:
	# Countryside beyond the map edge: rolling forested hills so the town never ends in a void.
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings=[0.0,20.0,60.0,140.0,300.0,600.0]
	var edges=[]
	# Walk the land border anticlockwise: west edge (north to south), south edge, east edge.
	var z=Layout.shore(0)
	while z<=1000.0: edges.append([Vector2(0,z),Vector2(-1,0)]); z+=20.0
	var x=0.0
	while x<=Layout.WORLD.end.x: edges.append([Vector2(x,1000),Vector2(0,1)]); x+=20.0
	z=1000.0
	while z>=Layout.shore(Layout.WORLD.end.x): edges.append([Vector2(Layout.WORLD.end.x,z),Vector2(1,0)]); z-=20.0
	for i in range(edges.size()-1):
		var a: Vector2=edges[i][0]
		var b: Vector2=edges[i+1][0]
		var na: Vector2=edges[i][1]
		var nb: Vector2=edges[i+1][1]
		for r in range(rings.size()-1):
			var quad=[]
			for pair in [[a,na,rings[r]],[b,nb,rings[r]],[a,na,rings[r+1]],[b,nb,rings[r+1]]]:
				var p: Vector2=pair[0]+pair[1]*pair[2]
				var base=Layout.height_at(clampf(pair[0].x,0,Layout.WORLD.end.x-0.1),clampf(pair[0].y,0,999.9))
				var rise=float(pair[2])*0.06+9.0*sin(p.x*0.011)*sin(p.y*0.013)*smoothstep(0.0,60.0,pair[2])
				quad.append(Vector3(p.x,base+rise,p.y))
			for j in [0,2,1,1,2,3]: st.add_vertex(quad[j])
	st.generate_normals()
	var hills=world.mats.grass.duplicate()
	var node=world._mesh_node(st.commit(),hills,"Outskirts")
	var mat=StandardMaterial3D.new()
	node.material_override.set_meta("outskirts",true)
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cull=world._mat("4f7d4a",0.95)
	cull.cull_mode=BaseMaterial3D.CULL_DISABLED
	node.material_override=cull


func _trail_bridges() -> void:
	# Where the hill trail crosses a canal, a plank footbridge carries it over the water.
	var trail: Array=Layout.HILL_TRAIL
	for route in Layout.WATER_ROUTES:
		var pts: Array=route.points
		for k in range(pts.size()-1):
			var c0=Vector2(pts[k].x,pts[k].z)
			var c1=Vector2(pts[k+1].x,pts[k+1].z)
			for t in range(trail.size()-1):
				var hit=Geometry2D.segment_intersects_segment(trail[t],trail[t+1],c0,c1)
				if hit==null: continue
				var dir: Vector2=(trail[t+1]-trail[t]).normalized()
				var span=route.width+7.0
				var a=hit-dir*span*0.5
				var b=hit+dir*span*0.5
				var ya=h(a.x,a.y)
				var yb=h(b.x,b.y)
				var mid=Vector3(hit.x,maxf(ya,yb)+0.1,hit.y)
				var deck=world._box(mid,Vector3(3.2,0.3,span),world.mats.wood,"TrailFootbridge",true)
				deck.rotation.y=atan2(dir.x,dir.y)
				for sd in [-1,1]:
					var side=Vector3(-dir.y,0,dir.x)*sd*1.5
					var rail=world._box(mid+side+Vector3(0,0.55,0),Vector3(0.1,0.9,span),world.mats.metal,"TrailBridgeRail",true)
					rail.rotation.y=atan2(dir.x,dir.y)
				# Sloped ramps from the trail up to the deck at both ends, so there is no step.
				for end in [[a,-1.0],[b,1.0]]:
					var edge=Vector3(end[0].x,mid.y+0.15,end[0].y)
					var out=end[0]+dir*end[1]*3.5
					var foot=Vector3(out.x,h(out.x,out.y)-0.05,out.y)
					var ramp=world._box((edge+foot)*0.5,Vector3(3.2,0.2,edge.distance_to(foot)+0.3),world.mats.wood,"TrailBridgeRamp",true)
					ramp.basis=Basis.looking_at((edge-foot).normalized(),Vector3.UP)
				counts.bridges+=1
