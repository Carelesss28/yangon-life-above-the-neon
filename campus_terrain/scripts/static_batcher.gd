extends RefCounted
## Merges the town's static box geometry into a few meshes per building (one surface per material),
## cutting tens of thousands of draw calls to a few thousand. Runs once after the world is built.
## Leaves alone anything that moves, sways, blinks or is toggled: vehicles, trains, people, wildlife,
## swaying trees and shrubs, cable cabins, drones, mecha, hidden markers, and shader materials
## (those read each mesh's own model space). Night mode keeps working: it edits shared materials.
const SKIP_SCRIPTS=["player.gd","follow_camera.gd","traffic.gd","skytrain.gd","bus_service.gd","npc_system.gd",
	"motor_district.gd","rides.gd","owned_vehicle.gd","wildlife.gd","town_breeze.gd","grass_system.gd",
	"building_interiors.gd","click_move.gd","drone_flight.gd","minimap.gd","anim_visual.gd","model_visual.gd",
	"student_visual.gd","hill_movers.gd"]
const CELL=48.0
const ATTRS=Mesh.ARRAY_FORMAT_VERTEX|Mesh.ARRAY_FORMAT_NORMAL|Mesh.ARRAY_FORMAT_TANGENT|Mesh.ARRAY_FORMAT_COLOR|Mesh.ARRAY_FORMAT_TEX_UV|Mesh.ARRAY_FORMAT_TEX_UV2
var world: Node3D
var protected={}
var groups={}     # instance key -> {anchor, cast, layers, mats: {material key -> {material, fmt, parts: [[mesh, surface, xform]]}}}
var victims: Array=[]

static func run(w: Node3D) -> Dictionary:
	var b=new()
	b.world=w
	return b._run()

func _run() -> Dictionary:
	var t0=Time.get_ticks_msec()
	for list_name in ["wind_trees","wind_plants"]:
		for n in world.get(list_name): protected[n]=true
	for bay in world.hangar_bays: protected[bay.node]=true
	if world.hangar_roof: protected[world.hangar_roof]=true
	if world.hill:
		for m in world.hill.movers: protected[m.node]=true
		if world.hill.get("parked_mecha"): protected[world.hill.parked_mecha]=true
	_walk(world,1,world)
	var t_walk=Time.get_ticks_msec()-t0
	var made=0
	for key in groups:
		var g=groups[key]
		var mesh=ArrayMesh.new()
		for mk in g.mats:
			var entry=g.mats[mk]
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,_concat(entry.parts))
			mesh.surface_set_material(mesh.get_surface_count()-1,entry.material)
		var mi=MeshInstance3D.new()
		mi.name="Batched"
		mi.mesh=mesh
		mi.cast_shadow=g.cast
		mi.layers=g.layers
		g.anchor.add_child(mi)
		made+=1
	var t_build=Time.get_ticks_msec()-t0
	for v in victims:
		v.get_parent().remove_child(v)
		v.queue_free()
	var out={"merged":victims.size(),"into":made,"walk":t_walk,"build":t_build,"ms":Time.get_ticks_msec()-t0}
	print("STATIC_BATCH ",out)
	return out

var arrays_cache={}
var unit_boxes={}
const PRIM_PROPS=["size","top_radius","bottom_radius","height","radius","radial_segments","rings","subdivide_width","subdivide_height","subdivide_depth","left_to_right","flip_faces","add_uv2","cap_top","cap_bottom","is_hemisphere","orientation","center_offset","section_length","sections","section_segments","inner_radius","outer_radius","ring_segments","curve_step"]
func _arrays(mesh: Mesh,i: int) -> Array:
	# Reading arrays back from the renderer stalls on the GPU, so read each distinct shape once.
	var k
	if mesh is PrimitiveMesh:
		k=[mesh.get_class()]
		for prop in PRIM_PROPS: k.append(mesh.get(prop))
	else:
		k=[mesh.get_instance_id(),i]
	if arrays_cache.has(k): return arrays_cache[k]
	var a: Array=mesh.surface_get_arrays(i)
	arrays_cache[k]=a
	return a

func _unit_box(mesh: BoxMesh) -> BoxMesh:
	# Box UVs and normals do not depend on size: share one unit box per subdivision and scale it.
	var k=[mesh.subdivide_width,mesh.subdivide_height,mesh.subdivide_depth,mesh.add_uv2]
	if not unit_boxes.has(k):
		var b=BoxMesh.new()
		b.subdivide_width=k[0]; b.subdivide_height=k[1]; b.subdivide_depth=k[2]; b.add_uv2=k[3]
		unit_boxes[k]=b
	return unit_boxes[k]

