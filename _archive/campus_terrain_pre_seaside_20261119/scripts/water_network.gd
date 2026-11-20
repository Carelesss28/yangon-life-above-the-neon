extends Node3D
const Layout=preload("res://scripts/terrain_layout.gd")
var world
var open_samples=0
var covered_samples=0
var crossing_samples=0
var sound: AudioStreamWAV

func _ready() -> void:
	name="TownWaterNetwork"
	var water=ShaderMaterial.new()
	water.shader=load("res://shaders/stylized_water.gdshader")
	water.set_shader_parameter("channel_flow",true)
	water.set_shader_parameter("flow_speed",0.22)
	water.set_shader_parameter("opacity",0.42)
	# Snapshot before adding channels: existing road/path/plot crossings need decks.
	var cover_rects=world.grass_exclusions.duplicate()
	var cover_routes=world.grass_routes.duplicate()
	for route in Layout.WATER_ROUTES:
		var st=SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var length=0.0
		var route_open=0
		var route2=[]
		for p in route.points: route2.append(Vector2(p.x,p.z))
		for i in range(route.points.size()-1):
			var a: Vector3=route.points[i]
			var b: Vector3=route.points[i+1]
			var count=ceili(Vector2(a.x,a.z).distance_to(Vector2(b.x,b.z))/1.5)
			var side=Vector3(-(b-a).z,0,(b-a).x).normalized()
			for j in range(count):
				var p=a.lerp(b,float(j)/count)
				var q=a.lerp(b,float(j+1)/count)
				var centre=(p+q)*0.5
				var ground=Layout.base_height_at(centre.x,centre.z)
				var point=Vector2(centre.x,centre.z)
				var depth=ground-centre.y
				var crossing=false
				for rect in cover_rects:
					if rect.has_point(point): crossing=true; break
				if not crossing:
					for entry in cover_routes:
						if entry.rect.has_point(point) and Layout.trail_distance(point,entry.route)<2.8:
							crossing=true; break
				var under_bridge=false
				for span in world.model_bridge_spans:
					if span.has_point(point): under_bridge=true;break
				var covered=crossing or under_bridge or depth<0.15 or depth>2.3
				var distance=p.distance_to(q)
				if covered:
					covered_samples+=1
					if under_bridge:
						pass # The imported bridge already supplies a higher, clear crossing deck.
					elif depth<0.15:
						# A closed supported carrier spans low terrain; no floating open water.
						world._bar(p+Vector3.UP*0.12,q+Vector3.UP*0.12,route.width*0.35,world.mats.metal)
						if j%12==0:
							world._bar(Vector3(centre.x,ground,centre.z),centre,0.12,world.mats.concrete)
					elif crossing:
						crossing_samples+=1
						# Flush collision deck; the lower pipe carries water below the crossing.
						var deck=world._box(Vector3(centre.x,ground-0.12,centre.z),Vector3(route.width+6,0.24,distance+0.35),world.mats.concrete,"CanalCrossingDeck",true)
						deck.rotation.y=atan2(q.x-p.x,q.z-p.z)
					elif j%15==0:
						world._box(Vector3(centre.x,ground+0.03,centre.z),Vector3(0.65,0.06,0.65),world.mats.metal,"CulvertInspectionCover")
				else:
					open_samples+=1
					route_open+=1
					var left=p-side*route.width*0.5
					var right=p+side*route.width*0.5
					var next_left=q-side*route.width*0.5
					var next_right=q+side*route.width*0.5
					var vertices=[left,right,next_left,next_right]
					var coords=[Vector2(0,length),Vector2(1,length),Vector2(0,length+distance),Vector2(1,length+distance)]
					for index in [0,1,2,1,3,2]:
						st.set_uv(coords[index]);st.add_vertex(vertices[index])
					# Low clean channel edges, driven by local terrain rather than painted shadows.
					for sign in [-1,1]:
						var edge=centre+side*sign*(route.width*0.5+0.15)
						var top=Layout.base_height_at(edge.x,edge.z)+0.06
						var wall=world._box(Vector3(edge.x,(top+centre.y-0.4)*0.5,edge.z),Vector3(0.18,maxf(top-centre.y+0.4,0.2),distance+0.1),world.mats.concrete,"OpenChannelEdge")
						wall.rotation.y=atan2(q.x-p.x,q.z-p.z)
				length+=distance
		if route_open>0:
			# Some routes are mainly buried; commit only if this surface has vertices.
			st.generate_normals()
			var mesh=st.commit()
			if mesh and mesh.get_surface_count()>0:
				world._mesh_node(mesh,water,"ChannelWater").cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				var arrays=mesh.surface_get_arrays(0)
				var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX].duplicate()
				for v in range(vertices.size()): vertices[v].y-=0.42
				arrays[Mesh.ARRAY_VERTEX]=vertices
				var bed=ArrayMesh.new()
				bed.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
				world._mesh_node(bed,world.mats.water_bed,"CleanChannelBed")
		var bounds=Rect2(route2[0],Vector2.ZERO)
		for p in route2: bounds=bounds.expand(p)
		world.grass_routes.append({"route":route2,"rect":bounds.grow(2.5)})
	# Pumps are explicit because the residential terraces and lake cannot gravity-feed uphill.
	for at in [Vector2(130,550),Vector2(460,105),Vector2(605,565)]:
		if not Layout.Roads.sample(at.x+2,at.y).is_empty(): at.y+=8
		var h=Layout.base_height_at(at.x,at.y)
		world._box(Vector3(at.x+2,h+0.65,at.y),Vector3(1.4,1.3,1.1),world.mats.metal,"WaterCirculationPump",true)
		world._box(Vector3(at.x+2,h+1.0,at.y-0.57),Vector3(0.65,0.2,0.04),world.mats.cyan,"PumpStatus")
	# Lake intake and enclosed riser meet the pumped-discharge start.
	world._bar(Vector3(590,-2.4,558),Vector3(605,-0.9,565),0.22,world.mats.metal)
	if DisplayServer.get_name()!="headless": _ambient_water()
	print("WATER_NETWORK_READY open=",open_samples," covered=",covered_samples," crossings=",crossing_samples)

func _ambient_water() -> void:
	# Quiet, spatial, generated water ambience; no third-party audio asset.
	var random=RandomNumberGenerator.new()
	random.seed=71743
	var count=44100
	var samples=PackedFloat32Array()
	samples.resize(count)
	var low=0.0
	for i in range(count):
		low=lerpf(low,random.randf_range(-1,1),0.18)
		samples[i]=low*(0.75+0.15*sin(float(i)/22050*TAU*2.0))
	for i in range(1000):
		samples[count-1000+i]=lerpf(samples[count-1000+i],samples[i],float(i)/1000)
	var data=PackedByteArray()
	data.resize(count*2)
	for i in range(count): data.encode_s16(i*2,int(clampf(samples[i]*24000,-32767,32767)))
	sound=AudioStreamWAV.new()
	sound.format=AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate=22050
	sound.data=data
	sound.loop_mode=AudioStreamWAV.LOOP_FORWARD
	sound.loop_end=count
	for at in [Vector3(65,3.2,55),Vector3(135,1.1,440),Vector3(465,1.3,175),Vector3(355,15,-155),Vector3(65,-1.0,690)]:
		var speaker=AudioStreamPlayer3D.new()
		speaker.stream=sound
		speaker.position=at
		speaker.volume_db=-26
		speaker.unit_size=3
		speaker.max_distance=22
		add_child(speaker)
		speaker.play()
