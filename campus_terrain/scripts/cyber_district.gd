extends RefCounted
## Cyberpunk density pass: infill shophouses and mid-rise blocks on empty ground, neon roof outlines,
## animated LED screens, drones, steam and solid street obstacles. All real-time; nothing baked.
## Infill sits only on open ground: never on roads, rails, stations, paths, plots, water or trails.
const Layout=preload("res://scripts/terrain_layout.gd")
const Roads=preload("res://scripts/road_layout.gd")
var world
var sl
var rng=RandomNumberGenerator.new()
var root: Node3D
var facade_materials: Array=[]
var led_materials: Array=[]
var infill_rects: Array=[]
var prop_rects: Array=[]
var counts={"infill":0,"outlined":0,"screens":0,"drones":0,"steam":0,"obstacles":0}
var wall_colours=["3a4048","4a5560","2f3a44","35565c","5a4a52","44505a","6a5a4a","2e4a50"]
var shop_names=["လက်ဖက်ရည်","မုန့်ဟင်းခါး","24H","REPAIR","MECHA PARTS","DATA CAFE","KARAOKE","SIM ARENA","NOODLES","BATTERY","HOSTEL","CLINIC","ROBOT BAR","PHONE FIX"]
const KEEP_CLEAR := [Rect2(578.87,562,235.21,358),Rect2(669.01,585,49.3,60)]

func setup(owner_world,street_life) -> void:
	world=owner_world
	sl=street_life
	rng.seed=2026111903
	root=Node3D.new()
	root.name="CyberDistrict"
	world.add_child(root)
	for building in world.get_node("PrototypeBuildings").get_children():
		if building is Node3D: _outline(building)
	_infill()
	_drones()
	print("CYBER_DISTRICT_READY ",counts)

func apply_mode(night: bool) -> void:
	for material in facade_materials: material.set_shader_parameter("night",1.0 if night else 0.0)
	for material in led_materials: material.set_shader_parameter("strength",1.0 if night else 0.45)

# ---------------------------------------------------------------- neon outlines
func _outline(building: Node3D) -> void:
	if "HANGAR" in str(building.get_meta("building_use","")): return
	var bounds: AABB=world._scene_bounds(building,building.get_parent_node_3d().global_transform)
	var local=bounds.position-building.global_position
	var w=bounds.size.x
	var d=bounds.size.z
	var top=bounds.end.y-building.global_position.y
	if w<4 or top<3: return
	# Roof outline sits on the main volume's top edge, not on antennas: use the shell height if known.
	var shell=building.get_node_or_null("Exterior")
	if shell==null: shell=building.get_node_or_null("CompositeShell")
	var edge_y=top-0.2
	if shell and shell is MeshInstance3D and shell.mesh is BoxMesh:
		edge_y=shell.position.y+shell.mesh.size.y/2+0.12
		w=shell.mesh.size.x+0.4
		d=shell.mesh.size.z+0.4
		local=Vector3(shell.position.x-w/2,0,shell.position.z-d/2)
	var cx=local.x+w/2
	var cz=local.z+d/2
	var colour=sl.colour_for(counts.outlined+1)
	var strip=sl.neon(colour,3.4)
	var node=Node3D.new()
	node.name="NeonOutline"
	building.add_child(node)
	sl._box(node,Vector3(cx,edge_y,cz-d/2),Vector3(w,0.12,0.12),strip,"NeonEdge")
	sl._box(node,Vector3(cx,edge_y,cz+d/2),Vector3(w,0.12,0.12),strip,"NeonEdge")
	sl._box(node,Vector3(cx-w/2,edge_y,cz),Vector3(0.12,0.12,d),strip,"NeonEdge")
	sl._box(node,Vector3(cx+w/2,edge_y,cz),Vector3(0.12,0.12,d),strip,"NeonEdge")
	for side in [-1,1]:
		sl._box(node,Vector3(cx+side*w/2,edge_y*0.5+1.5,cz+d/2),Vector3(0.12,maxf(0.5,edge_y-3.0),0.12),strip,"NeonCorner")
	counts.outlined+=1

