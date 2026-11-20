extends RefCounted
## Yangon-style shophouse rows along the street edges of every town block, plus seafront kiosks.
## Narrow 2-5 storey units: shop below, homes above, awnings, signs, balconies with laundry and AC,
## roll-up shutters, tea stools on the forecourt. Light is real time; windows glow only at night.
const Layout=preload("res://scripts/terrain_layout.gd")
const Roads=preload("res://scripts/road_layout.gd")
const Blocks=preload("res://scripts/reference_blocks.gd")
var world
var root: Node3D
var rng=RandomNumberGenerator.new()
var facades: Array=[]
var glows: Array=[]
var counts={"units":0,"stalls":0,"kiosks":0,"shutters":0}
var walls=["f1e4c8","e9c9a8","d7e6d2","cfe0ea","f2d0c4","e6dcf0","f4e9b8","d9cfc0","c9dccf","ecd2b2"]
var awnings: Array=[]
var dark: StandardMaterial3D
var metal: StandardMaterial3D
var shutter: StandardMaterial3D
var laundry: Array=[]
var stools: Array=[]
const NAMES={
	"home":["မုန့်ဟင်းခါး","ထမင်း","PHONE FIX","TAILOR","PHARMACY","BAKERY","SIM CARDS","STATIONERY","FLORIST","HARDWARE","JUICE","24H MART","NOODLES","PRINT SHOP","BARBER"],
	"downtown":["DATA CAFE","PHONE FIX","24H MART","KARAOKE","NOODLES","MECHA PARTS","BATTERY","GAME STORE","PHARMACY","BOOKS","VR ARCADE","SNEAKERS","CAMERA","RAMEN BAR","CHARGE HUB"],
	"harbour":["SEAFOOD","ICE","NETS & ROPE","MARINE PARTS","ထမင်း","DIVE SHOP","BAIT","SAILORS BAR","24H MART","FISH BALLS","BOAT REPAIR"],
	"market":["SPICES","FRUIT","FABRIC","GOLD THREAD","မုန့်ဟင်းခါး","RICE","BAGS","SHOES","TOYS","HERBS","24H MART"],
}

func setup(owner_world) -> void:
	world=owner_world
	rng.seed=2026111905
	root=Node3D.new()
	root.name="ShophouseRows"
	world.add_child(root)
	dark=world._mat("2a2c33",0.7)
	metal=world._mat("6d7780",0.5)
	shutter=world._mat("9aa3a8",0.55)
	for c in ["e2574c","f2c94c","4fa3c7","7ad08a","ef8fb0","b07ad8","ff9a4a","3fb3a3"]: awnings.append(world._mat(c,0.8))
	for c in ["f4f1e8","e2574c","4fa3c7","f2c94c","7ad08a","ef8fb0"]: laundry.append(world._mat(c,0.9))
	for c in ["d8453f","3d7fd6","3fae6a","e2b33d"]: stools.append(world._mat(c,0.55))
	for entry in Blocks.SHOPROWS: _row(entry[0],entry[1],entry[2])
	_seafront_kiosks()
	apply_mode(world.night)
	print("SHOPHOUSES_READY ",counts)

func apply_mode(night: bool) -> void:
	for m in facades: m.set_shader_parameter("night",1.0 if night else 0.0)
	for m in glows: m.emission_energy_multiplier=float(m.get_meta("energy"))*(1.0 if night else 0.12)

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

func _row(rect: Rect2,facing: int,district: String) -> void:
	world.building_plots.append({"plot":rect,"label":"SHOPHOUSE ROW"})
	world.grass_exclusions.append(rect)
	# Forecourt paving between the shopfronts and the street sidewalk.
	var front_z=rect.end.y if facing>0 else rect.position.y
	var apron=Rect2(rect.position.x,front_z if facing>0 else front_z-3.6,rect.size.x,3.6)
	world._surface(apron,world.mats.paving,"ShopForecourt",false,func(x: float,z: float)->float: return Layout.height_at(x,z)+0.08,2.0,true)
	var x=rect.position.x
	var since_alley=0
	var names: Array=NAMES.get(district,NAMES.home)
	# Gateways: a gap in the row in front of each main building behind it, so its entrance
	# (and anyone standing there) is visible and reachable straight from the street.
	var gaps: Array=[]
	if facing>0:
		for building in world.get_node("PrototypeBuildings").get_children():
			if not building.has_meta("entrance_local"): continue
			var door: Vector3=building.global_position+building.get_meta("entrance_local")
			if door.z<=rect.position.y and door.z>rect.position.y-14.0 and door.x>rect.position.x-2.0 and door.x<rect.end.x+2.0:
				gaps.append(Vector2(maxf(rect.position.x,door.x-5.0),minf(rect.end.x,door.x+5.0)))
	for g in gaps:
		world._surface(Rect2(g.x,rect.position.y-6.0,g.y-g.x,rect.size.y+6.0),world.mats.paving,"Gateway",false,func(px: float,pz: float)->float: return Layout.height_at(px,pz)+0.08,2.0,true)
	while x<rect.end.x-5.5:
		var in_gap=false
		for g in gaps:
			if x>=g.x-0.01 and x<g.y:
				x=g.y
				in_gap=true
		if in_gap:
			since_alley=0
			continue
		var width=minf(rng.randf_range(6.5,9.5),rect.end.x-x)
		for g in gaps:
			if x<g.x and x+width>g.x: width=g.x-x
		if width<4.0:
			x+=width
			continue
		if rect.end.x-(x+width)<5.5:
			var next_gap=false
			for g in gaps:
				if g.x>=x and g.x<rect.end.x: next_gap=true
			if not next_gap: width=rect.end.x-x
		var floors={"downtown":rng.randi_range(2,4),"home":rng.randi_range(2,4),"harbour":rng.randi_range(2,3),"market":rng.randi_range(2,3)}.get(district,3)
		var corner=x==rect.position.x or x+width>=rect.end.x-0.01
		_unit(Rect2(x,rect.position.y,width,rect.size.y),facing,floors,names[counts.units%names.size()] if not corner else "24H MART",corner)
		x+=width
		since_alley+=1
		# A narrow alley every few units keeps the block interior reachable on foot.
		if since_alley>=rng.randi_range(4,6) and x<rect.end.x-14:
			x+=3.0
			since_alley=0

