extends Node3D
## All geometry here is an editable terrain prototype, not final imported building art.

const Layout = preload("res://scripts/terrain_layout.gd")
const Player = preload("res://scripts/player.gd")
const FollowCamera = preload("res://scripts/follow_camera.gd")
const DressingClearance = preload("res://scripts/dressing_clearance.gd")
var player: CharacterBody3D
var camera: Camera3D
var sun: DirectionalLight3D
var environment: Environment
var night: bool = false
var labels: Array[Label3D] = []
var lamps: Array[Light3D] = []
var status: Label
var overview_button: Button
var night_button: Button
var rng = RandomNumberGenerator.new()
var mats: Dictionary = {}
var tree_resources: Array[PackedScene] = []
var tree_bounds: Array[AABB] = []
var elapsed: float = 0.0
var grass_exclusions: Array=[]
var grass_routes: Array=[]
var model_bridge_spans: Array=[]
var building_plots: Array = []
var grass_system: Node3D
var water_view_index=0
var wildlife
var wildlife_view_index=0
var wildlife_focus: Node3D
var breeze
var quitting=false
var interiors
var skytrain
var buses
var city_lighting
var street_life
var dressing_clearance: DressingClearance
var pending_path_lamps: Array[Vector2]=[]
var pending_trees: Array[Vector3]=[]
var wind_trees: Array=[]
var wind_plants: Array=[]
var downloaded_props=preload("res://scripts/downloaded_props.gd").new()

func _ready() -> void:
	rng.seed = 20261118
	_materials()
	downloaded_props.setup(self)
	_lighting()
	_ground()
	_roads()
	_walkways()
	_retaining_walls()
	_water_and_bridges()
	_amenities()
	_planting()
	_city_quadrants()
	_natural_hills()
	_expanded_district_terrain()
	_south_river()
	downloaded_props.swing(204,437)
	_build_connected_roads()
	# Original downloaded models remain available as an optional comparison.
	if "--downloaded-buildings" in OS.get_cmdline_user_args():
		load("res://scripts/downloaded_buildings.gd").new().setup(self)
	load("res://scripts/reference_buildings.gd").new().setup(self)
	var water_network=load("res://scripts/water_network.gd").new()
	water_network.world=self
	add_child(water_network)
	player = Player.new()
	player.name = "Student"
	add_child(player)
	player.teleport(Vector3(150, 0.15, 275))
	camera = FollowCamera.new()
	camera.name = "HighCamera"
	camera.target = player
	add_child(camera)
	player.camera = camera
	_hud()
	toggle_night()
	interiors=load("res://scripts/building_interiors.gd").new()
	interiors.world=self
	add_child(interiors)
	wildlife=load("res://scripts/wildlife.gd").new()
	wildlife.world=self
	add_child(wildlife)
	breeze=load("res://scripts/town_breeze.gd").new()
	breeze.world=self
	skytrain=load("res://scripts/skytrain.gd").new()
	skytrain.world=self
	add_child(skytrain)
	buses=load("res://scripts/bus_service.gd").new()
	buses.world=self
	add_child(buses)
	dressing_clearance=DressingClearance.new()
	dressing_clearance.setup(self)
	load("res://scripts/district_fountains.gd").new().setup(self)
	for p in pending_path_lamps: _lamp(p.x,p.y)
	for p in pending_trees: _tree(p.x,p.y,p.z)
	pending_path_lamps.clear()
	pending_trees.clear()
	load("res://scripts/masterplan_dressing.gd").new().setup(self)
	if "--no-street-life" not in OS.get_cmdline_user_args():
		street_life=load("res://scripts/street_life.gd").new()
		street_life.setup(self)
		street_life.apply_mode(night)
	add_child(breeze)
	if DisplayServer.get_name()!="headless":
		grass_system=load("res://scripts/grass_system.gd").new()
		grass_system.target=player
		grass_system.camera=camera
		grass_system.excluded_rects=grass_exclusions
		grass_system.excluded_routes=grass_routes
		add_child(grass_system)
	city_lighting=load("res://scripts/city_lighting.gd").new()
	city_lighting.world=self
	add_child(city_lighting)
	var args = OS.get_cmdline_user_args()
	if "--breeze-capture" in args:
		_breeze_capture()
	elif "--wildlife-capture" in args:
		_wildlife_capture()
	elif "--street-capture" in args:
		_street_capture()
	elif "--calm-water-capture" in args:
		_calm_water_capture()
	elif "--props-capture" in args:
		_props_capture()
	elif "--water-capture" in args:
		_water_capture()
	elif "--grass-capture" in args:
		_grass_capture()
	elif "--capture" in args:
		_capture_sequence()
	if DisplayServer.get_name()!="headless": get_tree().auto_accept_quit=false
	print("TERRAIN_READY: four 300 x 300 m quadrants around crossroads")

func _mat(colour: String, roughness: float = 0.8, emission: float = 0.0) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(colour)
	material.roughness = roughness
	if emission > 0:
		material.emission_enabled = true
		material.emission = Color(colour)
		material.emission_energy_multiplier = emission
	return material

func _materials() -> void:
	mats.concrete = _mat("b9c5c4")
	mats.coping = _mat("e0ded0")
	mats.metal = _mat("3e626b", 0.45)
	mats.wood = _mat("aa8058")
	mats.dark_wood = _mat("6c5945")
	mats.rock = _mat("71837d")
	mats.leaf = _mat("4d7e55")
	mats.flower = _mat("cbaa61")
	mats.pink = _mat("b8788b")
	mats.cyan = _mat("64c7c4", 0.4, 0.45)
	mats.amber = _mat("ffd79b", 0.5, 0.6)
	mats.road = _mat("404d54")
	mats.paint = _mat("d5d5bc")
	var grass=ShaderMaterial.new()
	grass.shader=load("res://shaders/ground_grass.gdshader")
	mats.grass=grass
	var paving_shader = Shader.new()
	paving_shader.code = """shader_type spatial;
varying vec3 world_pos;
float hash21(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise2(vec2 p) {
 vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);
}
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
 vec2 p = world_pos.xz;
 vec2 tile = floor(p / 2.0);
 vec2 f = fract(p / 2.0);
 float joint = step(0.965, f.x) + step(0.965, f.y);
 float tone = 0.88 + hash21(tile) * 0.24;
 float stain = noise2(p * 0.18) * 0.6 + noise2(p * 0.9) * 0.4;
 vec3 base = mix(vec3(0.25,0.30,0.29), vec3(0.20,0.25,0.26), smoothstep(0.35,0.75,stain)) * tone;
 float edge = smoothstep(0.78, 1.0, max(f.x, f.y)) * 0.5;
 base *= 1.0 - edge * 0.25;
 float crack = step(0.992, noise2(p * 3.1 + tile * 7.0)) * 0.5;
 base *= 1.0 - crack * 0.4;
 vec3 colour = mix(base, vec3(0.13,0.17,0.17), clamp(joint,0.0,1.0));
 float puddle = smoothstep(0.74, 0.8, noise2(p * 0.33 + 11.0));
 colour *= 1.0 - puddle * 0.18;
 ALBEDO = colour;
 ROUGHNESS = mix(0.72, 0.06, puddle);
 SPECULAR = mix(0.5, 0.9, puddle);
}"""
	var paving = ShaderMaterial.new()
	paving.shader = paving_shader
	mats.paving = paving
	var water=ShaderMaterial.new()
	water.shader=load("res://shaders/stylized_water.gdshader")
	mats.water=water
	mats.water_bed=_mat("8cabae",0.96)
	mats.water_bed.cull_mode=BaseMaterial3D.CULL_DISABLED

func _lighting() -> void:
	var world_environment = WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("91aaa7")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("a5c1c7")
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled=true
	environment.glow_intensity=0.65
	environment.glow_bloom=0.08
	environment.ssao_enabled=true
	environment.ssao_radius=1.5
	environment.ssao_intensity=0.65
	environment.ssr_enabled=true
	environment.fog_enabled=true
	environment.fog_density=0.000004
	environment.fog_sky_affect=0.0
	environment.fog_light_color=Color("526c86")
	world_environment.environment = environment
	add_child(world_environment)
	sun = DirectionalLight3D.new()
	sun.name = "AfternoonSun"
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_color = Color("ffedca")
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 420
	add_child(sun)

func _mesh_node(mesh: Mesh, material: Material, node_name: String, solid: bool = false) -> MeshInstance3D:
	var instance = MeshInstance3D.new()
	instance.name = node_name
	if node_name in ["DistrictLake","LowerForestPool"]: mesh=_wave_disk()
	instance.mesh = mesh
	instance.material_override = material
	if material==mats.water:
		instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if node_name=="WaterfallAndCreek":
			instance.material_override=material.duplicate()
			instance.material_override.set_shader_parameter("flow_direction",Vector2(0,1))
			instance.material_override.set_shader_parameter("flow_speed",0.3)
			instance.material_override.set_shader_parameter("wave_height",0.012)
			instance.material_override.set_shader_parameter("water_kind",3)
		elif node_name=="ContinuousSouthRiver":
			instance.material_override=material.duplicate()
			instance.material_override.set_shader_parameter("water_kind",1)
		elif "Lake" in node_name or "Pool" in node_name or "Fountain" in node_name:
			instance.material_override=material.duplicate()
			instance.material_override.set_shader_parameter("flow_speed",0.045)
			instance.material_override.set_shader_parameter("wave_height",0.022)
			instance.material_override.set_shader_parameter("water_kind",2)

	add_child(instance)
	if solid:
		var body = StaticBody3D.new()
		var collision = CollisionShape3D.new()
		collision.shape = mesh.create_trimesh_shape()
		body.add_child(collision)
		instance.add_child(body)
	return instance

func _box(at: Vector3, size: Vector3, material: Material, node_name: String = "Detail", solid: bool = false) -> MeshInstance3D:
	if node_name in ["SouthRoad","EastServiceRoad","NorthSouthAvenue","EastWestAvenue","StatuePlinth","MarketRainGardenEdge","MarketDrainageBasin","LakeBoardwalk"]:
		grass_exclusions.append(Rect2(Vector2(at.x-size.x*0.5,at.z-size.z*0.5),Vector2(size.x,size.z)).grow(0.35))
	var mesh = BoxMesh.new()
	mesh.size = size
	var instance = _mesh_node(mesh, material, node_name)
	instance.position = at
	if solid:
		var body = StaticBody3D.new()
		var collision = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		instance.add_child(body)
	return instance

func _cylinder(at: Vector3, radius: float, height: float, material: Material, node_name: String = "Detail") -> MeshInstance3D:
	if "Fountain" in node_name:
		grass_exclusions.append(Rect2(Vector2(at.x-radius,at.z-radius),Vector2.ONE*radius*2).grow(0.3))
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	var instance = _mesh_node(mesh, material, node_name)
	instance.position = at
	return instance

func _bar(a: Vector3, b: Vector3, radius: float, material: Material) -> void:
	if a.distance_to(b) < 0.001:
		return
	var instance = _cylinder((a + b) * 0.5, radius, a.distance_to(b), material, "Rail")
	var axis = (b - a).normalized()
	var reference = Vector3.RIGHT if absf(axis.dot(Vector3.FORWARD)) > 0.95 else Vector3.FORWARD
	var right = axis.cross(reference).normalized()
	instance.basis = Basis(right, axis, right.cross(axis)).orthonormalized()

func _surface(rect: Rect2, material: Material, node_name: String, solid: bool, height_function: Callable, step: float = 1.0, skip_water: bool = false) -> void:
	if material!=mats.grass and material!=mats.water:
		grass_exclusions.append(rect.grow(0.35))
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var xs: Array[float] = []
	var zs: Array[float] = []
	var count_x = ceili(rect.size.x / step)
	var count_z = ceili(rect.size.y / step)
	for i in range(count_x + 1):
		xs.append(minf(rect.position.x + i * step, rect.end.x))
	for j in range(count_z + 1):
		zs.append(minf(rect.position.y + j * step, rect.end.y))
	for edge in [80.01, 210.01, 645.0, 645.01]:
		if edge > rect.position.y and edge < rect.end.y:
			zs.append(edge)
	zs.sort()
	for ix in range(xs.size() - 1):
		for iz in range(zs.size() - 1):
			var x = xs[ix]
			var z = zs[iz]
			var xx = xs[ix + 1]
			var zz = zs[iz + 1]
			if material==mats.paving and _inside_stair((x+xx)*0.5,(z+zz)*0.5): continue
			if skip_water and Layout.wet((x + xx) * 0.5, (z + zz) * 0.5):
				continue
			var a = Vector3(x, height_function.call(x, z), z)
			var b = Vector3(xx, height_function.call(xx, z), z)
			var c = Vector3(x, height_function.call(x, zz), zz)
			var e = Vector3(xx, height_function.call(xx, zz), zz)
			for point in [a, b, c, b, e, c]:
				st.set_uv(Vector2(point.x, point.z) / 4.0)
				st.add_vertex(point)
	st.generate_normals()
	st.index()
	_mesh_node(st.commit(), material, node_name, solid)

func _ground() -> void:
	_surface(Rect2(0,0,614,614),mats.grass,"CampusGround",true,Layout.height_at)
	_box(Vector3(307,-5,307),Vector3(614,2.2,614),mats.rock,"GroundBase")
	# Boundaries follow the union of town + north parcel + west parcel.
	var outline=[Vector2(0,-700),Vector2(614,-700),Vector2(614,0),Vector2(614,810),Vector2(-300,810),Vector2(-300,0),Vector2(0,0)]
	for i in range(outline.size()):
		var a: Vector2=outline[i]
		var b: Vector2=outline[(i+1)%outline.size()]
		var c=(a+b)*0.5
		_box(Vector3(c.x,30,c.y),Vector3(maxf(absf(a.x-b.x),0.5),150,maxf(absf(a.y-b.y),0.5)),mats.metal,"WorldEdge",true).visible=false

func _roads() -> void:
	pass # Vehicle roads are assembled from road_layout.gd after terrain construction.

func _path(rect: Rect2, node_name: String = "Walkway") -> void:
	_surface(rect, mats.paving, node_name, false, func(x: float, z: float) -> float: return Layout.base_height_at(x, z) + 0.035, 0.5, true)

func _walkways() -> void:
	for z in [65,150,270]: _path(Rect2(5,z-3,281,6),"CrossCampusPromenade")
	for cx in Layout.CENTRES:
		_path(Rect2(cx-3,8,6,282),"NorthSouthSpine")
		for edge in [80.0,210.0]:
			_path(Rect2(cx+25,edge-20,6,40),"AccessibleRamp")
			_path(Rect2(cx,edge-23,31,3),"RampTopLanding")
			_path(Rect2(cx,edge+20,31,3),"RampBottomLanding")
			downloaded_props.stair(cx,edge,8.0,8.0,2.0,2.0 if edge==80 else 0.0)
	_path(Rect2(125,125,50,55),"CentralQuad")

func _rail(a: Vector2, b: Vector2, on_route: bool = false, fixed_height: float = -999.0) -> void:
	var total = a.distance_to(b)
	var count = maxi(1, ceili(total / 4.0))
	var previous = Vector3.ZERO
	for i in range(count + 1):
		var p = a.lerp(b, float(i) / count)
		var h = fixed_height if fixed_height > -900 else Layout.dry_height(p.x, p.y)
		if on_route:
			# Evaluate just inside the stair/ramp rather than on adjacent higher ground.
			var sample_x = p.x
			for cx in Layout.CENTRES:
				if absf(sample_x - cx) < 4.5: sample_x = cx
				if absf(sample_x - (cx + 30)) < 3.5: sample_x = cx + 30
				if absf(sample_x - (cx - 30)) < 3.5: sample_x = cx - 30
			h = Layout.dry_height(sample_x, p.y)
		var top = Vector3(p.x, h + 1.05, p.y)
		_cylinder(Vector3(p.x, h + 0.5, p.y), 0.055, 1.0, mats.metal, "RailPost")
		if i > 0:
			_bar(previous, top, 0.045, mats.metal)
		previous = top

func _retaining_walls() -> void:
	for edge in [80.0,210.0]:
		for x in range(286):
			var clear = Layout.Roads.sample(x+0.5,edge).is_empty()
			for cx in Layout.CENTRES:
				if absf(x-cx)<5 or absf(x-(cx+28))<4: clear=false
			if not clear: continue
			var low = 2.0 if edge == 80 else 0.0
			_box(Vector3(x+0.5,low+1,edge+0.02),Vector3(1,2,0.25),mats.concrete,"TerraceWall")

func _water_and_bridges() -> void:
	_bridge(Vector2(Layout.stream_x(150),150),19,6)

func _bridge(centre: Vector2, length: float, width: float) -> void:
	model_bridge_spans.append(Rect2(centre.x-length/2,centre.y-width/2,length,width).grow(0.4))
	downloaded_props.bridge(centre,length,width)

func _amenities() -> void:
	_box(Vector3(166,2.25,164),Vector3(4,0.5,4),mats.coping,"StatuePlinth",true)
	_label("CENTRAL QUAD",Vector3(150,2.2,175))
	for cx in Layout.CENTRES:
		for z in [35,65,110,150,185,245,275]:
			_lamp(cx-6,z)
			_lamp(cx+6,z)
		for z in [65,150,270]: _bench(cx+9,z+5)
	for x in [16,30,90]:
		var log=_cylinder(Vector3(x,0.35,250),0.32,3,mats.dark_wood,"GardenLogSeat")
		log.rotation.z=PI/2

func _bench(x: float, z: float) -> void:
	downloaded_props.bench(x,z)

func _lamp(x: float, z: float) -> void:
	if dressing_clearance==null:
		pending_path_lamps.append(Vector2(x,z))
		return
	var h = Layout.height_at(x, z)
	if not dressing_clearance.reserve(Vector2(x,z),0.30,"lamp"): return
	_cylinder(Vector3(x, h + 1.4, z), 0.08, 2.8, mats.metal, "PathLight")
	var emitter=_box(Vector3(x, h + 2.8, z), Vector3(0.35, 0.22, 0.35), mats.amber, "WarmLamp")
	emitter.add_to_group("city_lamp_emitters")
	var light = OmniLight3D.new()
	light.position = Vector3(x, h + 2.55, z)
	light.light_color = Color("ffca8b")
	light.omni_range = 7
	light.light_energy = 1.5 if night else 0.0
	light.set_meta("night_energy",1.5)
	add_child(light)
	lamps.append(light)

func _label(value: String, at: Vector3) -> void:
	var label = Label3D.new()
	label.text = value
	label.position = at
	label.font_size = 40
	label.pixel_size = 0.025
	label.modulate = Color("d9f6e7")
	label.outline_modulate = Color("17383e")
	label.outline_size = 9
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	labels.append(label)

func _scene_bounds(node: Node3D, parent_transform: Transform3D = Transform3D.IDENTITY) -> AABB:
	var transform = parent_transform * node.transform
	var bounds = AABB()
	if node is MeshInstance3D and node.mesh:
		bounds = transform * node.get_aabb()
	for child in node.get_children():
		if child is Node3D:
			var child_bounds = _scene_bounds(child, transform)
			if child_bounds.size.length() > 0:
				bounds = child_bounds if bounds.size.length() == 0 else bounds.merge(child_bounds)
	return bounds

func _planting() -> void:
	if "--downloaded-props" not in OS.get_cmdline_user_args(): return
	for path in ["res://models/trees/tree_oak_01.glb","res://models/trees/tree_oak_02.glb","res://models/trees/tree_bamboo_01.glb"]:
		var scene=load(path) as PackedScene
		var probe=scene.instantiate() as Node3D
		tree_resources.append(scene)
		tree_bounds.append(_scene_bounds(probe))
		probe.free()
	for x in range(8,282,10):
		for z in range(8,284,10):
			var xx=x+rng.randf_range(-1,1)
			var zz=z+rng.randf_range(-1,1)
			if not Layout.clear_for_planting(xx,zz): continue
			if rng.randf() < (0.7 if x<110 else 0.3): _tree(xx,zz,rng.randf_range(6.5,10))
			else: _shrub(xx,zz)

func _tree(x: float, z: float, height: float) -> void:
	if not Layout.channel_sample(x,z).is_empty() or not Layout.Roads.sample(x,z).is_empty(): return
	if tree_resources.is_empty(): return
	if dressing_clearance==null:
		pending_trees.append(Vector3(x,z,height))
		return
	var index = rng.randi_range(0, tree_resources.size() - 1)
	var bounds = tree_bounds[index]
	var scale_factor = height / maxf(bounds.size.y, 0.1)
	var radius=Vector2(bounds.size.x,bounds.size.z).length()*0.5*scale_factor
	if not dressing_clearance.reserve(Vector2(x,z),radius,"tree"): return
	var container = Node3D.new()
	container.name = "ExistingTreeModel_%d" % wind_trees.size()
	container.position = Vector3(x, Layout.height_at(x, z), z)
	container.rotation.y = rng.randf_range(0, TAU)
	add_child(container)
	wind_trees.append(container)
	var model = tree_resources[index].instantiate() as Node3D
	model.scale *= scale_factor
	model.position = Vector3(-bounds.get_center().x, -bounds.position.y, -bounds.get_center().z) * scale_factor
	container.add_child(model)
	var body = StaticBody3D.new()
	var collider = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 0.22
	shape.height = height * 0.4
	collider.shape = shape
	collider.position.y = shape.height * 0.5
	body.add_child(collider)
	container.add_child(body)

func _shrub(x: float, z: float) -> void:
	if not Layout.channel_sample(x,z).is_empty() or not Layout.Roads.sample(x,z).is_empty(): return
	var mesh = SphereMesh.new()
	mesh.radial_segments = 8
	mesh.rings = 4
	var shrub = _mesh_node(mesh, mats.leaf, "Planting")
	wind_plants.append(shrub)
	shrub.position = Vector3(x, Layout.height_at(x, z) + 0.35, z)
	shrub.scale = Vector3(1.8, 0.9, 1.5)
	if rng.randf() < 0.4:
		for i in range(3):
			var flower = _mesh_node(mesh, mats.flower if i % 2 else mats.pink, "Flowers")
			wind_plants.append(flower)
			flower.position = shrub.position + Vector3(rng.randf_range(-0.4, 0.4), 0.4, rng.randf_range(-0.4, 0.4))
			flower.scale = Vector3.ONE * 0.2