# ---------------------------------------------------------------- infill
func _blocked(rect: Rect2) -> bool:
	for zone in KEEP_CLEAR:
		if zone.intersects(rect): return true
	for park in world.parks:
		if Rect2(park.rect).grow(2.0).intersects(rect): return true
	if rect.position.y<Layout.shore(rect.get_center().x)+40.0: return true
	# The hills keep their attractions and forest: no infill blocks there.
	if Layout.HILLS.intersects(rect): return true
	for pad in Layout.HILL_PADS:
		if Vector2(pad.x,pad.y).distance_to(rect.get_center())<pad.z+30.0: return true
	for other in infill_rects:
		if other.grow(4.0).intersects(rect): return true
	for entry in world.building_plots:
		if entry.plot.grow(3.0).intersects(rect): return true
	var district=world.get_node("PrototypeBuildings")
	for building in district.get_children():
		if building.has_meta("reserved_plot") and Rect2(building.get_meta("reserved_plot")).grow(3.0).intersects(rect): return true
	for exclusion in world.grass_exclusions:
		# Wide plazas and the market plateau may take infill; narrow walkways never do.
		if exclusion.size.x>=26 and exclusion.size.y>=26: continue
		if exclusion.intersects(rect): return true
	for route in world.grass_routes:
		if route.rect.intersects(rect): return true
	for other in prop_rects:
		if other.intersects(rect): return true
	var c=rect.get_center()
	for item in world.dressing_clearance.placements:
		if true:
			var r: float=item.radius*(0.55 if item.kind=="tree" else 1.0)
			var closest=Vector2(clampf(item.center.x,rect.position.x,rect.end.x),clampf(item.center.y,rect.position.y,rect.end.y))
			if closest.distance_to(item.center)<r: return true
	var radius=rect.size.length()*0.5
	if not Roads.has_clearance(c,radius+2.0): return true
	if not world.dressing_clearance.clears_transport(c,radius+1.0): return true
	var heights=[]
	for p in [rect.position,rect.end,Vector2(rect.position.x,rect.end.y),Vector2(rect.end.x,rect.position.y),c]:
		if not Layout.in_world(p.x,p.y) or Layout.wet(p.x,p.y): return true
		if not Layout.channel_sample(p.x,p.y).is_empty(): return true
		if world._inside_stair(p.x,p.y): return true
		heights.append(Layout.height_at(p.x,p.y))
	if heights.max()-heights.min()>1.4: return true
	return false

func _collect_props() -> void:
	# Footprints of existing dressing (stalls, kiosks, canopies, benches) so infill never overlaps them.
	for name in ["MasterplanDressing"]:
		var node=world.get_node_or_null(name)
		if node==null: continue
		for mesh in node.find_children("*","MeshInstance3D",true,false):
			var box: AABB=mesh.global_transform*mesh.get_aabb()
			if box.size.x>60 or box.size.z>60: continue
			prop_rects.append(Rect2(box.position.x,box.position.z,box.size.x,box.size.z).grow(1.0))

func _infill() -> void:
	_collect_props()
	var areas=[Rect2(7.04,250,830.99,690)]
	var candidates: Array=[]
	for area in areas:
		var x=area.position.x+8.0
		while x<area.end.x-8:
			var z=area.position.y+8.0
			while z<area.end.y-8:
				candidates.append(Vector2(x+rng.randf_range(-3,3),z+rng.randf_range(-3,3)))
				z+=11.0
			x+=11.0
	# Shuffle deterministically so infill spreads across districts instead of filling one corner.
	for i in range(candidates.size()-1,0,-1):
		var j=rng.randi_range(0,i)
		var t=candidates[i]; candidates[i]=candidates[j]; candidates[j]=t
	for c in candidates:
		if counts.infill>=95: break
		var kind=rng.randf()
		var w=rng.randf_range(7,10) if kind<0.65 else rng.randf_range(10,14)
		var d=rng.randf_range(7,9) if kind<0.65 else rng.randf_range(9,12)
		var floors=rng.randi_range(2,3) if kind<0.65 else 4   # cozy scale: never above 4 floors
		var rect=Rect2(c-Vector2(w,d)/2-Vector2(1.5,1.5),Vector2(w+3,d+3))
		if _blocked(rect): continue
		infill_rects.append(rect)
		_build(c,w,d,floors)
		_obstacles(c,w,d)

