extends RefCounted
## Procedural street-level and rooftop life: neon, signs, cables, vents, tea-shop stools,
## food carts and vending machines. Everything is real geometry lit by the game; nothing is baked.
## Buildings keep their roots, IDs and footprints, so a Tripo model can still replace any of them.
var world
var rng=RandomNumberGenerator.new()
var root: Node3D
var neon_materials: Array=[]
var cable_budget=60
var cyber
var counts={"neon":0,"roof":0,"cables":0,"stools":0,"carts":0,"vending":0,"holo":0}
var dark: StandardMaterial3D
var grey: StandardMaterial3D
var steel: StandardMaterial3D
var cable_material: StandardMaterial3D
var stool_materials: Array=[]
var umbrella_materials: Array=[]
var neon_palette=["ff3d9a","2fe6e0","ffb84a","7dff9a","ff6a4a"]
var roofs: Array=[]
var holo_materials: Array=[]
var accent_materials: Array=[]
var laundry_materials: Array=[]

const COMMERCE := ["TEA","FOOD","CAFE","SHOP","GROCERY","ARCADE","CONVENIENCE","BOOKSHOP","LAUNDRY","COMMONS","UNION","REPAIR","ELECTRONICS","MOHINGA","CLUBS","STUDIOS"]
const TEA_WORDS := ["TEA","CAFE","MOHINGA","FOOD","COMMONS","UNION","GROCERY"]
const TECH_WORDS := ["ELECTRONICS","ARCADE","REPAIR","STUDIOS","ROBOT","CLINIC","MAKER","SERVICES"]

func setup(owner_world) -> void:
	world=owner_world
	rng.seed=2026111902
	root=Node3D.new()
	root.name="StreetLife"
	world.add_child(root)
	dark=world._mat("20262c",0.7)
	grey=world._mat("7b8a8c",0.7)
	steel=world._mat("9aa8a8",0.45)
	cable_material=world._mat("15181c",0.9)
	for colour in ["d8453f","3d7fd6","3fae6a","e2b33d"]: stool_materials.append(world._mat(colour,0.55))
	for colour in ["c8473d","2f8f9a","d89a3a","7c5fb0"]: umbrella_materials.append(world._mat(colour,0.8))
	for colour in ["2f8f9a","c0694a","d8a63a","8a6fb5","4f8f5f","d9d4c8"]: accent_materials.append(world._mat(colour,0.6))
	for colour in ["e8e2d4","d8453f","3d7fd6","e2b33d","8fd0c2","c46fa0"]: laundry_materials.append(world._mat(colour,0.9))
	var district=world.get_node_or_null("PrototypeBuildings")
	if district==null: return
	var index=0
	for building in district.get_children():
		if not building is Node3D: continue
		_dress(building,index)
		index+=1
	cyber=load("res://scripts/cyber_district.gd").new()
	cyber.setup(world,self)
	_cables()
	print("STREET_LIFE_READY ",counts)

func neon(colour: String,energy=3.0) -> StandardMaterial3D:
	var material=world._mat(colour,0.4,energy)
	material.set_meta("energy",energy)
	neon_materials.append(material)
	return material

func apply_mode(night: bool) -> void:
	_atmosphere(night)
	if cyber: cyber.apply_mode(night)
	for material in neon_materials:
		material.emission_energy_multiplier=float(material.get_meta("energy"))*(1.0 if night else 0.18)
	for material in holo_materials:
		material.set_shader_parameter("strength",1.0 if night else 0.35)

func _box(parent: Node3D,at: Vector3,size: Vector3,material: Material,title: String) -> MeshInstance3D:
	var mesh=BoxMesh.new()
	mesh.size=size
	var node=MeshInstance3D.new()
	node.name=title
	node.mesh=mesh
	node.material_override=material
	node.position=at
	parent.add_child(node)
	return node

func _cyl(parent: Node3D,at: Vector3,radius: float,height: float,material: Material,title: String) -> MeshInstance3D:
	var mesh=CylinderMesh.new()
	mesh.top_radius=radius
	mesh.bottom_radius=radius
	mesh.height=height
	mesh.radial_segments=10
	var node=MeshInstance3D.new()
	node.name=title
	node.mesh=mesh
	node.material_override=material
	node.position=at
	parent.add_child(node)
	return node

