extends Node3D
var world
var trees_animated=0
var plants_animated=0
var leaves: CPUParticles3D
var clock=0.0
var previous=Vector3.INF
var sound: AudioStreamPlayer
var bindings: Array=[]
var live_materials: Array=[]

func _ready() -> void:
	name="TownBreeze"
	for tree in world.wind_trees:
		var bounds=world._scene_bounds(tree)
		for mesh in tree.find_children("*","MeshInstance3D",true,false):
			_deform(mesh,tree.position.y,maxf(bounds.size.y,1),0.20)
		trees_animated+=1
	for shrub in world.wind_plants:
		_deform(shrub,shrub.position.y-0.35,0.9,0.055)
		plants_animated+=1
	_leaves()
	for at in [Vector2(135,118),Vector2(450,108),Vector2(320,-390)]: _banner(at)
	if DisplayServer.get_name()!="headless": _wind_audio()
	print("BREEZE_READY trees=",trees_animated," shrubs=",plants_animated)

func _deform(mesh: MeshInstance3D,root: float,height: float,amount: float) -> void:
	for i in range(mesh.mesh.get_surface_count()):
		var original=mesh.get_active_material(i)
		if not original is StandardMaterial3D: continue
		var material=ShaderMaterial.new()
		material.shader=load("res://shaders/foliage_breeze.gdshader")
		material.set_shader_parameter("base_colour",original.albedo_color)
		if original.albedo_texture: material.set_shader_parameter("base_texture",original.albedo_texture)
		material.set_shader_parameter("vertex_tint",original.vertex_color_use_as_albedo)
		material.set_shader_parameter("root_y",root)
		material.set_shader_parameter("plant_height",height)
		material.set_shader_parameter("sway_amount",amount)
		bindings.append({"mesh":mesh,"surface":i,"original":original})
		live_materials.append(material)
		mesh.set_surface_override_material(i,material)

func _leaves() -> void:
	leaves=CPUParticles3D.new()
	leaves.name="DriftingLeaves"
	leaves.amount=30
	leaves.lifetime=14
	leaves.preprocess=3
	leaves.local_coords=false
	leaves.emission_shape=CPUParticles3D.EMISSION_SHAPE_BOX
	leaves.emission_box_extents=Vector3(24,4,20)
	leaves.direction=Vector3(0.91,-0.08,0.41)
	leaves.spread=18
	leaves.initial_velocity_min=0.65
	leaves.initial_velocity_max=1.3
	leaves.gravity=Vector3(0,-0.045,0)
	leaves.scale_amount_min=0.6
	leaves.scale_amount_max=1.1
	leaves.angle_min=-180
	leaves.angle_max=180
	leaves.angular_velocity_min=-45
	leaves.angular_velocity_max=45
	var mesh=QuadMesh.new()
	mesh.size=Vector2(0.12,0.055)
	leaves.mesh=mesh
	var material=StandardMaterial3D.new()
	material.albedo_color=Color("9a945a")
	material.roughness=0.95
	material.billboard_mode=BaseMaterial3D.BILLBOARD_PARTICLES
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	leaves.material_override=material
	leaves.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(leaves)

func _banner(at: Vector2) -> void:
	var h=world.Layout.base_height_at(at.x,at.y)
	world._cylinder(Vector3(at.x,h+1.65,at.y),0.05,3.3,world.mats.metal,"BannerPole")
	world._bar(Vector3(at.x,h+3.1,at.y),Vector3(at.x+0.9,h+3.1,at.y),0.035,world.mats.metal)
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(12):
		for y in range(16):
			for xy in [Vector2(x,y),Vector2(x,y+1),Vector2(x+1,y),Vector2(x+1,y),Vector2(x,y+1),Vector2(x+1,y+1)]:
				st.set_uv(Vector2(xy.x/12,xy.y/16))
				st.add_vertex(Vector3(at.x+0.08+xy.x/12*0.75,h+3.05-xy.y/16*1.15,at.y))
	st.generate_normals()
	var material=ShaderMaterial.new()
	material.shader=load("res://shaders/banner_breeze.gdshader")
	world._mesh_node(st.commit(),material,"BreezeBanner")

func _process(delta: float) -> void:
	clock+=delta
	if not world.player: return
	var p=world.player.position
	leaves.position=p+Vector3(0,5,0)
	if p.distance_to(previous)>80: leaves.restart()
	previous=p
	leaves.visible=not world.camera.overview
	leaves.direction=Vector3(0.91,-0.08,0.41)*(0.8+0.15*sin(clock*0.23))
	if sound: sound.volume_db=-37+2*sin(clock*0.23)

func _wind_audio() -> void:
	var random=RandomNumberGenerator.new()
	random.seed=1836
	var count=66150
	var samples=PackedFloat32Array()
	samples.resize(count)
	var low=0.0
	for i in range(count):
		low=lerpf(low,random.randf_range(-1,1),0.045)
		samples[i]=low
	for i in range(1000): samples[count-1000+i]=lerpf(samples[count-1000+i],samples[i],float(i)/1000)
	var data=PackedByteArray()
	data.resize(count*2)
	for i in range(count): data.encode_s16(i*2,int(samples[i]*28000))
	var stream=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=22050
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
	stream.loop_end=count
	stream.data=data
	sound=AudioStreamPlayer.new()
	sound.stream=stream
	sound.volume_db=-37
	add_child(sound)
	sound.play()

func release_visuals() -> void:
	set_process(false)
	leaves.emitting=false
	for entry in bindings:
		if is_instance_valid(entry.mesh): entry.mesh.set_surface_override_material(entry.surface,entry.original)