func toggle_overview() -> void:
	if player.transit_mode: return
	if interiors and (interiors.inside or interiors.busy): return
	camera.overview = not camera.overview
	camera.masterplan = false
	camera.instant = true
	overview_button.text = "Walk camera [Tab]" if camera.overview else "Whole map [Tab]"

func toggle_masterplan() -> void:
	camera.masterplan = not camera.masterplan
	camera.overview = false
	camera.instant = true
	overview_button.text = "Whole map [Tab]"

func toggle_night() -> void:
	night = not night
	sun.light_energy = 0.25 if night else 1.35
	sun.light_color = Color("829cce") if night else Color("ffedca")
	environment.background_color = Color("344d6a") if night else Color("91aaa7")
	environment.ambient_light_color = Color("8babc8") if night else Color("a5c1c7")
	environment.ambient_light_energy = 0.42 if night else 0.65
	for light in lamps: light.light_energy = float(light.get_meta("night_energy",1.0)) if night else 0.0
	if city_lighting: city_lighting.apply_mode(night)
	if street_life: street_life.apply_mode(night)
	night_button.text = "Daylight [N]" if night else "Night lights [N]"

func visit_section(index: int) -> void:
	if player.transit_mode: return
	if interiors and (interiors.inside or interiors.busy): return
	var at=Layout.DISTRICT_VISITS[index]
	player.teleport(Vector3(at.x,Layout.height_at(at.x,at.y)+0.15,at.y))
	camera.instant=true

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if player.transit_mode and event.physical_keycode not in [KEY_ESCAPE,KEY_N]: return
	if interiors and interiors.busy: return
	if interiors and interiors.inside and event.physical_keycode not in [KEY_ESCAPE,KEY_N,KEY_R]: return
	match event.physical_keycode:
		KEY_TAB: toggle_overview()
		KEY_N: toggle_night()
		KEY_M: toggle_masterplan()
		KEY_1: visit_section(0)
		KEY_2: visit_section(1)
		KEY_3: visit_section(2)
		KEY_4: visit_section(3)
		KEY_5: visit_section(4)
		KEY_6: visit_section(5)
		KEY_7: visit_section(6)
		KEY_8: visit_section(7)
		KEY_R: player.teleport(player.last_safe); camera.instant = true
		KEY_F6:
			var points=[Vector2(139,176),Vector2(550,548),Vector2(92,165),Vector2(142,252)]
			var index=wildlife_view_index%points.size()
			var at: Vector2=points[index]
			wildlife_view_index+=1
			camera.target=player
			if index==1:
				if wildlife_focus==null:
					wildlife_focus=Node3D.new()
					add_child(wildlife_focus)
				wildlife_focus.position=Vector3(550,-2.2,548)
				camera.target=wildlife_focus
				player.teleport(Vector3(550,Layout.base_height_at(550,485)+0.15,485))
			else: player.teleport(Vector3(at.x,Layout.base_height_at(at.x,at.y)+0.15,at.y))
			camera.instant=true
		KEY_F4:
			var points=[Vector2(69,55),Vector2(139,440),Vector2(469,175),Vector2(69,678)]
			var at: Vector2=points[water_view_index%points.size()]
			water_view_index+=1
			player.teleport(Vector3(at.x,Layout.height_at(at.x,at.y)+0.15,at.y))
			camera.instant=true
		KEY_F2:
			for label in labels: label.visible = not label.visible
		KEY_ESCAPE:
			player.paused = not player.paused

func _button(value: String, parent: Node, action: Callable) -> Button:
	var button = Button.new()
	button.text = value
	button.add_theme_font_size_override("font_size", 12)
	button.custom_minimum_size.y = 38
	button.pressed.connect(action)
	button.focus_mode = Control.FOCUS_NONE
	parent.add_child(button)
	return button

func _hud() -> void:
	var layer = CanvasLayer.new()
	add_child(layer)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	layer.add_child(margin)
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.09, 0.12, 0.94)
	style.border_color = Color("47797b")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	margin.add_child(panel)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)
	var title = Label.new()
	title.text = "YUST / CAMPUS TERRAIN\nTOWN / FOREST / MARKET / RIVER"
	title.add_theme_font_size_override("font_size", 14)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color("c8ebe5"))
	row.add_child(title)
	for index in range(Layout.DISTRICT_VISITS.size()):
		_button("%d  %s" % [index + 1, ["Campus", "Tech", "Home", "Lake", "N Hill", "W Hill", "Market", "River"][index]], row, visit_section.bind(index))
	overview_button = _button("Whole map [Tab]", row, toggle_overview)
	night_button = _button("Night lights [N]", row, toggle_night)
	var help = Label.new()
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	help.position = Vector2(24, -92)
	help.text = "WASD / arrows  Walk     Shift  Run     E  Buildings     F  Skytrain     B  Bus\nRight-drag  Orbit and tilt     J/L  Orbit     I/K  Tilt     Wheel  Zoom     Home  Reset camera\n1-8  Visit area     Tab  Overview     M  Masterplan     T  Train map     V  Bus routes     R  Reset position     Esc  Pause"
	help.add_theme_color_override("font_color", Color("e7f2e5"))
	help.add_theme_color_override("font_shadow_color", Color("173039"))
	help.add_theme_constant_override("shadow_offset_x", 1)
	help.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(help)
	status = Label.new()
	status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	status.position = Vector2(-330, -50)
	status.add_theme_color_override("font_color", Color("e7f2e5"))
	layer.add_child(status)

func _process(delta: float) -> void:
	if camera and player and camera.target!=player and (not interiors or not interiors.inside) and (Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_D)):
		camera.target=player
		camera.instant=true
	elapsed += delta
	if status and player:
		var index = 0
		var nearest = INF
		for i in range(Layout.DISTRICT_VISITS.size()):
			var distance = Vector2(player.position.x,player.position.z).distance_to(Layout.DISTRICT_VISITS[i])
			if distance < nearest:
				nearest=distance
				index=i
		status.text = "%s\nGROUND %.1f m%s" % [Layout.DISTRICT_NAMES[index], player.position.y, "  |  PAUSED" if player.paused else ""]

func _capture_sequence() -> void:
	await get_tree().process_frame
	player.paused=true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://screenshots"))
	toggle_overview()
	for i in range(30): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://screenshots/terrain_with_south_river.png")
	toggle_overview()
	for index in range(8):
		visit_section(index)
		for i in range(20): await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://screenshots/district_%d.png" % index)
	player.teleport(Vector3(338,Layout.height_at(338,-145)+0.2,-145))
	camera.zoom=1.8
	camera.instant=true
	for i in range(25): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://screenshots/north_waterfall.png")
	print("CAPTURE_SAVED: town, hills and waterfall")
	await _quit_cleanly()

func _city_plot(rect: Rect2, text: String) -> void:
	building_plots.append({"plot":rect,"label":text})