func _concat(parts: Array) -> Array:
	var verts=PackedVector3Array()
	var norms=PackedVector3Array()
	var uvs=PackedVector2Array()
	var uv2s=PackedVector2Array()
	var cols=PackedColorArray()
	var idx=PackedInt32Array()
	var first: Array=_arrays(parts[0][0],parts[0][1])
	var has_n=first[Mesh.ARRAY_NORMAL]!=null and first[Mesh.ARRAY_NORMAL].size()>0
	var has_uv=first[Mesh.ARRAY_TEX_UV]!=null and first[Mesh.ARRAY_TEX_UV].size()>0
	var has_uv2=first[Mesh.ARRAY_TEX_UV2]!=null and first[Mesh.ARRAY_TEX_UV2].size()>0
	var has_c=first[Mesh.ARRAY_COLOR]!=null and first[Mesh.ARRAY_COLOR].size()>0
	for p in parts:
		var a: Array=_arrays(p[0],p[1])
		var xf: Transform3D=p[2]
		var base=verts.size()
		var v: PackedVector3Array=a[Mesh.ARRAY_VERTEX]
		verts.append_array(xf*v)
		if has_n: norms.append_array(Transform3D(xf.basis.inverse().transposed(),Vector3.ZERO)*(a[Mesh.ARRAY_NORMAL] as PackedVector3Array))
		if has_uv: uvs.append_array(a[Mesh.ARRAY_TEX_UV])
		if has_uv2: uv2s.append_array(a[Mesh.ARRAY_TEX_UV2])
		if has_c: cols.append_array(a[Mesh.ARRAY_COLOR])
		var ia=a[Mesh.ARRAY_INDEX]
		if ia==null or ia.size()==0:
			for k in range(v.size()): idx.append(base+k)
		elif base==0:
			idx.append_array(ia)
		else:
			for k in ia: idx.append(base+k)
	var out=[]
	out.resize(Mesh.ARRAY_MAX)
	out[Mesh.ARRAY_VERTEX]=verts
	if has_n: out[Mesh.ARRAY_NORMAL]=norms
	if has_uv: out[Mesh.ARRAY_TEX_UV]=uvs
	if has_uv2: out[Mesh.ARRAY_TEX_UV2]=uv2s
	if has_c: out[Mesh.ARRAY_COLOR]=cols
	out[Mesh.ARRAY_INDEX]=idx
	return out

func _walk(node: Node,depth: int,anchor: Node3D) -> void:
	for c in node.get_children():
		if protected.has(c) or not (c is Node3D) or not c.visible: continue
		var s=c.get_script()
		if s and s.resource_path.get_file() in SKIP_SCRIPTS: continue
		if c.get_class()=="MeshInstance3D" and s==null and c.get_child_count()==0:
			# Meshes straight under the world or a top-level container are bucketed by area.
			_take(c,anchor,depth<=2)
			continue
		# Each item under a top-level container (a building, a prop group) is its own anchor; so is
		# anything with a script of its own (it may move or spin as a whole).
		var next=anchor
		if depth==2 or s!=null: next=c
		_walk(c,depth+1,next)

var formats={}
func _format(mesh: Mesh,i: int) -> int:
	if mesh is ArrayMesh: return mesh.surface_get_format(i)&ATTRS
	var k=[mesh.get_instance_id(),i]
	if formats.has(k): return formats[k]
	var a=_arrays(mesh,i)
	var f=0
	for pair in [[Mesh.ARRAY_NORMAL,Mesh.ARRAY_FORMAT_NORMAL],[Mesh.ARRAY_TANGENT,Mesh.ARRAY_FORMAT_TANGENT],[Mesh.ARRAY_COLOR,Mesh.ARRAY_FORMAT_COLOR],[Mesh.ARRAY_TEX_UV,Mesh.ARRAY_FORMAT_TEX_UV],[Mesh.ARRAY_TEX_UV2,Mesh.ARRAY_FORMAT_TEX_UV2]]:
		if a[pair[0]]!=null and a[pair[0]].size()>0: f|=pair[1]
	formats[k]=f
	return f

func _take(mi: MeshInstance3D,anchor: Node3D,cells: bool) -> void:
	var mesh: Mesh=mi.mesh
	if mesh==null or mi.skin!=null or mi.material_overlay!=null or mi.visibility_range_end>0.0 or mi.transparency>0.0: return
	if mesh is ArrayMesh and mesh.get_blend_shape_count()>0: return
	var mats=[]
	for i in range(mesh.get_surface_count()):
		if mesh is ArrayMesh and mesh.surface_get_primitive_type(i)!=Mesh.PRIMITIVE_TRIANGLES: return
		var m=mi.get_active_material(i)
		if not (m is BaseMaterial3D): return
		if m.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED or m.billboard_mode!=BaseMaterial3D.BILLBOARD_DISABLED: return
		if m.normal_enabled or m.heightmap_enabled: return
		if (m.uv1_triplanar and not m.uv1_world_triplanar) or (m.uv2_triplanar and not m.uv2_world_triplanar): return
		mats.append(m)
	var xf: Transform3D=anchor.global_transform.affine_inverse()*mi.global_transform
	var cell=Vector2i()
	if cells: cell=Vector2i(floori(mi.global_position.x/CELL),floori(mi.global_position.z/CELL))
	var key=[anchor.get_instance_id(),cell,mi.cast_shadow,mi.layers]
	if not groups.has(key): groups[key]={"anchor":anchor,"cast":mi.cast_shadow,"layers":mi.layers,"mats":{}}
	var g=groups[key]
	for i in range(mats.size()):
		var fmt=_format(mesh,i)&~Mesh.ARRAY_FORMAT_TANGENT
		var mk=[mats[i].get_instance_id(),fmt]
		if not g.mats.has(mk): g.mats[mk]={"material":mats[i],"parts":[]}
		if mesh is BoxMesh and mesh.flip_faces==false:
			g.mats[mk].parts.append([_unit_box(mesh),i,xf*Transform3D(Basis.from_scale(mesh.size),Vector3.ZERO)])
		else:
			g.mats[mk].parts.append([mesh,i,xf])
	victims.append(mi)
