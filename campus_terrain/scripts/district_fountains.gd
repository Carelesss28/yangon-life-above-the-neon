extends RefCounted

const Layout=preload("res://scripts/terrain_layout.gd")
const FountainShader=preload("res://shaders/fountain_water.gdshader")
const SITES=[
	["CampusQuad",Vector2(736,688),3.6,8],
	["CentralPark",Vector2(334.51,440),3.2,7],
	["HomeCourtyard",Vector2(105.63,520),2.7,6],
	["SeafrontPlaza",Vector2(429.58,222),2.6,6],
]
var world
var root: Node3D
var stone: Material
var edge: Material
var water: ShaderMaterial
var jets: ShaderMaterial

func setup(owner_world) -> void:
	world=owner_world
	root=Node3D.new()
	root.name="DistrictFountains"
	world.add_child(root)
	stone=world._mat("7e9798")
	edge=world._mat("c4d9d7")
	water=ShaderMaterial.new()
	water.shader=FountainShader
	jets=water.duplicate()
	jets.set_shader_parameter("stream",true)
	for site in SITES:
		if world.dressing_clearance.reserve(site[1],site[2]+0.7,"fountain"):
			_build(site[0],site[1],site[2],site[3])
	print("DISTRICT_FOUNTAINS_READY ",root.get_child_count())

func _build(title: String,center: Vector2,radius: float,jet_count: int) -> void:
	var fountain=Node3D.new()
	fountain.name=title
	fountain.position=Vector3(center.x,Layout.height_at(center.x,center.y)+0.12,center.y)
	root.add_child(fountain)
	var low=0.0
	for i in range(12):
		var point=center+Vector2.from_angle(TAU*i/12)*radius
		low=minf(low,Layout.height_at(point.x,point.y)-fountain.position.y)
	_disk(fountain,Vector3.UP*(low*0.5+0.12),radius,0.7-low,stone,"BasinFoundation",true)
	_ring(fountain,radius,0.28,0.52,0.77,edge)
	var surface=_mesh(fountain,world._wave_disk(),water,Vector3.UP*0.52,"RippledWater")
	surface.scale=Vector3(radius-0.24,1,radius-0.24)
	var pedestal=radius*0.18
	_disk(fountain,Vector3.UP*0.63,pedestal*1.35,0.23,edge,"JetPedestal")
	_disk(fountain,Vector3.UP*0.82,pedestal*0.75,0.23,world.mats.metal,"NozzleManifold")

	var arcs=SurfaceTool.new()
	arcs.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(jet_count):
		var heading=Vector2.from_angle(TAU*i/jet_count)
		var direction=Vector3(heading.x,0,heading.y)
		var nozzle=direction*pedestal*0.64+Vector3.UP*0.93
		_disk(fountain,nozzle,0.055,0.08,world.mats.metal,"Nozzle")
		_jet_arc(arcs,nozzle,direction,radius*0.69,1.15+radius*0.15,float(i)/jet_count)
	_jet_arc(arcs,Vector3.UP*0.94,Vector3.FORWARD,radius*0.24,1.75+radius*0.15,0.1)
	arcs.generate_normals()
	_mesh(fountain,arcs.commit(),jets,Vector3.ZERO,"FlowingWaterJets")
	var light=OmniLight3D.new()
	light.position=Vector3(0,0.62,0)
	light.light_color=Color("86ddea")
	light.omni_range=radius*1.4
	light.light_energy=0.75 if world.night else 0.0
	light.set_meta("night_energy",0.75)
	fountain.add_child(light)
	world.lamps.append(light)
	world.grass_exclusions.append(Rect2(center-Vector2.ONE*radius,Vector2.ONE*radius*2))

func _disk(parent: Node3D,at: Vector3,radius: float,height: float,material: Material,title: String,solid=false) -> void:
	var disk=CylinderMesh.new()
	disk.top_radius=radius
	disk.bottom_radius=radius
	disk.height=height
	disk.radial_segments=32
	var piece=_mesh(parent,disk,material,at,title)
	if solid:
		var body=StaticBody3D.new()
		piece.add_child(body)
		var collider=CollisionShape3D.new()
		var shape=CylinderShape3D.new()
		shape.radius=radius
		shape.height=height
		collider.shape=shape
		body.add_child(collider)

func _ring(parent: Node3D,radius: float,width: float,bottom: float,top: float,material: Material) -> void:
	var surface=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(36):
		var a=Vector2.from_angle(TAU*i/36)
		var b=Vector2.from_angle(TAU*(i+1)/36)
		var outer_a=Vector3(a.x*radius,top,a.y*radius)
		var outer_b=Vector3(b.x*radius,top,b.y*radius)
		var inner_a=Vector3(a.x*(radius-width),top,a.y*(radius-width))
		var inner_b=Vector3(b.x*(radius-width),top,b.y*(radius-width))
		var step=Vector3.UP*(top-bottom)
		for v in [outer_a,outer_b,inner_a,inner_a,outer_b,inner_b,
				outer_a,outer_a-step,outer_b,outer_b,outer_a-step,outer_b-step,
				inner_b,inner_a-step,inner_a,inner_b-step,inner_a-step,inner_b]:
			surface.add_vertex(v)
	surface.generate_normals()
	_mesh(parent,surface.commit(),material,Vector3.ZERO,"BasinCoping")

func _jet_arc(surface: SurfaceTool,start: Vector3,heading: Vector3,distance: float,peak: float,offset: float) -> void:
	var side=heading.cross(Vector3.UP).normalized()
	for i in range(22):
		var t=float(i)/22.0
		var next=float(i+1)/22.0
		var a=start+heading*distance*t+Vector3.UP*(-(start.y-0.52)*t+4.0*peak*t*(1.0-t))
		var b=start+heading*distance*next+Vector3.UP*(-(start.y-0.52)*next+4.0*peak*next*(1.0-next))
		var across=side*lerpf(0.054,0.028,t)
		var upright=(b-a).normalized().cross(side)*lerpf(0.054,0.028,t)
		for wing in [across,upright]:
			var points=[a-wing,a+wing,b-wing,b+wing]
			for vertex in [0,1,2,1,3,2]:
				surface.set_uv(Vector2(t if vertex<2 else next,offset))
				surface.add_vertex(points[vertex])

func _mesh(parent: Node3D,mesh: Mesh,material: Material,at: Vector3,title: String) -> MeshInstance3D:
	var instance=MeshInstance3D.new()
	instance.name=title
	instance.mesh=mesh
	instance.material_override=material
	instance.position=at
	if material in [jets,water]: instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance
