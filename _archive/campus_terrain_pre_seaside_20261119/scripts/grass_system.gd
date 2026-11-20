extends Node3D
## Streamed, deterministic tufts; no grass collision or painted lighting.
const Layout=preload("res://scripts/terrain_layout.gd")
const CELL=16.0
const RADIUS=4
var target: Node3D
var camera: Camera3D
var excluded_rects: Array=[]
var excluded_routes: Array=[]
var chunks: Dictionary={}
var pending: Array[Vector2i]=[]
var last_cell=Vector2i(99999,99999)
var mesh: ArrayMesh
var material: ShaderMaterial
var overview_was=false

func _ready() -> void:
	mesh=_tuft_mesh()
	material=ShaderMaterial.new()
	material.shader=load("res://shaders/grass_blades.gdshader")

func _process(_delta: float) -> void:
	if target==null: return
	visible=not camera.overview
	if not visible:
		overview_was=true
		return
	var cell=Vector2i(floori(target.position.x/CELL),floori(target.position.z/CELL))
	if cell!=last_cell or overview_was:
		last_cell=cell
		overview_was=false
		pending.clear()
		for key in chunks.keys():
			if absi(key.x-cell.x)>RADIUS+1 or absi(key.y-cell.y)>RADIUS+1:
				chunks[key].queue_free()
				chunks.erase(key)
		for x in range(cell.x-RADIUS,cell.x+RADIUS+1):
			for z in range(cell.y-RADIUS,cell.y+RADIUS+1):
				var key=Vector2i(x,z)
				if not chunks.has(key): pending.append(key)
		pending.sort_custom(func(a,b):return a.distance_squared_to(cell)<b.distance_squared_to(cell))
	# Bound main-thread work; nearest chunks arrive first after a teleport.
	var started=Time.get_ticks_usec()
	for i in range(mini(2,pending.size())):
		_build_chunk(pending.pop_front())
		if Time.get_ticks_usec()-started>6000: break

func _allowed(x: float,z: float,h: float) -> bool:
	if not Layout.in_world(x,z): return false
	var p=Vector2(x,z)
	for rect in excluded_rects:
		if rect.has_point(p): return false
	for entry in excluded_routes:
		if entry.rect.has_point(p) and Layout.trail_distance(p,entry.route)<2.3: return false
	if Layout.wet(x,z) or not Layout.channel_sample(x,z).is_empty(): return false
	if z>=614 and z>Layout.river_north_bank(x)-1 and z<Layout.river_north_bank(x)+Layout.river_width(x)+4: return false
	if z<0 and z> -300 and absf(x-Layout.north_stream_x(z))<5: return false
	if z<0 and Vector2((x-Layout.north_stream_x(-36))/15,(z+36)/11).length()<1: return false
	if h < -2.0: return false
	# Reject steep faces and retaining wall tops.
	var dx=absf(Layout.height_at(x+0.7,z)-h)
	var dz=absf(Layout.height_at(x,z+0.7)-h)
	return maxf(dx,dz)<0.45

func _build_chunk(key: Vector2i) -> void:
	var random=RandomNumberGenerator.new()
	random.seed=abs(key.x*92837111+key.y*689287499)+7319
	var transforms: Array[Transform3D]=[]
	var colours: Array[Color]=[]
	for i in range(2200):
		var x=key.x*CELL+random.randf()*CELL
		var z=key.y*CELL+random.randf()*CELL
		if not Layout.in_world(x,z): continue
		var h=Layout.height_at(x,z)
		if not _allowed(x,z,h): continue
		var patch=sin(x*0.21+sin(z*0.15))*sin(z*0.18+x*0.07)
		if random.randf()>(0.68+patch*0.25): continue
		var height=random.randf_range(0.7,1.35)
		# Shorter campus lawn, looser meadow growth in the hills.
		if x>=0 and z>=0 and z<614: height*=0.72
		var basis=Basis(Vector3.UP,random.randf()*TAU).scaled(Vector3(random.randf_range(0.8,1.2),height,1))
		transforms.append(Transform3D(basis,Vector3(x-key.x*CELL,h-0.015,z-key.y*CELL)))
		colours.append(Color(random.randf(),0,0,1))
	var multi=MultiMesh.new()
	multi.transform_format=MultiMesh.TRANSFORM_3D
	multi.use_custom_data=true
	multi.mesh=mesh
	multi.instance_count=transforms.size()
	for i in range(transforms.size()):
		multi.set_instance_transform(i,transforms[i])
		multi.set_instance_custom_data(i,colours[i])
	var node=MultiMeshInstance3D.new()
	node.name="Grass_%d_%d" % [key.x,key.y]
	node.multimesh=multi
	node.material_override=material
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.position=Vector3(key.x*CELL,0,key.y*CELL)
	add_child(node)
	chunks[key]=node

func _tuft_mesh() -> ArrayMesh:
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for blade in range(5):
		var angle=blade*2.39996
		var side=Vector3(cos(angle),0,sin(angle))
		var centre=Vector3(sin(angle*2)*0.10,0,cos(angle*2)*0.10)
		var height=0.27+float(blade%3)*0.075
		var lean=Vector3(cos(angle+1.3),0,sin(angle+1.3))*0.10
		var points=[centre-side*0.038,centre+side*0.038,centre+lean*0.4+Vector3.UP*height*0.55-side*0.022,centre+lean*0.4+Vector3.UP*height*0.55+side*0.022,centre+lean+Vector3.UP*height]
		for index in [0,1,2,1,3,2,2,3,4]:
			st.set_normal((Vector3.UP+side*0.25).normalized())
			st.set_uv(Vector2(0,float(points[index].y)/height))
			st.add_vertex(points[index])
	return st.commit()
