extends Node3D
## Reference-led blue-hour lighting. All illumination is real time.
const Layout=preload("res://scripts/terrain_layout.gd")
var world
var warm_fixture: StandardMaterial3D
var cool_fixture: StandardMaterial3D
var metal: StandardMaterial3D
var materials: Array=[]
var zones={}
var added_lights: Array[Light3D]=[]

func _ready() -> void:
	name="CityLighting"
	warm_fixture=world._mat("ffd09a",0.5,2.4)
	cool_fixture=world._mat("9ad6e5",0.5,1.8)
	metal=world._mat("425b65")
	_buildings()
	_forest_paths()
	_market_and_gardens()
	_waterfront()
	_stations()
	_collect_materials()
	apply_mode(world.night)
	print("CITY_LIGHTING_READY added=",added_lights.size()," total=",world.lamps.size()," zones=",zones," materials=",materials.size())

func add_light(light: Light3D,position: Vector3,colour: String,energy: float,zone: String) -> void:
	light.position=position
	light.light_color=Color(colour)
	light.shadow_enabled=false
	light.set_meta("night_energy",energy)
	light.set_meta("lighting_zone",zone)
	light.light_energy=energy if world.night else 0.0
	add_child(light)
	world.lamps.append(light)
	added_lights.append(light)
	zones[zone]=int(zones.get(zone,0))+1

func omni(position: Vector3,colour: String,energy: float,radius: float,zone: String) -> void:
	var light=OmniLight3D.new()
	light.omni_range=radius
	light.omni_attenuation=1.35
	add_light(light,position,colour,energy,zone)

func spot(position: Vector3,target: Vector3,colour: String,energy: float,radius: float,angle: float,zone: String) -> void:
	var light=SpotLight3D.new()
	light.spot_range=radius
	light.spot_angle=angle
	light.spot_attenuation=1.2
	add_light(light,position,colour,energy,zone)
	light.basis=Basis.looking_at((target-position).normalized(),Vector3.UP)

func fixture(position: Vector3,height: float,zone: String,energy=1.3,radius=9.0) -> void:
	if not world.dressing_clearance.reserve(Vector2(position.x,position.z),0.3,"lamp"): return
	var post=MeshInstance3D.new()
	var mesh=CylinderMesh.new()
	mesh.top_radius=0.06
	mesh.bottom_radius=0.09
	mesh.height=height
	mesh.radial_segments=8
	post.mesh=mesh
	post.material_override=metal
	post.position=position+Vector3.UP*height/2
	add_child(post)
	var body=StaticBody3D.new()
	var shape=CollisionShape3D.new()
	var box=BoxShape3D.new()
	box.size=Vector3(0.3,height,0.3)
	shape.shape=box
	body.add_child(shape)
	post.add_child(body)
	var cap=MeshInstance3D.new()
	var head=BoxMesh.new()
	head.size=Vector3(0.32,0.18,0.32)
	cap.mesh=head
	cap.material_override=warm_fixture
	cap.position=position+Vector3.UP*height
	cap.add_to_group("city_lamp_emitters")
	add_child(cap)
	omni(cap.position-Vector3.UP*0.15,"ffca8a",energy,radius,zone)

func _buildings() -> void:
	for building in world.get_node("PrototypeBuildings").get_children():
		var bounds: AABB=world._scene_bounds(building)
		var c=bounds.get_center()
		var base=bounds.position.y
		var use: String=building.get_meta("building_use")
		var market=building.get_meta("architectural_style","")=="curved_glass_market"
		if building.has_meta("entrance_local"):
			var doorway: Vector3=building.global_position+building.get_meta("entrance_local")
			spot(doorway+Vector3(0,3.1,1.8),doorway+Vector3(0,0.1,3.5),"ffd09a",2.6,13,58,"shopfronts")
		for sign_value in [-1,1]:
			var z=bounds.position.z-0.35 if sign_value<0 else bounds.end.z+0.35
			if market:
				for x in [-0.28,0.28]: omni(Vector3(c.x+bounds.size.x*x,base+3.4,z),"ffc17b",3.1,20,"market_halls")
			else:
				omni(Vector3(c.x,base+3.8,z),"ffb66c",1.5,12,"window_spill")
		if "CLINIC" in use or "ARCADE" in use or "ROBOT" in use:
			omni(Vector3(bounds.end.x+0.25,base+4,c.z),"86cbd9",1.6,11,"tech_accents")
		for child in building.find_children("CafeCanopy*","MeshInstance3D",true,false):
			var pos: Vector3=child.global_position
			for side in [-1,1]: omni(pos+Vector3(side*2,-0.45,0),"ffbe78",1.7,8,"rooftop_cafes")