func _light(parent: Node3D,at: Vector3,colour: String,energy: float,radius: float) -> void:
	var light=OmniLight3D.new()
	light.name="NeonLight"
	light.position=at
	light.light_color=Color(colour)
	light.omni_range=radius
	light.light_energy=energy if world.night else 0.0
	light.shadow_enabled=false
	light.set_meta("night_energy",energy)
	parent.add_child(light)
	world.lamps.append(light)

func _has(title: String,words: Array) -> bool:
	for word in words:
		if word in title: return true
	return false

func _dress(building: Node3D,index: int) -> void:
	var title: String=str(building.get_meta("building_use",""))
	var bounds: AABB=world._scene_bounds(building,building.get_parent_node_3d().global_transform)
	var width=bounds.size.x
	var depth=bounds.size.z
	var top=bounds.end.y-building.global_position.y
	if width<4 or depth<4 or top<2: return
	var dressed=Node3D.new()
	dressed.name="StreetLife_%d"%index
	building.add_child(dressed)
	var entrance_x=0.0
	if building.has_meta("entrance_local"): entrance_x=float(building.get_meta("entrance_local").x)
	var commerce=_has(title,COMMERCE)
	var tea=_has(title,TEA_WORDS)
	var tech=_has(title,TECH_WORDS)
	if "MARKET" in title or "HALL" in title: commerce=true
	_rooftop(dressed,width,depth,top,tech)
	if commerce or tech:
		var colour=neon_palette[index%neon_palette.size()]
		_neon_front(dressed,width,depth,top,entrance_x,colour,title)
		_vending(dressed,width,depth,entrance_x,index)
	if tea:
		_tea_set(dressed,depth,entrance_x,index)
		_food_cart(dressed,width,depth,index)
	var floors=maxi(1,int(round(top/3.1)))
	var residential=_has(title,["APARTMENT","DORM","RESIDENCE","HOME","FAMILY"])
	_facade_variety(dressed,width,depth,top,floors,title,index,commerce,residential)
	_street_props(dressed,width,depth,index,commerce)
	if tech or "TECH" in title:
		_hologram(dressed,width,depth,top,colour_for(index+2),"TECH")
	elif commerce and index%3==0:
		_billboard(dressed,width,depth,top,colour_for(index+1),title)

func colour_for(index: int) -> String:
	return neon_palette[index%neon_palette.size()]

func _neon_front(parent: Node3D,width: float,depth: float,top: float,entrance_x: float,colour: String,title: String) -> void:
	var front=depth/2
	var floors=maxi(1,int(top/3.0))
	var band=neon(colour,3.2)
	# Fascia board above the door, tilted toward the high camera so it reads from above.
	var fascia=Node3D.new()
	fascia.name="FasciaBoard"
	fascia.position=Vector3(entrance_x,3.9,front+0.45)
	fascia.rotation_degrees.x=-38
	parent.add_child(fascia)
	var board_w=minf(width*0.6,11.0)
	_box(fascia,Vector3(0,0,0),Vector3(board_w,1.1,0.16),dark,"FasciaBacking")
	_box(fascia,Vector3(0,0.5,0.1),Vector3(board_w-0.2,0.08,0.05),band,"NeonFasciaTop")
	_box(fascia,Vector3(0,-0.5,0.1),Vector3(board_w-0.2,0.08,0.05),band,"NeonFasciaBottom")
	# Vertical blade sign on the corner, taller on taller buildings.
	var blade_h=clampf(top*0.55,2.6,9.0)
	var side=-1.0 if rng.randf()<0.5 else 1.0
	var x=side*(width/2-0.9)
	var blade_colour=colour_for(neon_palette.find(colour)+1)
	var blade=neon(blade_colour,3.6)
	_box(parent,Vector3(x,3.0+blade_h/2,front+0.85),Vector3(0.14,blade_h,1.5),dark,"BladeBacking")
	for face in [-1,1]:
		_box(parent,Vector3(x+face*0.09,3.0+blade_h/2,front+0.85),Vector3(0.05,blade_h-0.4,1.1),blade,"NeonBlade")
	_light(parent,Vector3(x,3.5,front+2.0),blade_colour,0.9,7.0)
	# A short name plate in Burmese where it is a tea shop, otherwise the English role.
	var label=Label3D.new()
	label.name="NeonText"
	label.text="လက်ဖက်ရည်" if "TEA" in title else ("မုန့်ဟင်းခါး" if "MOHINGA" in title else title.get_slice(" / ",0).capitalize())
	label.font_size=64
	label.pixel_size=0.011
	label.modulate=Color(colour).lightened(0.35)
	label.outline_size=0
	label.position=Vector3(0,0,0.13)
	fascia.add_child(label)
	# Hanging lantern/bunting string across the front.
	var lantern=neon("ffb84a",2.4)
	for i in range(7):
		var lx=-width*0.4+i*width*0.8/6.0
		_box(parent,Vector3(lx,3.0+0.2*sin(i*1.4),front+1.1),Vector3(0.22,0.3,0.22),lantern,"Lantern")
	counts.neon+=1

