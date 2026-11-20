extends RefCounted
## Purpose-furnished cutaway interiors. Furniture is geometry, never image sprites.
var b
var room: Node3D
var world
var wood: Material
var upholstery: Material
var white: Material
var metal: Material
var glass: Material
var accent: Material
var props=0
var width=20.0
var depth=18.0

func make(owner_world,title: String,variant: int) -> Node3D:
	world=owner_world
	b=load("res://scripts/reference_buildings.gd").new()
	b.world=world
	wood=world._mat("99764f")
	upholstery=world._mat("477a79")
	white=world._mat("b3c0b8")
	metal=world._mat("3d5661",0.6)
	glass=world._mat("2b536b",0.3)
	accent=world._mat(["608c87","93749d","b28861","698866"][variant%4])
	room=Node3D.new()
	room.name="Interior_"+str(variant)
	var theme=theme_for(title)
	if theme=="market": width=28; depth=24
	elif theme=="workshop": width=24; depth=22
	room.set_meta("theme",theme)
	room.set_meta("building_title",title)
	room.set_meta("room_width",width)
	room.set_meta("room_depth",depth)
	# Real walls enforce the room bounds. The near wall is cut away visually.
	piece("Floor",Vector3(0,-0.15,0),Vector3(width,0.3,depth),world._mat("546c71"),true)
	piece("Backdrop",Vector3(0,-0.4,0),Vector3(90,0.1,90),world._mat("182c38"))
	piece("NorthWall",Vector3(0,1.7,-depth/2),Vector3(width,3.4,0.25),white,true)
	for side in [-1,1]: piece("SideWall",Vector3(side*width/2,1.7,0),Vector3(0.25,3.4,depth),accent,true)
	piece("CutawayFrontWall",Vector3(0,0.35,depth/2),Vector3(width,0.7,0.25),metal)
	var boundary=StaticBody3D.new()
	boundary.name="FrontBoundary"
	var shape=CollisionShape3D.new()
	var geometry=BoxShape3D.new()
	geometry.size=Vector3(width,3.4,0.25)
	shape.shape=geometry
	boundary.add_child(shape)
	boundary.position=Vector3(0,1.7,depth/2)
	room.add_child(boundary)
	for side in [-1,1]:
		piece("Window",Vector3(side*width*0.27,2.1,-depth/2+0.17),Vector3(width*0.25,1.8,0.08),glass)
		piece("WindowFrame",Vector3(side*width*0.27,3.05,-depth/2+0.2),Vector3(width*0.27,0.12,0.15),metal)
	if theme not in ["classroom","workshop","market","cafe"]:
		label(title,Vector3(0,3.15,-depth/2+0.3),0.011)
	label("EXIT [E]",Vector3(0,2.4,depth/2-0.35),0.014)
	piece("ExitDoor",Vector3(0,1.15,depth/2-0.12),Vector3(2,2.3,0.13),glass)
	piece("WelcomeMat",Vector3(0,0.025,depth/2-1.7),Vector3(2.8,0.05,2),accent)
	match theme:
		"home": home()
		"classroom": classroom("PILOT" in title)
		"cafe": cafe()
		"clinic": clinic()
		"workshop": workshop("ENGINEERING" in title or "HANGAR" in title)
		"market": market(title)
		"shop": shop(title)
		"laundry": laundry()
		"office": office()
		"warehouse": warehouse()
	for side in [-1,1]:
		plant(Vector3(side*(width/2-1),0,depth/2-1.4))
		var light=OmniLight3D.new()
		light.name="WarmRoomLight"
		light.position=Vector3(side*width*0.24,3.1,0)
		light.light_color=Color("ffd4a1")
		light.light_energy=1.5
		light.omni_range=18
		room.add_child(light)
		piece("CeilingLight",Vector3(side*width*0.24,3.2,-depth/2+0.4),Vector3(2.2,0.12,0.15),world._mat("ffd8a3",0.5,1.5))
	room.set_meta("furniture_count",props)
	return room

