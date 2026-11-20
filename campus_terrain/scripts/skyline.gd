extends RefCounted
## Cyberpunk skyline: stepped ~60 m towers with lit window grids, corner neon, animated LED wraps,
## crowns with antennas and rooftop sign frames; extra rooftop sign frames on mid-rise buildings;
## large hologram ads over plazas. Everything is real time; day/night only changes emission.
const Layout=preload("res://scripts/terrain_layout.gd")
var world
var root: Node3D
var rng=RandomNumberGenerator.new()
var facades: Array=[]
var leds: Array=[]
var holos: Array=[]
var glows: Array=[]
var counts={"towers":0,"led_wraps":0,"sign_frames":0,"holograms":0}
const TOWER_WALLS=["2f4a63","3a3f5c","2e5560","4a4058","36485a","5a6a7a","3b5b6e"]
const NEON=["ff3d9a","2fe6e0","ffb84a","b07dff","7dff9a","ff6a4a"]
const SIGN_TEXT=["NEON NOODLES","YUST MECHA CUP","SKYTRAIN 24H","CYBER DATA","MOHINGA 2.0","PILOT ACADEMY","HARBOUR FEST","SKY TEA","MECHA PARTS","ROBO REPAIR","ANDROID BANK","VR DREAMS","SEA BREEZE COLA","GOLDEN ARMOR"]
const HOLO_TEXT=["YUST MECHA CUP","PILOTS WANTED","NEON NOODLES","SKYTRAIN 24H","SEA FEST","SYNC RATE 400%","CHARGE HUB","STAY SAFE · SHELTER 7"]

func setup(owner_world) -> void:
	world=owner_world
	rng.seed=2026112001
	root=Node3D.new()
	root.name="Skyline"
	world.add_child(root)

func apply_mode(night: bool) -> void:
	for m in facades: m.set_shader_parameter("night",1.0 if night else 0.0)
	for m in leds: m.set_shader_parameter("strength",1.0 if night else 0.55)
	for m in holos: m.set_shader_parameter("strength",1.0 if night else 0.45)
	for m in glows: m.emission_energy_multiplier=float(m.get_meta("energy"))*(1.0 if night else 0.3)

func glow(colour: String,energy: float) -> StandardMaterial3D:
	var m=world._mat(colour,0.4,energy)
	m.set_meta("energy",energy)
	glows.append(m)
	return m

func box(parent: Node3D,at: Vector3,size: Vector3,mat: Material,title: String,solid=false) -> MeshInstance3D:
	var mesh=BoxMesh.new()
	mesh.size=size
	var node=MeshInstance3D.new()
	node.name=title
	node.mesh=mesh
	node.material_override=mat
	node.position=at
	parent.add_child(node)
	if solid:
		var body=StaticBody3D.new()
		var shape=CollisionShape3D.new()
		var b=BoxShape3D.new()
		b.size=size
		shape.shape=b
		body.add_child(shape)
		node.add_child(body)
	return node

func facade(size: Vector3,colour: String) -> ShaderMaterial:
	var m=ShaderMaterial.new()
	m.shader=load("res://shaders/cyber_facade.gdshader")
	m.set_shader_parameter("wall_colour",Color(colour))
	m.set_shader_parameter("size",size)
	m.set_shader_parameter("seed",rng.randf_range(0,100))
	m.set_shader_parameter("lit_ratio",rng.randf_range(0.45,0.75))
	m.set_shader_parameter("night",1.0 if world.night else 0.0)
	facades.append(m)
	return m

func led(parent: Node3D,at: Vector3,size: Vector2,yaw: float=0.0) -> void:
	var m=ShaderMaterial.new()
	m.shader=load("res://shaders/led_screen.gdshader")
	m.set_shader_parameter("tint_a",Color(NEON[rng.randi_range(0,NEON.size()-1)]))
	m.set_shader_parameter("tint_b",Color(NEON[rng.randi_range(0,NEON.size()-1)]))
	m.set_shader_parameter("seed",rng.randf_range(0,50))
	m.set_shader_parameter("cells",Vector2(maxf(8,size.x*2.2),maxf(8,size.y*2.2)))
	m.set_shader_parameter("strength",1.0 if world.night else 0.55)
	leds.append(m)
	var q=MeshInstance3D.new()
	var mesh=QuadMesh.new()
	mesh.size=size
	q.mesh=mesh
	q.material_override=m
	q.position=at
	q.rotation.y=yaw
	q.name="LedWrap"
	q.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(q)
	counts.led_wraps+=1