func _rooftop(parent: Node3D,width: float,depth: float,top: float,tech: bool) -> void:
	var count=2+rng.randi_range(0,2)
	var antenna_mat=neon("ff2a2a",4.0)
	for i in range(count):
		var x=rng.randf_range(-width/2+2.0,width/2-2.0)
		var z=rng.randf_range(-depth/2+2.0,depth*0.15)
		var kind=rng.randi_range(0,3)
		var y=top+0.35
		if kind==0:
			_box(parent,Vector3(x,y+0.45,z),Vector3(1.5,0.9,1.1),grey,"AirCon")
			_cyl(parent,Vector3(x,y+0.93,z),0.42,0.08,dark,"AirConFan")
		elif kind==1:
			var stack=_cyl(parent,Vector3(x,y+0.8,z),0.26,1.6,steel,"VentStack")
			_cyl(parent,Vector3(x,y+1.7,z),0.42,0.14,dark,"VentCap")
			stack.rotation_degrees.z=rng.randf_range(-4,4)
		elif kind==2:
			for leg in [Vector2(-0.6,-0.6),Vector2(0.6,-0.6),Vector2(-0.6,0.6),Vector2(0.6,0.6)]:
				_cyl(parent,Vector3(x+leg.x,y+0.5,z+leg.y),0.07,1.0,dark,"TankLeg")
			_cyl(parent,Vector3(x,y+1.8,z),0.95,1.6,steel,"WaterTank")
		else:
			_cyl(parent,Vector3(x,y+2.4,z),0.05,4.8,dark,"Antenna")
			_box(parent,Vector3(x,y+4.8,z),Vector3(0.18,0.18,0.18),antenna_mat,"BeaconLight")
			var dish=MeshInstance3D.new()
			var sphere=SphereMesh.new()
			sphere.radius=0.55
			sphere.height=0.5
			dish.mesh=sphere
			dish.material_override=steel
			dish.position=Vector3(x+1.1,y+0.8,z)
			dish.rotation_degrees=Vector3(-50,rng.randf_range(0,360),0)
			parent.add_child(dish)
	roofs.append({"parent":parent,"top":top,"width":width,"depth":depth})
	counts.roof+=1

func _vending(parent: Node3D,width: float,depth: float,entrance_x: float,index: int) -> void:
	var x=entrance_x+(2.8 if index%2==0 else -2.8)
	if absf(x)>width/2-1: x=clampf(x,-width/2+1.0,width/2-1.0)
	var front=_neon_face(index)
	_solid(_box(parent,Vector3(x,0.95,depth/2+0.55),Vector3(0.95,1.9,0.8),dark,"VendingBody"))
	_box(parent,Vector3(x,1.1,depth/2+0.97),Vector3(0.75,1.3,0.05),front,"VendingFace")
	_solid(_box(parent,Vector3(x+1.0,0.95,depth/2+0.55),Vector3(0.95,1.9,0.8),dark,"VendingBody"))
	_box(parent,Vector3(x+1.0,1.1,depth/2+0.97),Vector3(0.75,1.3,0.05),_neon_face(index+1),"VendingFace")
	counts.vending+=2

func _neon_face(index: int) -> StandardMaterial3D:
	return neon(colour_for(index+3),1.8)