func _forest_paths() -> void:
	for route in Layout.TRAILS:
		for i in range(route.size()-1):
			var a: Vector2=route[i]
			var end: Vector2=route[i+1]
			var side=Vector2(-(end-a).y,(end-a).x).normalized()
			var steps=maxi(1,ceili(a.distance_to(end)/16.0))
			for j in range(steps):
				var p=a.lerp(end,float(j)/steps)+side*2.4
				fixture(Vector3(p.x,Layout.height_at(p.x,p.y)+0.04,p.y),1.9,"hill_trails",1.0,8)
	# Reservoir rim and the spillway cascade.
	for i in range(14):
		var angle=TAU*i/14
		var p=Vector2(Layout.RESERVOIR.x+Layout.RESERVOIR.z*1.18*cos(angle),Layout.RESERVOIR.y+Layout.RESERVOIR.w*1.18*sin(angle))
		omni(Vector3(p.x,Layout.height_at(p.x,p.y)+0.6,p.y),"ffc27e",1.1,8,"reservoir_walk")
	spot(Vector3(121.13,19,630),Vector3(116.2,12,610),"9ccedb",2.0,22,48,"spillway")

func _market_and_gardens() -> void:
	for entry in world.parks:
		var rect: Rect2=entry.rect
		for p in [rect.position+Vector2(4,4),rect.end-Vector2(4,4),Vector2(rect.position.x+4,rect.end.y-4),Vector2(rect.end.x-4,rect.position.y+4)]:
			fixture(Vector3(p.x,Layout.height_at(p.x,p.y),p.y),2.6,"gardens",1.2,11)
		var c=rect.get_center()
		omni(Vector3(c.x,Layout.height_at(c.x,c.y)+3.4,c.y),"ffd7a8",2.0,16,"social_spaces")
	for i in range(14):
		var angle=TAU*i/14
		var p=Vector2(Layout.POND.x+Layout.POND.z*1.2*cos(angle),Layout.POND.y+Layout.POND.w*1.2*sin(angle))
		omni(Vector3(p.x,Layout.height_at(p.x,p.y)+0.55,p.y),"ffc27e",1.0,7,"campus_pond")

func _waterfront() -> void:
	# Promenade lamps follow the sea wall; warm light pools fall on the walk, not the water.
	var x=20.0
	while x<Layout.WORLD.end.x-20.0:
		var z=Layout.shore(x)+3.5
		if Layout.harbour_weight(x)<0.5 or int(x)%2==0:
			fixture(Vector3(x,Layout.height_at(x,z),z),4.2,"promenade",1.6,12)
		x+=26.0

func _stations() -> void:
	for station in world.skytrain.stations:
		for z in [-10,10]:
			var p: Vector3=station.root.to_global(Vector3(0,3.7,z))
			omni(p,"ffd5a0",1.4,12,"skytrain_platforms")

func _collect_materials() -> void:
	var seen={}
	for group in ["city_window_panels","city_lamp_emitters"]:
		for mesh in get_tree().get_nodes_in_group(group):
			var material=mesh.material_override as StandardMaterial3D
			if material==null or seen.has(material.get_instance_id()): continue
			seen[material.get_instance_id()]=true
			var colour=material.albedo_color
			var is_window=group=="city_window_panels"
			var cool=colour.b>colour.r and colour.g>colour.r
			var emission_colour=Color(0.4,0.78,1.0) if cool else Color(1.0,0.62,0.27) if colour.b>0.7 else Color(1.0,0.42,0.08)
			materials.append({"material":material,"night_colour":colour,"emission_colour":emission_colour,"night_emission":1.1 if is_window else 1.6,"window":is_window})

func apply_mode(night: bool) -> void:
	for entry in materials:
		var material: StandardMaterial3D=entry.material
		material.albedo_color=entry.night_colour if night else Color("3a6376") if entry.window else Color("c6ccc4")
		material.emission_enabled=night
		material.emission=entry.emission_colour
		material.emission_energy_multiplier=entry.night_emission if night else 0.0
	for light in added_lights:
		light.light_energy=float(light.get_meta("night_energy")) if night else 0.0