func theme_for(title: String) -> String:
	if "WHOLESALE" in title or "DELIVERY" in title: return "warehouse"
	if "FAMILY" in title or "DORM" in title or "APARTMENT" in title or "HOME" in title: return "home"
	if "CLASSROOM" in title or "PILOT SCHOOL" in title: return "classroom"
	if "CLINIC" in title: return "clinic"
	if "HANGAR" in title or "ENGINEERING" in title or "REPAIR" in title or "ROBOT WORKSHOP" in title: return "workshop"
	if "MARKET" in title or "CLOTHING / CRAFTS" in title or "FOOD QUARTER" in title or "TECH / ROBOT PARTS" in title: return "market"
	if "LAUNDRY" in title: return "laundry"
	if "TEA" in title or "CAFE" in title or "FOOD" in title or "COMMONS" in title: return "cafe"
	if "ARCADE" in title or "BOOK" in title or "SHOP" in title: return "shop"
	return "office"

func piece(title: String,pos: Vector3,size: Vector3,mat: Material,solid=false) -> MeshInstance3D:
	props+=1
	return b.box(room,pos,size,mat,title,solid)

func label(text: String,pos: Vector3,pixel_size=0.018) -> void:
	var sign=Label3D.new()
	sign.text=text
	sign.position=pos
	sign.pixel_size=pixel_size
	sign.font_size=40
	room.add_child(sign)

func plant(pos: Vector3) -> void:
	b.cylinder(room,pos+Vector3.UP*0.3,0.4,0.6,wood,"PlantPot")
	var node=MeshInstance3D.new()
	var mesh=SphereMesh.new()
	mesh.radius=0.6
	mesh.height=1.5
	node.mesh=mesh
	node.material_override=world.mats.leaf
	node.position=pos+Vector3.UP*1.1
	room.add_child(node)

func table(pos: Vector3,w=2.4,d=1.2,title="Table") -> void:
	piece(title,pos+Vector3.UP*0.85,Vector3(w,0.16,d),wood,true)
	for side in [-1,1]: piece("TableLeg",pos+Vector3(side*w*0.35,0.4,0),Vector3(0.13,0.8,0.8),metal)

func chair(pos: Vector3,back=true) -> void:
	piece("ChairSeat",pos+Vector3.UP*0.45,Vector3(0.7,0.13,0.7),upholstery,true)
	if back: piece("ChairBack",pos+Vector3(0,0.85,0.3),Vector3(0.7,0.8,0.1),upholstery)
	for x in [-0.25,0.25]: piece("ChairLeg",pos+Vector3(x,0.2,0),Vector3(0.08,0.4,0.5),metal)

func monitor(pos: Vector3) -> void:
	piece("Monitor",pos+Vector3(0,1.32,-0.25),Vector3(1.1,0.65,0.12),metal)
	piece("Screen",pos+Vector3(0,1.32,-0.17),Vector3(0.95,0.5,0.04),world.mats.cyan)
	piece("Keyboard",pos+Vector3(0,0.97,0.2),Vector3(0.8,0.06,0.3),metal)

func shelf(pos: Vector3,books=false) -> void:
	piece("ShelfBack",pos+Vector3.UP*1.35,Vector3(2.8,2.7,0.18),metal,true)
	for level in range(3):
		piece("Shelf",pos+Vector3(0,0.35+level*0.85,0.35),Vector3(2.9,0.12,0.9),wood,true)
		for i in range(5): piece("Book" if books else "PackagedGoods",pos+Vector3(-1.05+i*0.5,0.7+level*0.85,0.3),Vector3(0.23 if books else 0.38,0.6 if books else 0.45,0.45),accent if i%2==0 else upholstery)

func bed(pos: Vector3) -> void:
	piece("BedFrame",pos+Vector3.UP*0.35,Vector3(2.2,0.7,3.8),wood,true)
	piece("Mattress",pos+Vector3.UP*0.8,Vector3(2.1,0.3,3.6),white)
	piece("Blanket",pos+Vector3(0,1.0,0.4),Vector3(2.15,0.15,2.5),upholstery)
	piece("Pillow",pos+Vector3(0,1.05,-1.1),Vector3(1.6,0.2,0.6),white)