func _tea_set(parent: Node3D,depth: float,entrance_x: float,index: int) -> void:
	for set_index in range(3):
		var cx=entrance_x+(set_index-1)*4.0
		var cz=depth/2+3.3+(set_index%2)*0.6
		_cyl(parent,Vector3(cx,0.24,cz),0.42,0.48,stool_materials[(index+set_index)%4],"LowTable")
		for stool in range(4):
			var angle=stool*PI/2+rng.randf_range(-0.3,0.3)
			var at=Vector3(cx+cos(angle)*0.9,0.17,cz+sin(angle)*0.9)
			_cyl(parent,at,0.21,0.34,stool_materials[(index+set_index+stool+1)%4],"PlasticStool")
			counts.stools+=1

func _food_cart(parent: Node3D,width: float,depth: float,index: int) -> void:
	var side=-1.0 if index%2==0 else 1.0
	var x=side*(width/2-2.2)
	var z=depth/2+3.6
	var umbrella: Material=umbrella_materials[index%4]
	_solid(_box(parent,Vector3(x,0.55,z),Vector3(1.7,0.9,0.9),world._mat("4a8f93",0.6),"FoodCart"))
	cyber_steam(parent,Vector3(x,1.3,z))
	_box(parent,Vector3(x,1.05,z),Vector3(1.75,0.12,0.95),steel,"CartCounter")
	for post in [-0.8,0.8]:
		_cyl(parent,Vector3(x+post,1.6,z-0.35),0.04,2.2,dark,"CartPost")
	_box(parent,Vector3(x,2.75,z-0.1),Vector3(2.4,0.1,1.6),umbrella,"CartCanopy")
	_box(parent,Vector3(x,2.55,z+0.7),Vector3(0.28,0.28,0.28),neon("ffb84a",3.0),"CartLantern")
	_light(parent,Vector3(x,2.4,z+0.8),"ffb070",0.8,5.5)
	counts.carts+=1

func _hologram(parent: Node3D,width: float,depth: float,top: float,colour: String,text: String) -> void:
	var holo=ShaderMaterial.new()
	holo.shader=load("res://shaders/hologram_sign.gdshader")
	holo.set_shader_parameter("holo_colour",Color(colour))
	holo_materials.append(holo)
	var quad=MeshInstance3D.new()
	var mesh=QuadMesh.new()
	mesh.size=Vector2(6.0,3.4)
	quad.mesh=mesh
	quad.material_override=holo
	quad.name="HologramSign"
	quad.position=Vector3(clampf(width*0.25,-width/2+3.5,width/2-3.5),top+4.6,depth/2-0.8)
	quad.rotation_degrees.x=-12
	quad.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(quad)
	for post in [-1,1]:
		_box(parent,Vector3(quad.position.x+post*2.6,top+2.2,quad.position.z),Vector3(0.12,4.4,0.12),dark,"HologramPost")
	var label=Label3D.new()
	label.text=text
	label.font_size=110
	label.pixel_size=0.017
	label.modulate=Color(colour).lightened(0.5)
	label.position=quad.position+Vector3(0,0,0.05)
	label.rotation_degrees.x=-12
	label.no_depth_test=false
	label.shaded=false
	parent.add_child(label)
	_light(parent,quad.position+Vector3(0,-0.5,1.5),colour,1.2,9.0)
	counts.holo+=1

func _cables() -> void:
	var tops: Array=[]
	for entry in roofs:
		var parent: Node3D=entry.parent
		tops.append({"point":parent.global_position+Vector3(rng.randf_range(-3,3),entry.top+0.8,entry.depth*0.1),"top":entry.top})
	for i in range(tops.size()):
		for j in range(i+1,tops.size()):
			if cable_budget<=0: return
			var a: Vector3=tops[i].point
			var b: Vector3=tops[j].point
			var distance=Vector2(a.x,a.z).distance_to(Vector2(b.x,b.z))
			if distance<8.0 or distance>30.0: continue
			if absf(a.y-b.y)>10.0: continue
			_catenary(a,b)
			cable_budget-=1
			counts.cables+=1

func _catenary(a: Vector3,b: Vector3) -> void:
	var segments=7
	var previous=a
	var sag=clampf(a.distance_to(b)*0.06,0.5,2.0)
	for s in range(1,segments+1):
		var t=float(s)/segments
		var point=a.lerp(b,t)
		point.y-=sag*4.0*t*(1.0-t)
		world._bar(previous,point,0.03,cable_material)
		previous=point


