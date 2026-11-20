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
	for route in [Layout.NORTH_TRAIL,Layout.WEST_TRAIL,Layout.MARKET_TRAIL]:
		var accumulated=0.0
		for i in range(route.size()-1):
			var a: Vector2=route[i]
			var end: Vector2=route[i+1]
			var side=Vector2(-(end-a).y,(end-a).x).normalized()
			var length=a.distance_to(end)
			var steps=maxi(1,ceili(length/16.0))
			for j in range(steps):
				var p=a.lerp(end,float(j)/steps)+side*2.5
				fixture(Vector3(p.x,Layout.height_at(p.x,p.y)+0.04,p.y),1.9,"forest_paths",1.0,8)
			accumulated+=length
	for p in [Vector2(240,-105),Vector2(205,-145),Vector2(-160,195)]:
		omni(Vector3(p.x,Layout.height_at(p.x,p.y)+2.5,p.y),"ffd19b",2.0,14,"forest_lookouts")
	for z in [-165,-153,-43]:
		var x=Layout.north_stream_x(z)
		var y=Layout.north_water_y(z)
		spot(Vector3(x+6,y+5,z+5),Vector3(x,y,z),"9ccedb",2.0,20,48,"waterfall")

func _market_and_gardens() -> void:
	for z in [-588,-552,-516,-480,-444]:
		for x in [136,463]: omni(Vector3(x,Layout.height_at(x,z)+2.3,z+1),"ffbf77",1.8,9,"market_stalls")
	for x in [230,352]: omni(Vector3(x,Layout.height_at(x,-386)+2.5,-386),"ffd49d",2.5,16,"market_terraces")
	for entry in world.building_plots:
		var use: String=entry.label
		if not ("GARDEN" in use or "COURTYARD" in use or "PICNIC" in use): continue
		var rect: Rect2=entry.plot
		for p in [rect.position+Vector2(3,3),rect.end-Vector2(3,3)]:
			fixture(Vector3(p.x,Layout.height_at(p.x,p.y),p.y),2.5,"gardens",1.2,11)
	for i in range(18):
		var angle=TAU*i/18
		var p=Vector2(550+55*cos(angle),548+53*sin(angle))
		if world.dressing_clearance.clears_transport(p,0.3):
			omni(Vector3(p.x,Layout.height_at(p.x,p.y)+0.55,p.y),"ffc27e",1.1,8,"lake_walk")
	for p in [Vector2(508,555),Vector2(189,435),Vector2(438,183),Vector2(150,150)]:
		omni(Vector3(p.x,Layout.height_at(p.x,p.y)+3.4,p.y),"ffd7a8",2.0,16,"social_spaces")
	for rect in [Rect2(208,163,64,34),Rect2(366,471,52,34)]:
		for p in [rect.position,rect.end]:
			var height=Layout.height_at(p.x,p.y)
			var centre=rect.get_center()
			spot(Vector3(p.x,height+7,p.y),Vector3(centre.x,height,centre.y),"cee5ec",3.0,45,48,"sports_courts")

func _waterfront() -> void:
	for x in range(-280,600,28):
		if absf(x+30)<10 or absf(x-150)<10 or absf(x-520)<10: continue
		spot(Vector3(x,0.6,647.0),Vector3(x,5,645.0),"ffd09a",2.8,14,43,"retaining_wall")
	for x in [-30,150,520]:
		omni(Vector3(x+5,2.6,652),"ffca8a",1.6,12,"stair_landings")
		omni(Vector3(x+5,12.62,624),"ffca8a",1.6,12,"stair_landings")

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