func _unit(r: Rect2,facing: int,floors: int,title: String,corner: bool) -> void:
	var c=r.get_center()
	var depth=r.size.y-1.0
	var ground=INF
	for p in [r.position,r.end,Vector2(r.position.x,r.end.y),Vector2(r.end.x,r.position.y)]:
		ground=minf(ground,Layout.height_at(p.x,p.y))
	var unit=Node3D.new()
	unit.name="Shophouse_%d"%counts.units
	unit.position=Vector3(c.x,ground,c.y)
	if facing<0: unit.rotation.y=PI
	unit.set_meta("building_use",title)
	root.add_child(unit)
	var w=r.size.x-0.15
	var storey=3.2
	var h=floors*storey
	var wall_colour=walls[rng.randi_range(0,walls.size()-1)]
	var facade=ShaderMaterial.new()
	facade.shader=load("res://shaders/cyber_facade.gdshader")
	facade.set_shader_parameter("wall_colour",Color(wall_colour))
	facade.set_shader_parameter("size",Vector3(w,h+0.6,depth))
	facade.set_shader_parameter("seed",rng.randf_range(0,100))
	facade.set_shader_parameter("lit_ratio",rng.randf_range(0.35,0.7))
	facade.set_shader_parameter("night",1.0 if world.night else 0.0)
	facades.append(facade)
	box(unit,Vector3(0,h/2-0.3,0),Vector3(w,h+0.6,depth),facade,"ShophouseShell",true)
	var front=depth/2
	# Shopfront: lit glazing or a roll-up shutter, a coloured awning and a sign board.
	var open_shop=rng.randf()<0.78
	if open_shop:
		box(unit,Vector3(0,1.35,front+0.05),Vector3(w-1.0,2.3,0.08),glow("ffd6a0" if not corner else "dff6ff",1.6),"ShopGlazing")
		box(unit,Vector3(w*0.5-0.9,1.15,front+0.07),Vector3(1.0,2.2,0.06),dark,"ShopDoor")
	else:
		box(unit,Vector3(0,1.35,front+0.06),Vector3(w-1.0,2.4,0.1),shutter,"RollUpShutter")
		for k in range(8): box(unit,Vector3(0,0.3+k*0.3,front+0.12),Vector3(w-1.0,0.04,0.02),metal,"ShutterRib")
		counts.shutters+=1
	world.shop_fronts.append({"node":unit,"width":w,"front":front,"open":open_shop})
	var awn=box(unit,Vector3(0,2.85,front+0.75),Vector3(w-0.3,0.12,1.6),awnings[rng.randi_range(0,awnings.size()-1)],"Awning")
	awn.rotation.x=0.22
	var board=box(unit,Vector3(0,3.45,front+0.18),Vector3(w-0.6,0.7,0.12),dark if corner or rng.randf()<0.6 else world._mat(wall_colour).duplicate(),"SignBoard")
	var label=Label3D.new()
	label.text=title
	label.font_size=48
	label.pixel_size=0.011
	label.position=Vector3(0,3.45,front+0.26)
	label.modulate=Color("ffe9b8") if not corner else Color("bff4ff")
	label.outline_size=4
	label.outline_modulate=Color("1a1a24")
	label.shaded=false
	unit.add_child(label)
	if corner:
		box(unit,Vector3(0,3.84,front+0.2),Vector3(w-0.6,0.08,0.08),glow("6fe8ff",3.0),"MartNeon")
	elif rng.randf()<0.35:
		var colour=["ff3d9a","2fe6e0","ffb84a","7dff9a"][rng.randi_range(0,3)]
		var bx=(w/2-0.5)*(1 if rng.randf()<0.5 else -1)
		box(unit,Vector3(bx,3.4+minf(h*0.3,3.0),front+0.6),Vector3(0.12,minf(h*0.6,5.5),0.9),glow(colour,3.2),"BladeNeon")
	# Upper floors: balconies, laundry lines and AC units on many units.
	for f in range(1,floors):
		var y=f*storey
		if rng.randf()<0.55:
			box(unit,Vector3(0,y+0.05,front+0.55),Vector3(w-1.2,0.14,1.1),world.mats.concrete,"Balcony")
			box(unit,Vector3(0,y+0.6,front+1.08),Vector3(w-1.2,0.9,0.05),metal,"BalconyRail")
			if rng.randf()<0.6:
				for k in range(3):
					box(unit,Vector3(-w*0.3+k*w*0.25,y+1.55,front+0.75),Vector3(0.55,0.8,0.03),laundry[rng.randi_range(0,laundry.size()-1)],"Laundry")
		if rng.randf()<0.5:
			box(unit,Vector3(w*0.32*(1 if f%2==0 else -1),y+1.9,front+0.3),Vector3(0.9,0.55,0.5),world._mat("d9dcd6"),"WallAC")
	# Roof: parapet, water tank or a little roof garden.
	box(unit,Vector3(0,h+0.45,front-0.1),Vector3(w,0.3,0.25),world.mats.coping,"Parapet")
	var roll=rng.randf()
	if roll<0.4:
		box(unit,Vector3(rng.randf_range(-w*0.25,w*0.25),h+0.9,-depth*0.2),Vector3(1.4,1.2,1.4),world._mat("4f8fb0"),"WaterTank")
	elif roll<0.7:
		box(unit,Vector3(0,h+0.42,-depth*0.1),Vector3(w*0.6,0.25,depth*0.4),world.mats.leaf,"RoofGarden")
	# Street life on the forecourt: tea stools and low tables outside food and tea shops.
	# Tea-shop stools belong to the town's four tea shops only (main buildings), not every shophouse.
	if false:
		var tz=front+2.3
		var table=MeshInstance3D.new()
		var cyl=CylinderMesh.new()
		cyl.top_radius=0.4
		cyl.bottom_radius=0.4
		cyl.height=0.46
		table.mesh=cyl
		table.material_override=stools[counts.stalls%4]
		table.position=Vector3(-w*0.15,0.23,tz)
		unit.add_child(table)
		for k in range(4):
			var a=k*PI/2+0.4
			var stool=MeshInstance3D.new()
			var sm=CylinderMesh.new()
			sm.top_radius=0.2
			sm.bottom_radius=0.2
			sm.height=0.32
			stool.mesh=sm
			stool.material_override=stools[(counts.stalls+k+1)%4]
			stool.position=Vector3(-w*0.15+cos(a)*0.8,0.16,tz+sin(a)*0.65)
			unit.add_child(stool)
		counts.stalls+=1
	counts.units+=1