func _facade_variety(parent: Node3D,width: float,depth: float,top: float,floors: int,title: String,index: int,commerce: bool,residential: bool) -> void:
	var front=depth/2
	var accent: Material=accent_materials[index%accent_materials.size()]
	var style=index%4
	# Vertical fins and floor bands vary the plain facade and the silhouette.
	if style==0 or style==2:
		var fins=int(width/2.6)
		for i in range(fins):
			var x=-width/2+1.3+i*(width-2.6)/maxf(1,fins-1)
			if top>5.5: _box(parent,Vector3(x,(3.4+top-0.3)*0.5,front+0.16),Vector3(0.12,top-3.7,0.3),accent,"FacadeFin")
	if style==1 or style==3:
		for floor_index in range(1,floors):
			_box(parent,Vector3(0,floor_index*3.1+0.05,front+0.35),Vector3(width+0.6,0.3,0.9),accent,"FloorBand")
	# Stepped penthouse volume on taller buildings, set back from the edge.
	if floors>=2 and index%3!=1:
		var pw=width*rng.randf_range(0.35,0.55)
		var pd=depth*rng.randf_range(0.35,0.5)
		var px=rng.randf_range(-width*0.2,width*0.2)
		_box(parent,Vector3(px,top+1.7,-depth*0.12),Vector3(pw,3.2,pd),accent,"Penthouse")
		_box(parent,Vector3(px,top+3.4,-depth*0.12),Vector3(pw+0.6,0.3,pd+0.6),dark,"PenthouseRoof")
		_box(parent,Vector3(px,top+1.9,-depth*0.12+pd/2+0.03),Vector3(pw-0.8,1.4,0.06),neon("ffcf8a",1.8),"emit_penthouse_window")
	# Striped shop awnings either side of the door.
	if commerce:
		for side in [-1,1]:
			var awning=_box(parent,Vector3(side*width*0.27,2.6,front+0.95),Vector3(width*0.2,0.12,1.4),accent_materials[(index+side+3)%accent_materials.size()],"ShopAwning")
			awning.rotation_degrees.x=14
	# Residential balconies: AC units and washing lines.
	if residential:
		for floor_index in range(1,mini(floors,5)):
			var y=floor_index*3.1+0.9
			for k in range(2):
				var x=(-0.28+0.56*k)*width+rng.randf_range(-1,1)
				_box(parent,Vector3(x,y-0.7,front+0.7),Vector3(width*0.2,0.14,1.3),grey,"BalconySlab")
				_box(parent,Vector3(x,y-0.1,front+1.28),Vector3(width*0.2,0.9,0.05),dark,"BalconyRail")
				_box(parent,Vector3(x+width*0.07,y+0.2,front+0.6),Vector3(0.9,0.55,0.55),grey,"BalconyAirCon")
				for line in range(3):
					var lx=x-width*0.07+line*0.7
					_box(parent,Vector3(lx,y+0.55,front+1.0),Vector3(0.5,0.85,0.03),laundry_materials[(index+floor_index+k+line)%laundry_materials.size()],"HangingLaundry")
				_box(parent,Vector3(x,y+1.0,front+1.0),Vector3(width*0.2,0.03,0.03),dark,"WashingLine")

func _billboard(parent: Node3D,width: float,depth: float,top: float,colour: String,title: String) -> void:
	var w=minf(width*0.55,9.0)
	var x=rng.randf_range(-width*0.15,width*0.15)
	var board=Node3D.new()
	board.name="RooftopBillboard"
	board.position=Vector3(x,top+2.4,depth/2-1.0)
	board.rotation_degrees.x=-14
	parent.add_child(board)
	_box(board,Vector3.ZERO,Vector3(w,2.6,0.2),dark,"BillboardBack")
	_box(board,Vector3(0,0,0.13),Vector3(w-0.3,2.3,0.05),neon(colour,2.6),"BillboardPanel")
	var label=Label3D.new()
	label.text=title.get_slice(" / ",0).capitalize()
	label.font_size=80
	label.pixel_size=0.016
	label.modulate=Color("101418")
	label.position=Vector3(0,0,0.18)
	label.shaded=false
	board.add_child(label)
	for post in [-1,1]: _box(parent,Vector3(x+post*w*0.4,top+0.9,depth/2-1.2),Vector3(0.14,1.8,0.14),dark,"BillboardPost")
	counts.neon+=1