func _facade(w: float,h: float,d: float) -> ShaderMaterial:
	var material=ShaderMaterial.new()
	material.shader=load("res://shaders/cyber_facade.gdshader")
	material.set_shader_parameter("wall_colour",Color(wall_colours[rng.randi_range(0,wall_colours.size()-1)]))
	material.set_shader_parameter("size",Vector3(w,h,d))
	material.set_shader_parameter("seed",rng.randf_range(0,100))
	material.set_shader_parameter("lit_ratio",rng.randf_range(0.3,0.55))
	material.set_shader_parameter("night",1.0 if world.night else 0.0)
	facade_materials.append(material)
	return material

func _solid(node: MeshInstance3D) -> void:
	var body=StaticBody3D.new()
	var shape=CollisionShape3D.new()
	var box=BoxShape3D.new()
	box.size=(node.mesh as BoxMesh).size
	shape.shape=box
	body.add_child(shape)
	node.add_child(body)

func _build(c: Vector2,w: float,d: float,floors: int) -> void:
	var ground=INF
	for p in [c+Vector2(-w,-d)/2,c+Vector2(w,-d)/2,c+Vector2(-w,d)/2,c+Vector2(w,d)/2,c]:
		ground=minf(ground,Layout.height_at(p.x,p.y))
	var building=Node3D.new()
	building.name="CyberInfill_%02d"%counts.infill
	building.position=Vector3(c.x,ground,c.y)
	building.rotation.y=0.0
	building.set_meta("building_use","infill")
	root.add_child(building)
	var h=floors*3.1
	var body=sl._box(building,Vector3(0,h/2-0.6,0),Vector3(w,h+1.2,d),_facade(w,h+1.2,d),"InfillShell")
	_solid(body)
	world.grass_exclusions.append(Rect2(c-Vector2(w,d)/2,Vector2(w,d)).grow(0.4))
	# Ground-floor shopfront: lit glazing, awning, door strip and a sign.
	var colour=sl.colour_for(counts.infill)
	sl._box(building,Vector3(0,1.3,d/2+0.05),Vector3(w*0.7,2.2,0.08),sl.neon("ffc98a",1.6),"Shopfront")
	var awning=sl._box(building,Vector3(0,2.75,d/2+0.8),Vector3(w*0.85,0.14,1.6),sl.accent_materials[counts.infill%sl.accent_materials.size()],"InfillAwning")
	awning.rotation_degrees.x=12
	sl._box(building,Vector3(0,3.15,d/2+1.55),Vector3(w*0.85,0.08,0.08),sl.neon(colour,3.0),"AwningNeon")
	# Vertical blade sign.
	var blade_h=minf(h-1.0,7.0)
	var bx=(w/2-0.6)*(1 if counts.infill%2==0 else -1)
	sl._box(building,Vector3(bx,3.4+blade_h/2,d/2+0.8),Vector3(0.14,blade_h,1.4),sl.dark,"BladeBacking")
	for face in [-1,1]:
		sl._box(building,Vector3(bx+face*0.09,3.4+blade_h/2,d/2+0.8),Vector3(0.05,blade_h-0.4,1.0),sl.neon(sl.colour_for(counts.infill+2),3.6),"NeonBlade")
	var label=Label3D.new()
	label.text=shop_names[counts.infill%shop_names.size()]
	label.font_size=64
	label.pixel_size=0.012
	label.modulate=Color(colour).lightened(0.35)
	label.position=Vector3(0,3.6,d/2+0.2)
	label.shaded=false
	building.add_child(label)
	# Neon outline on the roof edge and corners.
	var strip=sl.neon(sl.colour_for(counts.infill+1),3.2)
	for z in [-d/2,d/2]: sl._box(building,Vector3(0,h+0.62,z),Vector3(w,0.12,0.12),strip,"NeonEdge")
	for x in [-w/2,w/2]: sl._box(building,Vector3(x,h+0.62,0),Vector3(0.12,0.12,d),strip,"NeonEdge")
	for x in [-w/2,w/2]: sl._box(building,Vector3(x,h/2+1.6,d/2),Vector3(0.12,h-2.0,0.12),strip,"NeonCorner")
	# Rooftop clutter and cables reuse the street-life kit.
	sl._rooftop(building,w,d,h+0.6,floors>=5)
	# Large animated LED screen on taller blocks.
	if floors>=4 or rng.randf()<0.3:
		_screen(building,Vector3(0,h*0.62,d/2+0.12),Vector2(w*0.7,minf(h*0.35,6.0)))
	# Steam from the occasional rooftop vent.
	if rng.randf()<0.35: _steam(building,Vector3(rng.randf_range(-w/3,w/3),h+0.9,-d/4))
	if counts.infill%3==0: sl._light(building,Vector3(0,3.0,d/2+2.5),colour,1.0,8.0)
	counts.infill+=1