func _city_quadrants() -> void:
	# Sidewalk ring gives each district an entrance and a continuous walking route.
	for x in [282,318]: _path(Rect2(x,5,4,604),"AvenueSidewalk")
	for z in [282,318]: _path(Rect2(5,z,604,4),"AvenueSidewalk")
	# Northeast: transit edge, workshop plots, raised student plaza.
	for z in [65,150,245]: _path(Rect2(314,z-3,294,6),"TechEastWestWalk")
	for x in [350,450,570]: _path(Rect2(x-3,8,6,278),"TechNorthSouthWalk")
	_path(Rect2(410,110,80,80),"StudentPlaza")
	_city_plot(Rect2(365,20,55,32),"CLINIC / STUDENT SERVICES")
	_city_plot(Rect2(475,20,65,32),"APARTMENTS")
	_city_plot(Rect2(365,80,36,48),"ELECTRONICS / REPAIR")
	_city_plot(Rect2(500,95,50,45),"ROBOT WORKSHOP")
	_city_plot(Rect2(365,175,36,45),"ARCADE / CONVENIENCE")
	_city_plot(Rect2(490,200,62,34),"SHOPS / TEA")
	_city_plot(Rect2(375,255,65,22),"TRANSIT STOP")
	# Southwest: homes rise across two broad ramped terraces.
	for z in [350,450,560]: _path(Rect2(8,z-3,278,6),"HomeCrossStreet")
	for x in [50,150,250]: _path(Rect2(x-3,314,6,294),"HomeTerraceWalk")
	_city_plot(Rect2(72,460,58,45),"FAMILY HOME / ROOFTOP CAFE")
	_city_plot(Rect2(175,460,50,40),"RESIDENTIAL COURTYARD")
	_city_plot(Rect2(72,330,55,32),"TEA / MOHINGA / GROCERY")
	_city_plot(Rect2(175,335,50,30),"LAUNDRY / LOCAL SHOPS")
	_city_plot(Rect2(68,575,60,30),"APARTMENTS")
	_city_plot(Rect2(175,575,52,30),"COMMUNITY GARDEN")
	# Southeast: level market edge, gently descending waterfront.
	for z in [350,400]: _path(Rect2(314,z-3,294,6),"MarketWalk")
	_path(Rect2(345,314,6,294),"LakesideEntryWalk")
	_path(Rect2(430,350,6,258),"LakesideRamp")
	_path(Rect2(345,490,130,5),"ParkConnector")
	_city_plot(Rect2(365,330,42,20),"EVENING FOOD STRIP")
	_city_plot(Rect2(475,330,60,45),"SPORTS COURT")
	_city_plot(Rect2(470,420,48,30),"PICNIC LAWN")
	_city_plot(Rect2(365,525,48,38),"COMMUNITY GARDEN")
	var pond=CylinderMesh.new()
	pond.top_radius=1; pond.bottom_radius=1; pond.height=0.04; pond.radial_segments=80
	var water=_mesh_node(pond,mats.water,"DistrictLake")
	water.position=Vector3(550,-2.25,548); water.scale=Vector3(49,1,46)
	# A continuous raised boardwalk surrounds the water with access from the west.
	for z in [497,597]: _box(Vector3(550,-2.15,z),Vector3(108,0.3,4),mats.wood,"LakeBoardwalk",true)
	for x in [498,602]: _box(Vector3(x,-2.15,547),Vector3(4,0.3,104),mats.wood,"LakeBoardwalk",true)
	_path(Rect2(430,595,68,4),"BoardwalkApproach")
	# Sparse plot-aware planting and warm lights; buildings remain reserved footprints.
	for area in [Rect2(314,0,300,280),Rect2(0,314,280,300),Rect2(314,314,300,300)]:
		for x in range(int(area.position.x)+12,int(area.end.x)-8,22):
			for z in range(int(area.position.y)+12,int(area.end.y)-8,22):
				if x>470 and z>410: continue
				# Plant only perimeter bands so no plot or primary route is obstructed.
				if x>area.position.x+25 and x<area.end.x-25 and z>area.position.y+25 and z<area.end.y-25: continue
				if absf(z-350)<8 or absf(z-450)<8 or absf(z-560)<8 or absf(x-350)<8 or absf(x-570)<8: continue
				_tree(x,z,rng.randf_range(6,9))
	for at in [Vector2(450,150),Vector2(150,450),Vector2(430,460)]:
		for offset in [-9,9]:
			_lamp(at.x+offset,at.y)
			_bench(at.x+offset,at.y+6)

func _hill_trail(route: Array) -> void:
	var bounds=Rect2(route[0],Vector2.ZERO)
	for point in route: bounds=bounds.expand(point)
	grass_routes.append({"rect":bounds.grow(2.4),"route":route})
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(route.size()-1):
		var a: Vector2=route[i]
		var b: Vector2=route[i+1]
		var steps=ceili(a.distance_to(b))
		var side=Vector2(-(b-a).y,(b-a).x).normalized()*1.7
		for j in range(steps):
			var c=a.lerp(b,float(j)/steps)
			var d=a.lerp(b,float(j+1)/steps)
			var points=[c-side,c+side,d-side,d+side]
			var verts=[]
			for p in points: verts.append(Vector3(p.x,Layout.base_height_at(p.x,p.y)+0.06,p.y))
			# Flip where needed so all trail triangles face upward.
			for indices in [[0,1,2],[1,3,2]]:
				var u: Vector3=verts[indices[0]]
				var v: Vector3=verts[indices[1]]
				var w: Vector3=verts[indices[2]]
				if (v-u).cross(w-u).y>0:
					st.add_vertex(u);st.add_vertex(w);st.add_vertex(v)
				else:
					st.add_vertex(u);st.add_vertex(v);st.add_vertex(w)
	st.generate_normals()
	_mesh_node(st.commit(),mats.trail,"ForestDirtTrail")
	for point in route:
		var fan=SurfaceTool.new()
		fan.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(16):
			var a=point+Vector2(cos(TAU*i/16),sin(TAU*i/16))*1.72
			var b=point+Vector2(cos(TAU*(i+1)/16),sin(TAU*(i+1)/16))*1.72
			for v in [point,a,b]: fan.add_vertex(Vector3(v.x,Layout.base_height_at(v.x,v.y)+0.065,v.y))
		fan.generate_normals()
		_mesh_node(fan.commit(),mats.trail,"TrailCorner")

