extends RefCounted
const Layout=preload("res://scripts/terrain_layout.gd")
## Original downloads remain untouched; these are cleaned, textured copies.
var world
var scenes={}
var bounds={}
var info={}
var counts={"bench":0,"bridge":0,"stair":0,"swing":0}

func setup(owner_world) -> void:
	world=owner_world
	if "--downloaded-props" not in OS.get_cmdline_user_args(): return
	info=JSON.parse_string(FileAccess.get_file_as_string("res://models/downloaded_props/source_info.json"))
	for piece in ["bench","bridge","stair","swing"]:
		scenes[piece]=load("res://models/downloaded_props/%s.glb" % piece)
		var probe=scenes[piece].instantiate()
		bounds[piece]=world._scene_bounds(probe)
		_tone(probe)
		var prepared=PackedScene.new()
		prepared.pack(probe)
		scenes[piece]=prepared
		probe.free()

func place(piece: String,at: Vector3,scale_value: Vector3) -> Node3D:
	var root=Node3D.new()
	root.name="Downloaded_%s" % piece
	root.position=at
	world.add_child(root)
	var model=scenes[piece].instantiate() as Node3D
	model.scale=scale_value
	root.add_child(model)
	counts[piece]+=1
	return root

func bench(x: float,z: float) -> void:
	if scenes.is_empty():
		var at=Vector3(x,Layout.height_at(x,z),z)
		world._box(at+Vector3(0,0.48,0),Vector3(2.25,0.13,0.58),world.mats.wood,"BenchSeat")
		world._box(at+Vector3(0,0.45,-0.05),Vector3(2.25,0.9,0.6),world.mats.wood,"BenchSolid",true).visible=false
		world._box(at+Vector3(0,0.77,-0.26),Vector3(2.25,0.3,0.1),world.mats.wood,"BenchBack")
		for side in [-1,1]:
			world._box(at+Vector3(side*0.87,0.25,0),Vector3(0.12,0.5,0.49),world.mats.metal,"BenchLeg")
		return
	var b: AABB=bounds.bench
	var size=2.1/b.size.x
	place("bench",Vector3(x,Layout.height_at(x,z)-b.position.y*size,z),Vector3.ONE*size)
	world.grass_exclusions.append(Rect2(x-1.15,z-0.65,2.3,1.3))

func bridge(centre: Vector2,length: float,width: float) -> void:
	if scenes.is_empty():
		world._box(Vector3(centre.x,1.8,centre.y),Vector3(length,0.4,width),world.mats.wood,"BridgeDeck",true)
		for side in [-1,1]:
			var z=centre.y+side*(width/2-0.15)
			world._box(Vector3(centre.x,2.9,z),Vector3(length,0.1,0.1),world.mats.metal,"BridgeRail")
			for i in range(5):
				var x=centre.x+length*(i/4.0-0.5)
				world._box(Vector3(x,2.45,z),Vector3(0.11,0.91,0.11),world.mats.metal,"BridgePost")
		return
	var b: AABB=bounds.bridge
	var s=Vector3(length/b.size.x,width/b.size.z,width/b.size.z)
	var deck=float(info.bridge.centre_surface_z)
	place("bridge",Vector3(centre.x,2.0-deck*s.y,centre.y),s)
	# Preserve the tested, flush crossing collider; discard its old box appearance.
	world._box(Vector3(centre.x,1.8,centre.y),Vector3(length,0.4,width),world.mats.wood,"BridgeCollision",true).visible=false
	world.grass_exclusions.append(Rect2(centre.x-length/2,centre.y-width/2,length,width))

func stair(cx: float,centre_z: float,width: float,run: float,rise: float,low: float) -> void:
	if scenes.is_empty():
		var tread_count=ceili(rise/0.18)
		for i in range(tread_count):
			var z=centre_z+run/2-(i+0.5)*run/tread_count
			var y=low+(i+1)*rise/tread_count
			world._box(Vector3(cx,y-0.14,z),Vector3(width,0.28,run/tread_count+0.02),world.mats.concrete,"StairTread")
		return
	var b: AABB=bounds.stair
	var values=[]
	for p in info.stair.profile_y:
		if p[1]!=null: values.append(float(p[1]))
	var minimum: float=values.min()
	var maximum: float=values.max()
	var s=Vector3(width/b.size.x,rise/maxf(maximum-minimum,0.01),run/b.size.z)
	place("stair",Vector3(cx,low-minimum*s.y,centre_z),s)
	world.grass_exclusions.append(Rect2(cx-width/2,centre_z-run/2,width,run))

func swing(x: float,z: float) -> void:
	if scenes.is_empty():
		var at=Vector3(x,Layout.height_at(x,z),z)
		world._box(at+Vector3(0,2.8,0),Vector3(3.8,0.14,0.14),world.mats.metal,"SwingBeam")
		for side in [-1,1]:
			world._box(at+Vector3(side*1.76,1.4,0),Vector3(0.13,2.8,0.13),world.mats.metal,"SwingPost")
			var seat=at+Vector3(side*0.86,0.72,0)
			world._box(seat,Vector3(0.58,0.11,0.39),world.mats.cyan,"SwingSeat")
			for hanger in [-1,1]:
				world._box(seat+Vector3(hanger*0.24,1.04,0),Vector3(0.03,2.08,0.03),world.mats.metal,"SwingHanger")
		return
	var b: AABB=bounds.swing
	var s=2.7/b.size.y
	place("swing",Vector3(x,Layout.height_at(x,z)-b.position.y*s,z),Vector3.ONE*s)
	world.grass_exclusions.append(Rect2(x-1.5,z-1.0,3,2))

func _tone(node: Node) -> void:
	if node is MeshInstance3D:
		for i in range(node.mesh.get_surface_count()):
			var source=node.get_active_material(i)
			if source is StandardMaterial3D:
				var material=source.duplicate()
				material.albedo_color*=Color(0.60,0.60,0.60,1)
				node.set_surface_override_material(i,material)
	for child in node.get_children(): _tone(child)