func _screen(parent: Node3D,at: Vector3,size: Vector2) -> void:
	var material=ShaderMaterial.new()
	material.shader=load("res://shaders/led_screen.gdshader")
	var a=Color(sl.colour_for(counts.screens))
	var b=Color(sl.colour_for(counts.screens+2))
	material.set_shader_parameter("tint_a",a)
	material.set_shader_parameter("tint_b",b)
	material.set_shader_parameter("seed",rng.randf_range(0,50))
	material.set_shader_parameter("strength",1.0 if world.night else 0.45)
	led_materials.append(material)
	var quad=MeshInstance3D.new()
	var mesh=QuadMesh.new()
	mesh.size=size
	quad.mesh=mesh
	quad.material_override=material
	quad.position=at
	quad.name="LedScreen"
	quad.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(quad)
	sl._box(parent,at+Vector3(0,0,-0.08),Vector3(size.x+0.3,size.y+0.3,0.12),sl.dark,"ScreenFrame")
	counts.screens+=1

func _steam(parent: Node3D,at: Vector3) -> void:
	var steam=CPUParticles3D.new()
	steam.name="Steam"
	steam.position=at
	steam.amount=10
	steam.lifetime=3.2
	steam.direction=Vector3(0.2,1,0.1)
	steam.spread=12
	steam.initial_velocity_min=0.5
	steam.initial_velocity_max=0.9
	steam.gravity=Vector3(0.15,0.25,0.05)
	steam.scale_amount_min=0.8
	steam.scale_amount_max=1.6
	var curve=Curve.new()
	curve.add_point(Vector2(0,0.4))
	curve.add_point(Vector2(1,1.6))
	steam.scale_amount_curve=curve
	var mesh=QuadMesh.new()
	mesh.size=Vector2(0.9,0.9)
	steam.mesh=mesh
	var material=StandardMaterial3D.new()
	material.albedo_color=Color(0.85,0.88,0.95,0.16)
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode=BaseMaterial3D.BILLBOARD_PARTICLES
	steam.material_override=material
	steam.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(steam)
	counts.steam+=1

# ---------------------------------------------------------------- obstacles
func _obstacles(c: Vector2,w: float,d: float) -> void:
	# Barriers, planters and crates beside infill blocks, on open ground only (never on paths).
	var barrier=world._mat("c9c3b2",0.85)
	var stripe=world._mat("d8a63a",0.7)
	var planter=world._mat("3f4a52",0.8)
	var spots=[Vector2(-w/2-1.6,0),Vector2(w/2+1.6,0),Vector2(0,-d/2-1.6)]
	for spot in spots:
		var p=c+spot+Vector2(rng.randf_range(-1,1),rng.randf_range(-1,1))
		if _point_blocked(p): continue
		var y=Layout.height_at(p.x,p.y)
		var kind=rng.randi_range(0,2)
		var node: MeshInstance3D
		if kind==0:
			node=sl._box(root,Vector3(p.x,y+0.45,p.y),Vector3(2.2,0.9,0.6),barrier,"JerseyBarrier")
			sl._box(root,Vector3(p.x,y+0.7,p.y+0.31),Vector3(2.0,0.14,0.02),stripe,"BarrierStripe")
			node.rotation.y=rng.randf_range(-0.4,0.4)
		elif kind==1:
			node=sl._box(root,Vector3(p.x,y+0.4,p.y),Vector3(1.8,0.8,1.8),planter,"Planter")
			var bush=sl._cyl(root,Vector3(p.x,y+1.1,p.y),0.75,0.8,world.mats.leaf,"PlanterShrub")
			var sphere=SphereMesh.new()
			sphere.radius=0.8
			sphere.height=1.2
			bush.mesh=sphere
		else:
			node=sl._box(root,Vector3(p.x,y+0.45,p.y),Vector3(1.4,0.9,1.4),sl.accent_materials[rng.randi_range(0,sl.accent_materials.size()-1)],"CargoCrate")
			sl._box(root,Vector3(p.x+0.2,y+1.25,p.y-0.1),Vector3(0.9,0.7,0.9),sl.accent_materials[rng.randi_range(0,sl.accent_materials.size()-1)],"CargoCrate")
		_solid(node)
		counts.obstacles+=1