func _natural_hills() -> void:
	mats.trail=_mat("75694e")
	mats.moss=_mat("526a43")
	_surface(Layout.NORTH_HILLS,mats.grass,"NorthHillTerrain",true,Layout.height_at,2)
	_surface(Layout.WEST_HILLS,mats.grass,"WestHillTerrain",true,Layout.height_at,2)
	_hill_trail(Layout.NORTH_TRAIL)
	_hill_trail(Layout.WEST_TRAIL)
	# Source stream, rocky waterfall chute and lower cascading creek form one flow.
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(-299,-31):
		var width=6.5+13.0*maxf(0.0,1.0-absf(z+219)/10.0)
		var next_width=6.5+13.0*maxf(0.0,1.0-absf(z+220)/10.0)
		var a=Vector3(Layout.north_stream_x(z)-width/2,Layout.north_water_y(z),z)
		var b=a+Vector3(width,0,0)
		var c=Vector3(Layout.north_stream_x(z+1)-next_width/2,Layout.north_water_y(z+1),z+1)
		var d=c+Vector3(next_width,0,0)
		for point in [a,b,c,b,d,c]:
			var span=width if point.z==z else next_width
			st.set_uv(Vector2((point.x-Layout.north_stream_x(point.z))/span+0.5,point.z))
			st.add_vertex(point)
	st.generate_normals()
	_mesh_node(st.commit(),mats.water,"WaterfallAndCreek")
	var pool_mesh=CylinderMesh.new()
	pool_mesh.top_radius=1;pool_mesh.bottom_radius=1;pool_mesh.height=0.04;pool_mesh.radial_segments=48
	var pool=_mesh_node(pool_mesh,mats.water,"LowerForestPool")
	pool.position=Vector3(Layout.north_stream_x(-36),4.2,-36)
	pool.scale=Vector3(13,1,9)

	rng.seed=813279
	# Clustered vegetation: wet gullies are fern/shrub-rich, ridges have open rock gaps.
	for parcel in [Layout.NORTH_HILLS,Layout.WEST_HILLS]:
		for x in range(int(parcel.position.x)+5,int(parcel.end.x)-4,11):
			for z in range(int(parcel.position.y)+5,int(parcel.end.y)-4,11):
				var xx=x+rng.randf_range(-3,3)
				var zz=z+rng.randf_range(-3,3)
				var route=Layout.NORTH_TRAIL if zz<0 else Layout.WEST_TRAIL
				if Layout.trail_distance(Vector2(xx,zz),route)<6 or Layout.trail_distance(Vector2(xx,zz),Layout.MARKET_TRAIL)<6: continue
				if zz<0 and absf(xx-Layout.north_stream_x(zz))<12: continue
				var cluster=sin(xx*0.026+sin(zz*0.018))*cos(zz*0.031)
				if cluster> -0.15 and rng.randf()<0.7:
					_tree(xx,zz,rng.randf_range(7,14))
				elif rng.randf()<0.45: _shrub(xx,zz)
		# Buried rock outcrops and occasional fallen wood; keep walking corridors clear.
		for i in range(115):
			var x=rng.randf_range(parcel.position.x+5,parcel.end.x-5)
			var z=rng.randf_range(parcel.position.y+5,parcel.end.y-5)
			var route=Layout.NORTH_TRAIL if z<0 else Layout.WEST_TRAIL
			if Layout.trail_distance(Vector2(x,z),route)<6 or Layout.trail_distance(Vector2(x,z),Layout.MARKET_TRAIL)<6: continue
			var rock_scale=Vector3(rng.randf_range(2,6),rng.randf_range(1.5,4),rng.randf_range(2,5))
			var turn=rng.randf_range(0,TAU)
			var log_turn=rng.randf_range(0,TAU) if i%15==0 else 0.0
			if not Layout.Roads.has_clearance(Vector2(x,z),maxf(rock_scale.x,rock_scale.z)*0.5): continue
			var rock_mesh=SphereMesh.new()
			rock_mesh.radial_segments=7;rock_mesh.rings=4
			var rock=_mesh_node(rock_mesh,mats.moss if i%3==0 else mats.rock,"BuriedHillRock")
			rock.position=Vector3(x,Layout.height_at(x,z)-0.2,z)
			rock.scale=rock_scale
			rock.rotation.y=turn
			if i%15==0:
				var log=_cylinder(Vector3(x,Layout.height_at(x,z)+0.3,z),0.4,5,mats.dark_wood,"FallenForestLog")
				log.rotation=Vector3(0,log_turn,PI/2)
	# Small resting points at trail ends; forest has no grid of lamps.
	for at in [Vector2(320,-180),Vector2(-60,445)]:
		_bench(at.x,at.y)
	_label("NORTH HILLS / 500 x 300 m",Vector3(140,Layout.height_at(140,-90)+2,-90))
	_label("WEST HILLS / 300 x 500 m",Vector3(-115,Layout.height_at(-115,270)+2,270))

func _expanded_district_terrain() -> void:
	# Northern plateau and access route around the east edge of the forest.
	_surface(Rect2(0,-700,614,400),mats.grass,"NorthernMarketPlateau",true,Layout.height_at,2)
	_surface(Rect2(500,-300,114,300),mats.grass,"ForestEastAccessSlope",true,Layout.height_at,2)

	_surface(Rect2(590,-700,5,700),mats.paving,"MarketAccessFootway",false,func(x: float,z: float)->float: return Layout.height_at(x,z)+0.08,2)
	for z in [-670,-410]: _path(Rect2(20,z-4,575,8),"MarketCrossStreet")
	for x in [75,300,535]: _path(Rect2(x-4,-670,8,310),"MarketShoppingSpine")
	_path(Rect2(175,-610,250,175),"MarketPedestrianCore")
	_path(Rect2(245,-405,110,45),"MarketArrivalPlaza")
	_path(Rect2(300,-380,290,6),"MarketTransitConnector")
	_city_plot(Rect2(195,-590,95,55),"PRODUCE / EVERYDAY MARKET")
	_city_plot(Rect2(310,-590,95,55),"CLOTHING / CRAFTS")
	_city_plot(Rect2(195,-515,95,55),"FOOD QUARTER / TEA")
	_city_plot(Rect2(310,-515,95,55),"TECH / ROBOT PARTS")
	_city_plot(Rect2(95,-645,150,35),"WHOLESALE / COLD STORAGE")
	_city_plot(Rect2(345,-645,150,35),"DELIVERY / RECYCLING")
	_city_plot(Rect2(460,-405,90,28),"BUS / TRAM ARRIVAL")
	_city_plot(Rect2(100,-405,90,28),"BIKE PARKING / INFO")
	_city_plot(Rect2(95,-545,55,65),"CRAFT / BOOK LANES")
	_city_plot(Rect2(450,-545,55,65),"CAFES / COMMUNITY")
	# Wide planted buffer preserves the forest edge, with one winding foot connection.
	_hill_trail(Layout.MARKET_TRAIL)
	# Shallow market rain gardens sit outside the shopping core.
	for x in [40,565]:
		_box(Vector3(x,18.13,-520),Vector3(9,0.26,95),mats.concrete,"MarketRainGardenEdge")
		_box(Vector3(x,18.28,-520),Vector3(7.8,0.04,93),mats.water,"MarketDrainageBasin")
	for x in [75,300,535]:
		for z in [-670,-410]:
			_lamp(x-8,z);_lamp(x+8,z)
	# Southwest: local gathering courtyards between the existing home terraces.
	_path(Rect2(72,427,56,18),"NeighbourhoodCourtyard")
	_path(Rect2(175,427,50,18),"PlaygroundCourtyard")
	_city_plot(Rect2(180,430,18,10),"PLAYGROUND")
	_path(Rect2(72,530,56,25),"UpperResidentialGarden")
	for at in [Vector2(80,440),Vector2(120,440),Vector2(185,440),Vector2(215,440),Vector2(90,548)]:
		_bench(at.x,at.y)
		_lamp(at.x,at.y+2)
	# Southeast: complete a winding lakeside loop, with lawns and a small food strip.
	var loop=[]
	for i in range(49):
		var angle=TAU*i/48
		loop.append(Vector2(550+55*cos(angle),548+53*sin(angle)))
	_hill_trail(loop)
	_hill_trail([Vector2(430,490),Vector2(460,490),Vector2(480,510),Vector2(495,548)])
	_hill_trail([Vector2(430,595),Vector2(470,600),Vector2(510,595)])
	_city_plot(Rect2(455,460,28,18),"LAKESIDE CAFE / RAIN SHELTER")
	for i in range(36):
		var angle=TAU*i/36
		var at=Vector2(550+50*cos(angle),548+47*sin(angle))
		# Shore planting stays inside the walking loop.
		_shrub(at.x,at.y)
	for at in [Vector2(485,525),Vector2(550,485),Vector2(550,608)]:
		_bench(at.x,at.y)
	# Soft buffer planting around market boundaries, away from circulation lanes.
	rng.seed=829014
	for x in range(12,580,17):
		for z in [-690,-350]:
			if absf(x-300)<12: continue
			_tree(x,z,rng.randf_range(7,11))
	for z in range(-650,-420,20):
		_tree(16,z,rng.randf_range(7,10))
		_tree(580,z,rng.randf_range(7,10))
	_label("NORTHERN MARKET / 600 x 400 m",Vector3(300,20,-390))