func home() -> void:
	bed(Vector3(6,0,-4.5))
	piece("Wardrobe",Vector3(8,1.3,-6),Vector3(2.5,2.6,1.2),wood,true)
	piece("BedroomPartition",Vector3(3.2,1.65,-4.5),Vector3(0.15,3.3,6),white,true)
	piece("SofaBase",Vector3(-6,0.5,2),Vector3(4.6,0.65,1.5),upholstery,true)
	piece("SofaBack",Vector3(-6,1.1,2.6),Vector3(4.6,0.9,0.3),upholstery)
	table(Vector3(-6,0,-0.2),2.7,1.3,"CoffeeTable")
	table(Vector3(6,0,2),3,1.4,"StudyDesk")
	monitor(Vector3(6,0,2))
	chair(Vector3(6,0,3.1))
	piece("KitchenCounter",Vector3(-6,0.7,-6.5),Vector3(5,1.4,1.5),wood,true)
	piece("Sink",Vector3(-6,1.45,-6.5),Vector3(1.2,0.08,0.9),metal)
	piece("Cooktop",Vector3(-4.3,1.45,-6.5),Vector3(1.1,0.08,0.8),glass)
	piece("Fridge",Vector3(-8.8,1.1,-5.8),Vector3(1.2,2.2,1.3),white,true)
	label("FAMILY KITCHEN",Vector3(-6,2.7,-8.6))

func classroom(piloting: bool) -> void:
	piece("TeachingScreen",Vector3(0,2.1,-8.7),Vector3(7,1.8,0.15),metal)
	label("PILOT SYSTEMS" if piloting else "YUST CLASSROOM",Vector3(0,2.2,-8.55))
	table(Vector3(-4,0,-6.2),3,1.2,"InstructorDesk")
	monitor(Vector3(-4,0,-6.2))
	for x in [-6,-3,3,6]:
		for z in [-3,0,3]:
			table(Vector3(x,0,z),2,1,"StudentDesk")
			chair(Vector3(x,0,z+0.85))
			piece("StudyTablet",Vector3(x,0.98,z),Vector3(0.6,0.08,0.4),glass)
	if piloting:
		for x in [-8,8]:
			piece("SimulatorPod",Vector3(x,1.1,-6.5),Vector3(1.5,2.2,2),upholstery,true)
			piece("SimulatorScreen",Vector3(x,1.8,-5.4),Vector3(1.2,0.9,0.15),world.mats.cyan)

func cafe() -> void:
	piece("TeaCounter",Vector3(-3,0.7,-6.3),Vector3(8,1.4,1.6),wood,true)
	piece("KitchenCabinet",Vector3(6,1.1,-6.6),Vector3(3,2.2,1.4),metal,true)
	for i in range(6): b.cylinder(room,Vector3(-6+i,1.6,-6.3),0.15,0.25,white,"TeaCup")
	label("TEA / SNACKS",Vector3(-3,2.6,-8.6))
	for x in [-5,5]:
		for z in [-2,2,5]:
			table(Vector3(x,0,z),2,1.3,"CafeTable")
			chair(Vector3(x-1.3,0,z),false)
			chair(Vector3(x+1.3,0,z),false)
			b.cylinder(room,Vector3(x,1.03,z),0.12,0.2,white,"TeaCup")

func clinic() -> void:
	table(Vector3(-5,0,4),5,1.5,"ReceptionDesk")
	monitor(Vector3(-5,0,4))
	for z in [0,2,4]: chair(Vector3(7,0,z))
	for x in [-5,5]:
		bed(Vector3(x,0,-4))
		piece("PrivacyScreen",Vector3(x+(2.2 if x<0 else -2.2),1.4,-4),Vector3(0.12,2.8,4),upholstery,true)
		piece("MedicalCabinet",Vector3(x,1.2,-7.7),Vector3(2.5,2.4,0.7),white,true)
		label("EXAM ROOM",Vector3(x,3,-8.5),0.012)