func _street_props(parent: Node3D,width: float,depth: float,index: int,commerce: bool) -> void:
	var front=depth/2
	# Parked scooters beside the entrance, bins, stacked crates and poster panels on side walls.
	var scooter_colours=["c8473d","3d7fd6","e2b33d","3fae6a","d8d4c8"]
	for k in range(2 if commerce else 1):
		var x=-width*0.32+k*1.4+rng.randf_range(-0.5,0.5)
		var z=front+4.9
		var paint=world._mat(scooter_colours[(index+k)%5],0.5)
		var scooter=Node3D.new()
		scooter.name="ParkedScooter"
		scooter.position=Vector3(x,0,z)
		scooter.rotation_degrees.y=rng.randf_range(-25,25)+90*float(k%2)
		parent.add_child(scooter)
		_box(scooter,Vector3(0,0.55,0),Vector3(0.35,0.35,1.4),paint,"ScooterBody")
		_box(scooter,Vector3(0,0.78,-0.15),Vector3(0.34,0.1,0.55),dark,"ScooterSeat")
		_box(scooter,Vector3(0,0.95,0.55),Vector3(0.6,0.06,0.06),dark,"ScooterBars")
		for wz in [-0.55,0.55]:
			var wheel=_cyl(scooter,Vector3(0,0.28,wz),0.28,0.12,dark,"ScooterWheel")
			wheel.rotation_degrees.z=90
		_box(scooter,Vector3(0,0.78,0.72),Vector3(0.18,0.14,0.08),neon("fff2c0",2.0),"ScooterLight")
	if commerce:
		_solid(_box(parent,Vector3(width/2-0.8,0.5,front+1.6),Vector3(0.7,1.0,0.7),world._mat("3f8f5a",0.8),"BinGreen"))
		_solid(_box(parent,Vector3(width/2-1.6,0.5,front+1.6),Vector3(0.7,1.0,0.7),world._mat("3a6fa8",0.8),"BinBlue"))
		for k in range(3):
			_solid(_box(parent,Vector3(-width/2+1.2+(k%2)*0.9,0.3+(k/2)*0.55,front+1.5),Vector3(0.85,0.55,0.85),accent_materials[(index+k)%accent_materials.size()],"CrateStack"))
	# Posters on the side walls.
	for k in range(2):
		var side=-1.0 if (index+k)%2==0 else 1.0
		_box(parent,Vector3(side*(width/2+0.06),2.2+0.2*k,rng.randf_range(-depth*0.3,depth*0.3)),Vector3(0.05,1.8,1.2),neon(colour_for(index+k+1),1.4),"WallPoster")


func _solid(node: MeshInstance3D) -> MeshInstance3D:
	var body=StaticBody3D.new()
	var shape=CollisionShape3D.new()
	var box=BoxShape3D.new()
	box.size=(node.mesh as BoxMesh).size
	shape.shape=box
	body.add_child(shape)
	node.add_child(body)
	return node

var pending_steam: Array=[]
func cyber_steam(parent: Node3D,at: Vector3) -> void:
	# Food carts are dressed before the cyber pass exists; steam is attached once it does.
	if cyber: cyber._steam(parent,at)
	else: pending_steam.append([parent,at])

func _atmosphere(night: bool) -> void:
	var environment: Environment=world.environment
	if environment==null: return
	if pending_steam.size()>0 and cyber:
		for entry in pending_steam: cyber._steam(entry[0],entry[1])
		pending_steam.clear()
	if night:
		# Deeper indigo night, faint violet haze and stronger bloom so neon carries.
		environment.background_color=Color("1b1f3c")
		environment.ambient_light_color=Color("7f88c8")
		environment.ambient_light_energy=0.34
		environment.fog_density=0.0007
		environment.fog_light_color=Color("241f4a")
		environment.glow_intensity=0.95
		environment.glow_bloom=0.12
	else:
		environment.fog_density=0.000004
		environment.fog_light_color=Color("526c86")
		environment.glow_intensity=0.65
		environment.glow_bloom=0.08