# Called by reference_buildings.build() for any plot whose title contains TOWER.
func build_tower(b,root_node: Node3D,roof: Node3D,w: float,d: float,floors: int,variant: int,title: String) -> void:
	var podium=b.module(root_node,roof,Vector3.ZERO,w*0.95,d*0.9,2,variant)
	var storey=3.2
	var shaft_floors=maxi(4,floors-2)
	var shares=[0.5,0.3,0.2] if shaft_floors>=12 else [0.6,0.4]
	var y=podium
	var sw=w*0.66
	var sd=maxf(d*0.66,9.0)
	var offset=Vector3(rng.randf_range(-w*0.08,w*0.08),0,-d*0.06)
	var colour=TOWER_WALLS[(variant*3+1)%TOWER_WALLS.size()]
	var neon=NEON[(variant+counts.towers)%NEON.size()]
	var strip=glow(neon,3.6)
	for i in range(shares.size()):
		var tf=maxi(2,int(round(shaft_floors*shares[i])))
		var h=tf*storey
		var c=offset+Vector3(0,y+h/2,0)
		box(root_node,c,Vector3(sw,h,sd),facade(Vector3(sw,h,sd),colour),"TowerShaft",true)
		# Corner neon strips and a ledge at each setback.
		for cx in [-1,1]:
			for cz in [-1,1]:
				box(root_node,offset+Vector3(cx*(sw/2+0.06),y+h/2,cz*(sd/2+0.06)),Vector3(0.16,h,0.16),strip,"CornerNeon")
		box(root_node,offset+Vector3(0,y+h+0.15,0),Vector3(sw+1.0,0.3,sd+1.0),world.mats.coping,"SetbackLedge")
		# Animated LED wrap on the front (camera-facing) face of the lower tiers.
		if i<2:
			var lh=minf(h*0.55,16.0)
			led(root_node,offset+Vector3(0,y+h*0.55,sd/2+0.08),Vector2(sw*0.78,lh))
			if i==0 and rng.randf()<0.6:
				led(root_node,offset+Vector3(sw/2+0.08,y+h*0.5,0),Vector2(sd*0.7,lh*0.8),PI/2)
		y+=h
		sw=maxf(sw*0.78,8.0)
		sd=maxf(sd*0.8,7.0)
	# Crown: neon ring, antenna with beacon and a rooftop sign frame.
	for z in [-sd/2,sd/2]: box(roof,offset+Vector3(0,y+0.6,z),Vector3(sw,0.18,0.18),strip,"CrownNeon")
	for x in [-sw/2,sw/2]: box(roof,offset+Vector3(x,y+0.6,0),Vector3(0.18,0.18,sd),strip,"CrownNeon")
	box(roof,offset+Vector3(sw*0.25,y+5.5,-sd*0.2),Vector3(0.25,11,0.25),world.mats.metal,"TowerAntenna")
	box(roof,offset+Vector3(sw*0.25,y+11.2,-sd*0.2),Vector3(0.45,0.45,0.45),glow("ff3030",5.0),"AircraftBeacon")
	sign_frame(roof,offset+Vector3(-sw*0.1,y,sd*0.15),minf(sw*1.1,18.0),title)
	b.entry(root_node,Vector3(-w*0.12,0,d*0.45),title,8)
	counts.towers+=1

func sign_frame(parent: Node3D,base: Vector3,width: float,seed_title: String) -> void:
	# Steel lattice frame with a big neon word, standing on two legs on the roof.
	var height=width*0.32
	var leg_h=2.4
	var steel=world.mats.metal
	for s in [-1,1]:
		box(parent,base+Vector3(s*width*0.42,leg_h/2,0),Vector3(0.3,leg_h,0.3),steel,"SignLeg")
		var brace=box(parent,base+Vector3(s*width*0.42,leg_h/2,-1.2),Vector3(0.2,leg_h*1.3,0.2),steel,"SignBrace")
		brace.rotation.x=0.5
	box(parent,base+Vector3(0,leg_h+height/2,0),Vector3(width,height,0.3),world._mat("15161c",0.7),"SignBoard")
	for y in [leg_h,leg_h+height]: box(parent,base+Vector3(0,y,0.1),Vector3(width,0.16,0.16),steel,"SignRail")
	var colour=NEON[abs(hash(seed_title))%NEON.size()]
	box(parent,base+Vector3(0,leg_h+height-0.25,0.2),Vector3(width-0.4,0.1,0.06),glow(colour,3.5),"SignNeonTop")
	box(parent,base+Vector3(0,leg_h+0.25,0.2),Vector3(width-0.4,0.1,0.06),glow(colour,3.5),"SignNeonBottom")
	var label=Label3D.new()
	label.text=SIGN_TEXT[abs(hash(seed_title))%SIGN_TEXT.size()]
	label.font_size=128
	label.pixel_size=width*0.00065
	label.position=base+Vector3(0,leg_h+height/2,0.2)
	label.modulate=Color(colour).lightened(0.45)
	label.outline_size=10
	label.outline_modulate=Color(colour).darkened(0.4)
	label.shaded=false
	parent.add_child(label)
	counts.sign_frames+=1