func _seafront_kiosks() -> void:
	# Small tea, juice and snack kiosks along the promenade, with stools and a striped canopy.
	var kinds=["JUICE","ICE CREAM","ROTI","COCONUT","SNACKS"]
	var x=70.0
	var i=0
	while x<591.55:
		var z=Layout.shore(x)+20.0
		if absf(x-535.21)>25 and absf(x-429.58)>18 and absf(x-105.63)>14 and Layout.channel_sample(x,z).is_empty():
			var y=Layout.PROMENADE_Y
			var k=Node3D.new()
			k.name="SeafrontKiosk"
			k.position=Vector3(x,y,z)
			k.rotation.y=PI  # counter faces the promenade and the town
			root.add_child(k)
			box(k,Vector3(0,1.25,0),Vector3(3.2,2.5,2.6),world._mat(walls[i%walls.size()]),"KioskBody",true)
			box(k,Vector3(0,1.1,-1.32),Vector3(2.6,1.0,0.06),glow("ffd6a0",1.8),"KioskCounter")
			var canopy=box(k,Vector3(0,2.75,-0.9),Vector3(3.8,0.12,2.2),awnings[i%awnings.size()],"KioskCanopy")
			canopy.rotation.x=-0.18
			var label=Label3D.new()
			label.text=kinds[i%kinds.size()]
			label.font_size=48
			label.pixel_size=0.012
			label.position=Vector3(0,3.15,-1.35)
			label.rotation.y=PI
			label.modulate=Color("ffe9b8")
			label.outline_size=4
			label.outline_modulate=Color("1a1a24")
			label.shaded=false
			k.add_child(label)
			for s in range(4):
				var stool=MeshInstance3D.new()
				var sm=CylinderMesh.new()
				sm.top_radius=0.2
				sm.bottom_radius=0.2
				sm.height=0.32
				stool.mesh=sm
				stool.material_override=stools[(i+s)%4]
				stool.position=Vector3(-1.2+s*0.8,0.16,-2.6)
				k.add_child(stool)
			world.grass_exclusions.append(Rect2(x-2,z-2,4,4))
			counts.kiosks+=1
		x+=rng.randf_range(70,100)
		i+=1