func workshop(hangar: bool) -> void:
	for x in [-7,7]:
		table(Vector3(x,0,1),4.5,2,"EngineeringWorkbench")
		monitor(Vector3(x,0,1))
		shelf(Vector3(x,0,-8))
		for i in range(4): piece("Tool",Vector3(x-1.4+i*0.8,1.0,1.4),Vector3(0.5,0.08,0.2),metal)
	var origin=Vector3(-6,0,-5)
	piece("TrainingFramePlatform",origin+Vector3.UP*0.15,Vector3(4,0.3,4),metal,true)
	for side in [-1,1]:
		piece("FrameLeg",origin+Vector3(side*0.6,1.4,0),Vector3(0.65,2.5,0.9),upholstery)
		piece("FrameArm",origin+Vector3(side*1.4,3.2,0),Vector3(0.6,2,0.7),white)
	piece("TrainingFrameBody",origin+Vector3(0,3.2,0),Vector3(2,1.8,1.2),white,true)
	piece("FrameHead",origin+Vector3(0,4.6,0),Vector3(0.8,0.8,0.8),metal)
	piece("FrameVisor",origin+Vector3(0,4.6,0.45),Vector3(0.6,0.2,0.06),world.mats.cyan)
	label("TRAINING BAY" if hangar else "FRAME / ROBOT REPAIR",Vector3(0,3,-10.6))

func market(title: String) -> void:
	var textiles="CLOTHING" in title
	var electronics="TECH" in title
	for x in [-9,-5,5,9]:
		for z in [-6,0,5]:
			table(Vector3(x,0,z),3,1.7,"VendorCounter")
			if electronics: monitor(Vector3(x,0,z))
			elif textiles:
				piece("ClothingRack",Vector3(x,2,z),Vector3(2.6,0.1,0.1),metal)
				for i in range(3): piece("DisplayedGarment",Vector3(x-0.8+i*0.8,1.5,z),Vector3(0.6,0.9,0.2),accent if i%2==0 else upholstery)
			else:
				for i in range(5): b.cylinder(room,Vector3(x-1+i*0.5,1.1,z),0.2,0.3,world.mats.leaf if i%2 else wood,"ProduceBasket")
	label(title,Vector3(0,3,-11.6),0.014)

func shop(title: String) -> void:
	for x in [-6,-3,3,6]: shelf(Vector3(x,0,-4),"BOOK" in title)
	table(Vector3(-6,0,4.5),4,1.5,"Checkout")
	monitor(Vector3(-6,0,4.5))
	if "ARCADE" in title:
		for x in [-7,-4,4,7]:
			piece("ArcadeCabinet",Vector3(x,1.2,0),Vector3(1.4,2.4,1.2),accent,true)
			piece("GameDisplay",Vector3(x,1.7,0.65),Vector3(1.15,0.9,0.1),world.mats.cyan)

func laundry() -> void:
	for x in [-7,-4,4,7]:
		piece("WashingMachine",Vector3(x,0.7,-5),Vector3(2.3,1.4,2),white,true)
		var door=b.cylinder(room,Vector3(x,0.75,-3.9),0.5,0.15,glass,"WasherPorthole")
		door.rotation.x=PI/2
		piece("Dryer",Vector3(x,2.1,-5),Vector3(2.3,1.4,2),metal,true)
	table(Vector3(-5,0,1),5,2,"FoldingTable")
	for x in [-6,-4]: piece("FoldedClothes",Vector3(x,1.07,1),Vector3(1,0.25,0.8),upholstery)
	for z in [0,2,4]: chair(Vector3(7,0,z))

func office() -> void:
	for x in [-5,5]:
		for z in [-4,2]:
			table(Vector3(x,0,z),3,1.5,"OfficeDesk")
			monitor(Vector3(x,0,z))
			chair(Vector3(x,0,z+1.2))
	for x in [-6,6]: shelf(Vector3(x,0,-7.5),true)

func warehouse() -> void:
	for x in [-6,-3,3,6]:
		shelf(Vector3(x,0,-6))
		for z in [-2,2]:
			piece("StoragePallet",Vector3(x,0.1,z),Vector3(2.3,0.2,2),wood,true)
			piece("StorageCrate",Vector3(x,0.8,z),Vector3(1.8,1.4,1.6),accent,true)
	table(Vector3(-6,0,5),3,1.2,"DispatchDesk")
	monitor(Vector3(-6,0,5))