# After all buildings exist: sign frames on some mid-rise roofs, then hologram ads.
func after_buildings() -> void:
	var i=0
	for building in world.get_node("PrototypeBuildings").get_children():
		var title: String=str(building.get_meta("building_use",""))
		if "TOWER" in title or "MARKET" in title or "YUST" in title or "DORM" in title or "CLASSROOM" in title: continue
		i+=1
		if i%3!=0: continue
		var shells=building.find_children("CompositeShell","MeshInstance3D",true,false)
		if shells.is_empty(): continue
		var top=-INF
		var best: MeshInstance3D
		for s in shells:
			var p: Vector3=building.to_local(s.global_position)
			var t=p.y+s.mesh.size.y/2
			if t>top: top=t; best=s
		var bp: Vector3=building.to_local(best.global_position)
		sign_frame(building,Vector3(bp.x,top+0.3,bp.z+best.mesh.size.z*0.2),minf(best.mesh.size.x*0.8,14.0),title)
	_holograms()
	print("SKYLINE_READY ",counts)

func _holograms() -> void:
	var spots=[Vector2(334.51,440),Vector2(429.58,214),Vector2(422.54,740),Vector2(693.66,690),Vector2(676.06,300),Vector2(232.39,440),Vector2(105.63,300),Vector2(535.21,880)]
	for k in range(spots.size()):
		var p: Vector2=_free_spot(spots[k])
		var y=Layout.height_at(p.x,p.y)
		var node=Node3D.new()
		node.name="HologramAd"
		node.position=Vector3(p.x,y,p.y)
		root.add_child(node)
		var colour=NEON[k%NEON.size()]
		box(node,Vector3(0,0.4,0),Vector3(2.2,0.8,2.2),world._mat("25262e",0.6),"ProjectorBase",true)
		box(node,Vector3(0,0.85,0),Vector3(1.4,0.1,1.4),glow(colour,4.0),"ProjectorLens")
		var m=ShaderMaterial.new()
		m.shader=load("res://shaders/hologram_sign.gdshader")
		m.set_shader_parameter("holo_colour",Color(colour))
		m.set_shader_parameter("strength",1.0 if world.night else 0.45)
		holos.append(m)
		var q=MeshInstance3D.new()
		var mesh=QuadMesh.new()
		mesh.size=Vector2(9,13)
		q.mesh=mesh
		q.material_override=m
		q.position=Vector3(0,14,0)
		q.rotation.x=-0.25
		q.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.add_child(q)
		# A simple mecha-head / figure silhouette drawn from glowing bars inside the panel.
		var bar=glow(colour,2.6)
		for part in [[Vector3(0,16.5,0.1),Vector3(3.2,2.4,0.05),bar],[Vector3(0,12.6,0.6),Vector3(5.0,4.2,0.05),bar],
				[Vector3(-1.0,16.8,0.03),Vector3(0.6,0.25,0.06),glow("ffffff",4.0)],[Vector3(1.0,16.8,0.03),Vector3(0.6,0.25,0.06),glow("ffffff",4.0)]]:
			var piece=box(node,part[0],part[1],part[2],"HoloFigure")
			piece.rotation.x=-0.25
		var label=Label3D.new()
		label.text=HOLO_TEXT[k%HOLO_TEXT.size()]
		label.font_size=128
		label.pixel_size=0.02
		label.position=Vector3(0,8.9,1.4)
		label.rotation.x=-0.25
		label.modulate=Color(colour).lightened(0.5)
		label.outline_size=10
		label.outline_modulate=Color(colour).darkened(0.5)
		label.shaded=false
		node.add_child(label)
		var light=OmniLight3D.new()
		light.light_color=Color(colour)
		light.omni_range=16
		light.light_energy=0.0
		light.set_meta("night_energy",2.0)
		light.position=Vector3(0,6,2)
		light.shadow_enabled=false
		node.add_child(light)
		world.lamps.append(light)
		world.grass_exclusions.append(Rect2(p.x-1.5,p.y-1.5,3,3))
		counts.holograms+=1

func _free_spot(p: Vector2) -> Vector2:
	# Nudge a projector off roads, building plots and fountains onto open ground or plaza.
	for r in [0.0,8.0,14.0,20.0,28.0]:
		for a in range(8):
			var q=p+Vector2(cos(a*PI/4),sin(a*PI/4))*r
			if not Layout.Roads.sample(q.x,q.y).is_empty() or not Layout.Roads.has_clearance(q,2.0): continue
			if not Layout.channel_sample(q.x,q.y).is_empty() or Layout.wet(q.x,q.y): continue
			var blocked=false
			for entry in world.building_plots:
				if Rect2(entry.plot).grow(2.0).has_point(q): blocked=true; break
			for f in [Vector2(334.51,440),Vector2(429.58,222),Vector2(697.18,690),Vector2(105.63,520)]:
				if q.distance_to(f)<9: blocked=true
			if not blocked: return q
			if r==0.0: break
	return p