func _south_river() -> void:
	# The river runs west/east across the complete 914 m width of the world.
	_surface(Layout.RIVER_RECT,mats.grass,"SouthRiverBanksAndBed",true,Layout.height_at,2)
	_surface(Rect2(-300,500,300,114),mats.grass,"WestHillRiverTransition",true,Layout.height_at,2)
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(-300,614,2):
		var xx=minf(x+2,614)
		var north=Layout.river_water_edge(x,true)-0.12
		var south=Layout.river_water_edge(x,false)+0.12
		var next_north=Layout.river_water_edge(xx,true)-0.12
		var next_south=Layout.river_water_edge(xx,false)+0.12
		for j in range(36):
			var t=float(j)/36
			var tt=float(j+1)/36
			var a=Vector3(x,Layout.RIVER_WATER_Y,lerpf(north,south,t))
			var b=Vector3(xx,Layout.RIVER_WATER_Y,lerpf(next_north,next_south,t))
			var c=Vector3(x,Layout.RIVER_WATER_Y,lerpf(north,south,tt))
			var d=Vector3(xx,Layout.RIVER_WATER_Y,lerpf(next_north,next_south,tt))
			for v in [a,b,c,b,d,c]:
				var across=(v.z-(north if v.x==x else next_north))/((south-north) if v.x==x else (next_south-next_north))
				var anchor=smoothstep(0,0.12,across)*(1-smoothstep(0.88,1,across))
				st.set_color(Color(anchor,1,1,1))
				st.set_uv(Vector2(v.x/18.0,across))
				st.add_vertex(v)

	st.generate_normals()
	var river=_mesh_node(st.commit(),mats.water,"ContinuousSouthRiver")
	_river_stones(river.material_override)
	# Lower motor road and separate river-edge bicycle / walking paths.


	var cycle=[]
	var foot=[]
	for x in range(-290,611,5):
		cycle.append(Vector2(x,Layout.river_north_bank(x)-11))
		foot.append(Vector2(x,Layout.river_north_bank(x)-5))
	var dirt=mats.trail
	mats.trail=_mat("426e76")
	_hill_trail(cycle)
	mats.trail=mats.paving
	_hill_trail(foot)
	mats.trail=dirt
	for x in range(-280,605,15):
		_box(Vector3(x,0.15,Layout.river_north_bank(x)-11),Vector3(4,0.02,0.12),mats.paint,"CycleCentreStripe")
	# Main retaining wall separates the raised town from the lower waterfront street.
	for x in range(-300,614,2):
		var gap=false
		for cx in [-30,150,520]:
			if absf(x-cx)<5: gap=true
		for cx in [-90,460]:
			if absf(x-cx)<7: gap=true
		if not gap: _box(Vector3(x+1,5,645.04),Vector3(2,10,0.3),mats.concrete,"RiverTownRetainingWall")
	for cx in [-30.0,150.0,520.0]:
		for i in range(5):
			downloaded_props.stair(cx,650-(i+0.5)*5.2,7,5.2,2,i*2.0)

	# Sparse maintenance ladders; these are props, climbing mechanics are still pending.
	for x in [70,250,570]:
		for offset in [-0.4,0.4]:
			_bar(Vector3(x+offset,0.3,645.5),Vector3(x+offset,10.8,645.5),0.045,mats.metal)
		for i in range(34):
			_bar(Vector3(x-0.4,0.4+i*0.3,645.55),Vector3(x+0.4,0.4+i*0.3,645.55),0.035,mats.metal)
	for route in [
		[Vector2(150,560),Vector2(150,610),Vector2(150,624)],
		[Vector2(430,595),Vector2(470,620),Vector2(520,624)],
		[Vector2(-60,445),Vector2(-60,500),Vector2(-60,570),Vector2(-30,624)]
	]: _hill_trail(route)
	for x in [-180,200,450]:
		var z=Layout.river_north_bank(x)-20
		_bench(x,z);_lamp(x+4,z)
	_label("LOWER WATERFRONT / CYCLE PATH",Vector3(200,2,670))
	_label("UPPER TOWN +10 m",Vector3(200,11,630))

func _grass_capture() -> void:
	player.paused=true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://screenshots"))
	for at in [Vector2(140,249),Vector2(150,-40)]:
		player.teleport(Vector3(at.x,Layout.height_at(at.x,at.y)+0.05,at.y))
		camera.instant=true
		for i in range(90): await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://screenshots/grass_%s_day.png" % ("campus" if at.y>0 else "hills"))
	player.teleport(Vector3(140,Layout.height_at(140,249)+0.05,249))
	camera.instant=true
	toggle_night()
	for i in range(90): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://screenshots/grass_campus_night.png")
	print("GRASS_CAPTURE_COMPLETE chunks=",grass_system.chunks.size())
	await _quit_cleanly()

func _water_capture() -> void:
	player.paused=true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://screenshots"))
	for entry in [{"at":Vector2(65,55),"name":"campus"},{"at":Vector2(135,440),"name":"homes"},{"at":Vector2(465,175),"name":"tech"},{"at":Vector2(65,678),"name":"outfall"}]:
		var at: Vector2=entry.at
		player.teleport(Vector3(at.x+4,Layout.height_at(at.x+4,at.y)+0.2,at.y))
		camera.instant=true
		for i in range(100): await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://screenshots/water_network_%s.png" % entry.name)
	print("WATER_NETWORK_CAPTURE_COMPLETE")
	await _quit_cleanly()

func _build_connected_roads() -> void:
	var roads=load("res://scripts/road_layout.gd")
	for edge in roads.EDGES:
		var a: Vector3=roads.NODES[edge[0]]
		var b: Vector3=roads.NODES[edge[1]]
		var width=roads.width(edge)
		var mountain=roads.is_mountain(edge)
		var flat=Vector2(b.x-a.x,b.z-a.z)
		var count=ceili(flat.length()/2)
		var side=Vector3(-flat.y,0,flat.x).normalized()
		var st=SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(count):
			var p=roads.point(a,b,float(i)/count,mountain)+Vector3.UP*0.1
			var q=roads.point(a,b,float(i+1)/count,mountain)+Vector3.UP*0.1
			var vertices=[p-side*width*0.5,p+side*width*0.5,q-side*width*0.5,q+side*width*0.5]
			for j in [0,2,1,1,2,3]: st.add_vertex(vertices[j])
			if i%6==2:
				var stripe=_box((p+q)*0.5+Vector3.UP*0.02,Vector3(0.12,0.02,p.distance_to(q)),mats.paint,"RoadCentreStripe")
				stripe.rotation.y=atan2(q.x-p.x,q.z-p.z)
			if mountain and i%8==4 and i>4 and i<count-5:
				for direction in [-1,1]:
					var edge_position=p+side*direction*(width*0.5+0.36)
					_box(edge_position+Vector3.UP*0.45,Vector3(0.16,0.9,0.16),mats.metal,"MountainRoadDelineator")
					_box(edge_position+Vector3.UP*0.76,Vector3(0.18,0.12,0.18),mats.paint,"MountainRoadReflector")
			if mountain and i>2 and i<count-3 and i%2==0:
				var road_step=roads.point(a,b,minf(float(i+2)/count,1.0),true)+Vector3.UP*0.12
				for direction in [-1,1]:
					var shift=side*direction*(width*0.5-0.26)
					_bar(p+shift+Vector3.UP*0.025,road_step+shift,0.045,mats.paint)
			if i%15==0 and p.y-Layout.natural_height_at(p.x,p.z)>2:
				# Slender support piers keep the existing lower paths and lake bank open.
				var ground=Layout.natural_height_at(p.x,p.z)
				_cylinder(Vector3(p.x,(p.y+ground)*0.5,p.z),0.25,p.y-ground,mats.concrete,"RoadSupport")
		st.generate_normals()
		_mesh_node(st.commit(),mats.road,"MountainVehicleRoad" if mountain else "ConnectedVehicleRoad",true)
		var rect=Rect2(Vector2(a.x,a.z),Vector2.ZERO).expand(Vector2(b.x,b.z)).grow(width*0.5+0.3)
		grass_exclusions.append(rect)
	# Flush junctions are explicit collision surfaces shared by all incident edges.
	for key in roads.NODES:
		var p: Vector3=roads.NODES[key]
		var main=key in ["n","c","s","w","e"]
		if key.begins_with("hill_"):
			var junction=CylinderMesh.new()
			junction.top_radius=4.02
			junction.bottom_radius=4.02
			junction.height=0.20
			junction.radial_segments=24
			_mesh_node(junction,mats.road,"MountainRoadJunction",true).position=p
		else:
			_box(p+Vector3.UP*0.01,Vector3(18 if main else 8,0.18,18 if main else 8),mats.road,"RoadJunction",true)