func _point_blocked(p: Vector2) -> bool:
	var probe=Rect2(p-Vector2(1.2,1.2),Vector2(2.4,2.4))
	for exclusion in world.grass_exclusions:
		if exclusion.intersects(probe): return true
	for route in world.grass_routes:
		if route.rect.intersects(probe): return true
	if not Roads.has_clearance(p,2.0): return true
	if not world.dressing_clearance.clears_transport(p,1.5): return true
	if Layout.wet(p.x,p.y) or not Layout.channel_sample(p.x,p.y).is_empty(): return true
	return false

# ---------------------------------------------------------------- drones
func _drones() -> void:
	var centres=[Vector2(693.66,700),Vector2(429.58,330),Vector2(366.2,450),Vector2(176.06,400),Vector2(105.63,520),Vector2(669.01,330),
		Vector2(436.62,740),Vector2(760.56,820),Vector2(535.21,230),Vector2(690.14,200),Vector2(176.06,700),Vector2(302.82,620)]
	for i in range(centres.size()):
		var c: Vector2=centres[i]
		var drone=Node3D.new()
		drone.set_script(load("res://scripts/drone_flight.gd"))
		drone.name="Drone_%d"%i
		drone.centre=Vector3(c.x,Layout.height_at(c.x,c.y)+rng.randf_range(16,26),c.y)
		drone.radius=rng.randf_range(14,30)
		drone.speed=rng.randf_range(0.15,0.35)*(1 if i%2==0 else -1)
		drone.angle=rng.randf_range(0,TAU)
		drone.bob=rng.randf_range(0,3)
		root.add_child(drone)
		sl._box(drone,Vector3.ZERO,Vector3(0.7,0.22,0.7),sl.dark,"DroneBody")
		sl._box(drone,Vector3(0,-0.2,0),Vector3(0.45,0.3,0.45),sl.accent_materials[i%sl.accent_materials.size()],"DronePackage")
		for corner in [Vector2(-0.55,-0.55),Vector2(0.55,-0.55),Vector2(-0.55,0.55),Vector2(0.55,0.55)]:
			var arm=sl._box(drone,Vector3(corner.x*0.6,0,corner.y*0.6),Vector3(0.6,0.06,0.08),sl.dark,"DroneArm")
			arm.rotation.y=atan2(corner.x,corner.y)
			var rotor=sl._cyl(drone,Vector3(corner.x,0.14,corner.y),0.32,0.03,sl.steel,"DroneRotor")
			drone.rotors.append(rotor)
		sl._box(drone,Vector3(0,-0.05,0.38),Vector3(0.2,0.08,0.06),sl.neon("2fe6e0",4.0),"DroneEye")
		drone.blink=sl._box(drone,Vector3(0,0.18,-0.3),Vector3(0.14,0.14,0.14),sl.neon("ff2a2a",6.0),"DroneBlink")
		var glow=OmniLight3D.new()
		glow.light_color=Color("6fe8ff")
		glow.omni_range=5.0
		glow.light_energy=0.8 if world.night else 0.0
		glow.set_meta("night_energy",0.8)
		glow.shadow_enabled=false
		glow.position=Vector3(0,-0.5,0)
		drone.add_child(glow)
		world.lamps.append(glow)
		counts.drones+=1