func _props_capture() -> void:
	player.paused=true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://screenshots"))
	for entry in [{"name":"stairs","at":Vector2(150,88)},{"name":"bridge","at":Vector2(66,156)},{"name":"bench","at":Vector2(159,70)},{"name":"swing","at":Vector2(190,441)},{"name":"waterfront_stairs","at":Vector2(150,650)}]:
		var at: Vector2=entry.at
		player.teleport(Vector3(at.x,Layout.height_at(at.x,at.y)+0.15,at.y))
		camera.instant=true
		for i in range(100): await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://screenshots/downloaded_%s.png" % entry.name)
	print("DOWNLOADED_PROPS_COUNTS ",downloaded_props.counts)
	await _quit_cleanly()

func _inside_stair(x: float,z: float) -> bool:
	for cx in Layout.CENTRES:
		if absf(x-cx)<4 and (absf(z-80)<4 or absf(z-210)<4): return true
	for cx in [-30.0,150.0,520.0]:
		if absf(x-cx)<3.5 and z>=624 and z<=650: return true
	return false

func _calm_water_capture() -> void:
	player.paused=true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://screenshots"))
	for entry in [{"name":"channel","at":Vector2(70,55)},{"name":"lake","at":Vector2(495,548)},{"name":"river","at":Vector2(200,690)},{"name":"creek","at":Vector2(340,-145)}]:
		var at: Vector2=entry.at
		player.teleport(Vector3(at.x,Layout.base_height_at(at.x,at.y)+0.2,at.y))
		camera.instant=true
		for i in range(100): await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://screenshots/calm_water_%s.png" % entry.name)
	print("CALM_WATER_CAPTURE_COMPLETE")
	await _quit_cleanly()

func _wildlife_capture() -> void:
	player.paused=true
	camera.zoom=0.6
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://screenshots"))
	for entry in [{"name":"cat","at":Vector2(139,176)},{"name":"ducks","at":Vector2(550,548)},{"name":"birds","at":Vector2(92,165)},{"name":"butterflies","at":Vector2(142,252)}]:
		if "--duck-only" in OS.get_cmdline_user_args() and entry.name!="ducks": continue
		var at: Vector2=entry.at
		camera.target=player
		if entry.name=="ducks":
			if wildlife_focus==null:
				wildlife_focus=Node3D.new()
				add_child(wildlife_focus)
			wildlife_focus.position=Vector3(550,-2.2,548)
			camera.target=wildlife_focus
			player.teleport(Vector3(550,Layout.base_height_at(550,485)+0.15,485))
		else: player.teleport(Vector3(at.x,Layout.base_height_at(at.x,at.y)+0.15,at.y))
		camera.instant=true
		for i in range(100): await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://screenshots/wildlife_%s.png" % entry.name)
	print("WILDLIFE_CAPTURE_COMPLETE ",wildlife.counts)
	await _quit_cleanly()

func _wave_disk() -> ArrayMesh:
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring in range(24):
		for segment in range(96):
			var r=float(ring)/24
			var rr=float(ring+1)/24
			var a=TAU*segment/96
			var b=TAU*(segment+1)/96
			var points=[Vector3(cos(a)*r,0,sin(a)*r),Vector3(cos(b)*r,0,sin(b)*r),Vector3(cos(a)*rr,0,sin(a)*rr),Vector3(cos(b)*rr,0,sin(b)*rr)]
			for i in [0,2,1,1,2,3]:
				var v=points[i]
				st.set_color(Color(1-smoothstep(0.82,1,v.length()),1,1,1))
				st.set_normal(Vector3.UP)
				st.set_uv(Vector2(v.x,v.z)*0.5+Vector2.ONE*0.5)
				st.add_vertex(v)
	return st.commit()

func _river_stones(material: ShaderMaterial) -> void:
	var obstacles: Array[Vector4]=[]
	var stone_material=_mat("8a9c9e",0.9)
	for i in range(12):
		var x=-260.0+i*75.0
		var north=Layout.river_water_edge(x,true)
		var south=Layout.river_water_edge(x,false)
		var z=north+5+i%3 if i%2==0 else south-5-i%3
		var radius=1.0+(i%3)*0.35
		var mesh=SphereMesh.new()
		mesh.radius=1.0
		mesh.height=2.0
		mesh.radial_segments=16
		mesh.rings=8
		var rock=_mesh_node(mesh,stone_material,"RiverStone")
		rock.add_to_group("stylized_river_stones")
		rock.position=Vector3(x,Layout.RIVER_WATER_Y+0.10,z)
		rock.scale=Vector3(radius*1.5,radius*0.55,radius)
		obstacles.append(Vector4(x,z,radius,1.0))
	material.set_shader_parameter("river_rocks",obstacles)

func _quit_cleanly() -> void:
	if quitting: return
	quitting=true
	if breeze and DisplayServer.get_name()!="headless":
		breeze.release_visuals()
		for i in range(3):
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
	get_tree().quit()

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST: _quit_cleanly()

func _breeze_capture() -> void:
	player.paused=true
	camera.zoom=0.6
	get_window().size=Vector2i(960,600)
	for child in get_children():
		if child is CanvasLayer: child.visible=false
	player.teleport(Vector3(460,Layout.height_at(460,115)+0.15,115))
	camera.instant=true
	for i in range(100): await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://screenshots/breeze_frames"))
	for i in range(32):
		await get_tree().create_timer(0.125).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://screenshots/breeze_frames/frame_%03d.png" % i)
	print("BREEZE_MOTION_CAPTURE_COMPLETE")
	await _quit_cleanly()

func _street_capture() -> void:
	player.paused=true
	get_window().size=Vector2i(1440,900)
	for child in get_children():
		if child is CanvasLayer: child.visible=false
	var views=[["campus_entrance",Vector2(126,266),1.0],["tech_street",Vector2(375,150),0.8],["tea_street",Vector2(110,364),0.9],["tech_wide",Vector2(450,170),1.8],["market_hall",Vector2(300,-392),1.8],["market_hall2",Vector2(200,-498),1.8],["campus_wide",Vector2(150,150),1.8]]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://screenshots"))
	if street_life and street_life.cyber:
		var picks=street_life.cyber.infill_rects
		for i in [0,int(picks.size()/2),picks.size()-1]:
			if i>=0 and i<picks.size():
				var c: Vector2=picks[i].get_center()
				views.append(["cyber_infill_%d"%i,c+Vector2(0,16),1.5])
	for view in views:
		player.teleport(Vector3(view[1].x,Layout.height_at(view[1].x,view[1].y)+0.15,view[1].y))
		camera.zoom=view[2]
		camera.instant=true
		for i in range(90): await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://screenshots/street_life_%s.png" % view[0])
	print("STREET_CAPTURE_COMPLETE")
	await _quit_cleanly()
