extends RefCounted
## Replace an individual root with a finished GLB; footprint and ID stay stable.
const Layout = preload("res://scripts/terrain_layout.gd")
var world
var district: Node3D
var wall: StandardMaterial3D
var glass: StandardMaterial3D
var warm: StandardMaterial3D
var roof_material: StandardMaterial3D
var accents: Array = []
var count = 0

func setup(owner_world) -> void:
	world = owner_world
	district = Node3D.new()
	district.name = "PrototypeBuildings"
	world.add_child(district)
	wall = world._mat("829491")
	roof_material = world._mat("526a73")
	glass = world._mat("355967",0.25)
	warm = world._mat("eac28b",0.5,0.18)
	for colour in ["438b91","d39a64","718eaa","809a78"]:
		accents.append(world._mat(colour))
	for entry in world.building_plots:
		var title: String = entry.label
		if title=="ROBOT WORKSHOP": continue # Downloaded complex.
		var open_space = false
		for word in ["GARDEN","COURT","LAWN","PLAYGROUND","PARKING"]:
			if word in title: open_space=true
		if open_space: continue
		if "TRANSIT" in title or "TRAM" in title:
			shelter(entry.plot,title)
		elif entry.plot.size.x>80:
			# Separate market halls with open lanes between them.
			var plot: Rect2 = entry.plot
			var n = 3
			for i in range(n):
				build(Rect2(plot.position+Vector2(i*plot.size.x/n,0),Vector2(plot.size.x/n-3,plot.size.y)),title,1)
		else:
			var floors = 1
			if "APARTMENT" in title or "FAMILY" in title: floors=6
			elif "CLINIC" in title: floors=3
			elif "REPAIR" in title or "ARCADE" in title: floors=2
			build(entry.plot,title,floors)
	print("PROTOTYPE_BUILDINGS_READY: ",count)

func box(parent: Node3D, at: Vector3, size: Vector3, mat: Material, title: String, solid=false) -> MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = size
	var node = MeshInstance3D.new()
	node.name = title
	node.mesh = mesh
	node.material_override = mat
	node.position = at
	parent.add_child(node)
	if solid:
		var body = StaticBody3D.new()
		var shape = CollisionShape3D.new()
		var geometry = BoxShape3D.new()
		geometry.size = size
		shape.shape = geometry
		body.add_child(shape)
		node.add_child(body)
	return node

func root_for(plot: Rect2, title: String) -> Node3D:
	var node = Node3D.new()
	node.name = "Placeholder_%02d" % count
	node.set_meta("replacement_id",node.name)
	node.set_meta("building_use",title)
	node.set_meta("reserved_plot",plot)
	district.add_child(node)
	var c = plot.get_center()
	node.position = Vector3(c.x,Layout.height_at(c.x,c.y)+0.12,c.y)
	world.grass_exclusions.append(plot)
	count+=1
	return node

func sign_on(parent: Node3D, title: String, at: Vector3) -> void:
	var sign = Label3D.new()
	sign.name = "ReplaceableSign"
	sign.text = title
	sign.font_size = 48
	sign.pixel_size = 0.014
	sign.position = at
	sign.modulate = Color("ecf5e6")
	sign.outline_size = 5
	sign.no_depth_test = false
	parent.add_child(sign)

func planter(parent: Node3D, at: Vector3) -> void:
	box(parent,at+Vector3(0,0.35,0),Vector3(2.4,0.7,1.2),world.mats.metal,"Planter")
	box(parent,at+Vector3(0,0.95,0),Vector3(2.0,0.7,0.9),world.mats.leaf,"TropicalPlant")

func build(plot: Rect2, title: String, floors: int) -> void:
	var root = root_for(plot,title)
	var variant = count-1
	var style = style_for(title)
	# Stable, visibly different proportions even for neighbouring market halls.
	var width = minf(plot.size.x-8,26) * (0.83+0.017*(variant%10))
	var depth = minf(plot.size.y-9,20) * (0.82+0.027*(variant%7))
	var storey = 3.1+0.09*(variant%5)
	var height = floors*storey
	root.set_meta("architectural_style",style)
	root.set_meta("design_variant",variant)
	var accent: Material = accents[count%accents.size()]
	# Foundation covers minor terrain grade; all decoration remains inside its plot.
	box(root,Vector3(0,-0.4,0),Vector3(width+1,1,depth+1),world.mats.concrete,"Foundation",true)
	box(root,Vector3(0,height/2,0),Vector3(width,height,depth),wall,"Exterior",true)
	box(root,Vector3(-width/2+0.7,height/2,0),Vector3(1.4,height,depth+0.12),accent,"FacadeAccent")
	for floor_index in range(floors):
		var y = floor_index*storey
		for side in [-1,1]:
			for bay in range(int(width/3.4)-1):
				var x = -width/2+3.1+bay*3.4
				if floor_index==0 and absf(x)<3: continue
				box(root,Vector3(x,y+1.95,side*(depth/2+0.035)),Vector3(2.25,1.65,0.12),warm if (bay+floor_index)%3==0 else glass,"Window")
			box(root,Vector3(0,y+storey-0.18,side*(depth/2+0.13)),Vector3(width,0.18,0.3),accent,"FloorBand")
		for side in [-1,1]:
			for bay in range(int(depth/4)-1):
				box(root,Vector3(side*(width/2+0.035),y+1.95,-depth/2+3+bay*4),Vector3(0.12,1.6,2.2),glass,"SideWindow")
	# A visible front door, canopy, and restrained cyan strip.
	box(root,Vector3(0,1.25,depth/2+0.09),Vector3(2.4,2.5,0.2),glass,"door_1")
	box(root,Vector3(0,2.8,depth/2+0.8),Vector3(5.5,0.25,2.0),accent,"EntranceCanopy")
	box(root,Vector3(0,2.65,depth/2+1.8),Vector3(4.8,0.08,0.08),world.mats.cyan,"emit_entrance")
	box(root,Vector3(0,0.04,depth/2+1.5),Vector3(5,0.12,3),world.mats.paving,"EntranceLanding")
	sign_on(root,title,Vector3(0,3.0,depth/2+1.85))
	var roof = Node3D.new()
	roof.name = "roof"
	root.add_child(roof)
	box(roof,Vector3(0,height+0.15,0),Vector3(width+0.7,0.3,depth+0.7),roof_material,"FlatRoof")
	for side in [-1,1]:
		box(roof,Vector3(side*width/2,height+0.65,0),Vector3(0.2,0.8,depth),accent,"RoofEdge")
		planter(roof,Vector3(side*(width/2-2.2),height+0.3,-depth/2+2))
	box(roof,Vector3(-width/4,height+0.7,-depth/4),Vector3(3,1.1,2),world.mats.metal,"Ventilation")
	box(roof,Vector3(width/4,height+0.5,-depth/4),Vector3(4,0.18,2.5),glass,"SolarPanel")
	distinctive_architecture(root,roof,style,variant,width,depth,height,storey,floors,accent)
	if "CAFE" in title or "TEA" in title or "FOOD" in title or "FAMILY" in title:
		var terrace_y = height+0.35 if floors>1 else 0.15
		var terrace_z = 1.5 if floors>1 else depth/2+2.7
		box(root,Vector3(0,terrace_y+2.7,terrace_z),Vector3(width*0.65,0.2,3.8),accent,"CafeShade")
		for side in [-1,1]:
			box(root,Vector3(side*width*0.28,terrace_y+1.35,terrace_z),Vector3(0.16,2.7,0.16),world.mats.metal,"ShadeSupport")
		for x in [-3.0,3.0]:
			box(root,Vector3(x,terrace_y+0.75,terrace_z),Vector3(1.4,0.15,1.2),world.mats.coping,"CafeTable")
			box(root,Vector3(x,terrace_y+0.35,terrace_z),Vector3(0.16,0.7,0.16),world.mats.metal,"TableLeg")
			for side in [-1,1]:
				box(root,Vector3(x+side,terrace_y+0.25,terrace_z),Vector3(0.55,0.5,0.55),accent,"PlasticStool")
	planter(root,Vector3(-width/2+1.5,0,depth/2+1.6))
	planter(root,Vector3(width/2-1.5,0,depth/2+1.6))

func shelter(plot: Rect2, title: String) -> void:
	var root = root_for(plot,title)
	var width = minf(plot.size.x-8,18) * (0.85+0.03*(count%5))
	var roof_height = 3.4+0.17*(count%4)
	root.set_meta("architectural_style","transit")
	root.set_meta("design_variant",count-1)
	box(root,Vector3(0,roof_height,0),Vector3(width,0.25,4),accents[count%accents.size()],"roof")
	for i in range(3+count%3):
		box(root,Vector3(-width/2+1.5+i*2.1,roof_height+0.25,0),Vector3(1.5,0.15,3),glass,"SolarCanopy")
	box(root,Vector3(width/2-2,1.4,0.3),Vector3(0.8,2.8,0.7),world.mats.metal,"TimetableKiosk",true)
	box(root,Vector3(width/2-2,1.8,0.69),Vector3(0.65,1.4,0.1),world.mats.cyan,"RouteScreen")
	for side in [-1,1]:
		box(root,Vector3(side*(width/2-0.3),1.6,0),Vector3(0.3,3.2,0.3),world.mats.metal,"Support",true)
	box(root,Vector3(0,1.5,-1.8),Vector3(width,2.6,0.12),glass,"ShelterBack")
	box(root,Vector3(0,0.5,-0.8),Vector3(width*0.6,0.25,0.65),wall,"Bench",true)
	box(root,Vector3(0,3.2,2),Vector3(width-1,0.1,0.1),world.mats.cyan,"emit_route")
	sign_on(root,title,Vector3(0,2.8,2.05))

func style_for(title: String) -> String:
	if "FAMILY" in title: return "rooftop_cafe_home"
	if "DORM" in title: return "student_residence"
	if "APARTMENT" in title: return "garden_apartments"
	if "CLASSROOM" in title: return "teaching_atrium"
	if "HANGAR" in title: return "engineering_hall"
	if "CLINIC" in title: return "medical_centre"
	if "REPAIR" in title: return "repair_workshop"
	if "ARCADE" in title: return "arcade"
	if "CLOTHING" in title: return "fashion_market"
	if "PRODUCE" in title: return "produce_market"
	if "WHOLESALE" in title: return "cold_storage"
	if "DELIVERY" in title: return "logistics_depot"
	if "TECH" in title: return "robot_parts_market"
	if "CRAFT" in title: return "bookshop"
	if "LAUNDRY" in title: return "laundrette"
	if "LAKESIDE" in title: return "lake_pavilion"
	if "FOOD" in title or "TEA" in title or "CAFE" in title: return "tea_house"
	return "neighbourhood_shop"

func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, mat: Material, title: String) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius=radius
	mesh.bottom_radius=radius
	mesh.height=height
	mesh.radial_segments=16
	node.mesh=mesh
	node.material_override=mat
	node.position=at
	node.name=title
	parent.add_child(node)
	return node

func distinctive_architecture(root: Node3D, roof: Node3D, style: String, variant: int, w: float, d: float, h: float, storey: float, floors: int, accent: Material) -> void:
	var handedness = -1.0 if variant%2==0 else 1.0
	match style:
		"rooftop_cafe_home", "student_residence", "garden_apartments":
			# A taller service core and staggered balconies break up residential slabs.
			box(roof,Vector3(handedness*w*0.27,h+2.0,-d*0.22),Vector3(w*0.24,4,d*0.38),accent,"LiftPenthouse")
			for floor_index in range(1,floors):
				var x = handedness*w*0.23 * (-1 if floor_index%2==0 else 1)
				var y = floor_index*storey
				box(root,Vector3(x,y,d/2+0.8),Vector3(w*0.36,0.22,1.7),roof_material,"BalconyDeck")
				box(root,Vector3(x,y+0.6,d/2+1.6),Vector3(w*0.36,1.0,0.12),glass,"BalconyRailing")
				planter(root,Vector3(x,y+0.1,d/2+0.7))
			if style=="rooftop_cafe_home":
				box(roof,Vector3(-w*0.31,h+1.6,0),Vector3(2.5,2.6,d*0.5),glass,"CafeLiftLobby")
				sign_on(root,"SKY LEAF CAFE",Vector3(0,h+2.0,d/2+0.4))
			elif style=="garden_apartments":
				for i in range(3):
					box(roof,Vector3(w*0.2-i*2.5,h+1.3+i*0.45,0),Vector3(2,0.18,d*0.65),accent,"SteppedGardenPergola")
			else:
				for i in range(3+variant%3):
					box(root,Vector3(-w/2+1.2+i*2.7,h/2,d/2+0.22),Vector3(0.2,h,0.45),accent,"DormPrivacyFin")
		"teaching_atrium":
			box(roof,Vector3(0,h+1.2,0),Vector3(w*0.42,2,d*0.75),glass,"RaisedGlassAtrium")
			for i in range(5):
				box(roof,Vector3(-w*0.2+i*w*0.1,h+2.3,0),Vector3(0.2,0.25,d*0.8),wall,"AtriumBeam")
			for side in [-1,1]:
				box(root,Vector3(side*(w/2-0.4),h/2,d/2+0.6),Vector3(0.5,h+1,1.3),accent,"TeachingFacadeBlade")
		"engineering_hall", "repair_workshop", "robot_parts_market":
			for i in range(3+variant%3):
				var x = -w*0.36+i*(w*0.72/(2+variant%3))
				box(roof,Vector3(x,h+0.8,0),Vector3(0.6,1.3,d*0.85),accent,"IndustrialRoofRib")
			box(root,Vector3(-w*0.22,1.5,d/2+0.16),Vector3(w*0.35,2.9,0.15),world.mats.metal,"RollerBay")
			for i in range(6):
				box(root,Vector3(-w*0.22,0.4+i*0.43,d/2+0.26),Vector3(w*0.33,0.08,0.1),accent,"BaySlat")
			cylinder(roof,Vector3(w*0.3,h+1.9,-d*0.3),0.65,3.3,world.mats.metal,"VentStack")
			if style=="robot_parts_market":
				box(roof,Vector3(w*0.26,h+2.4,d*0.15),Vector3(2.4,3.2,1.8),accent,"RobotDisplayHead")
				box(roof,Vector3(w*0.26,h+2.5,d*0.15+0.95),Vector3(1.7,0.4,0.1),world.mats.cyan,"RobotVisor")
		"medical_centre":
			box(roof,Vector3(-w*0.25,h+2.8,0),Vector3(w*0.3,5,d*0.65),wall,"MedicalTower")
			box(root,Vector3(w*0.27,h*0.65,d/2+0.25),Vector3(2.8,0.65,0.3),world.mats.cyan,"MedicalHorizontal")
			box(root,Vector3(w*0.27,h*0.65,d/2+0.25),Vector3(0.65,2.8,0.3),world.mats.cyan,"MedicalVertical")
			box(roof,Vector3(w*0.2,h+0.8,0),Vector3(w*0.4,0.3,d*0.65),glass,"ClinicSolarWing")
		"arcade":
			box(roof,Vector3(handedness*w*0.28,h+2,0),Vector3(w*0.3,4,d*0.5),accent,"ArcadeSignTower")
			box(root,Vector3(0,h*0.62,d/2+0.2),Vector3(w*0.63,2.0,0.2),glass,"GameScreen")
			for i in range(5):
				box(root,Vector3(-w*0.26+i*w*0.13,h*0.62,d/2+0.35),Vector3(0.65,0.5+0.22*(i%3),0.15),world.mats.cyan,"ScreenPixel")
		"cold_storage", "logistics_depot":
			box(roof,Vector3(handedness*w*0.22,h+1.1,0),Vector3(w*0.5,2,d*0.7),roof_material,"RefrigerationPlant" if style=="cold_storage" else "DispatchOffice")
			for i in range(2+variant%2):
				var x = -w*0.3+i*w*0.3
				box(root,Vector3(x,1.3,d/2+0.2),Vector3(w*0.22,2.5,0.25),world.mats.metal,"LoadingDoor")
				box(root,Vector3(x,0.35,d/2+1.2),Vector3(w*0.24,0.6,1.8),roof_material,"LoadingDock",true)
				if style=="cold_storage": cylinder(roof,Vector3(x,h+2.3,0),0.8,0.5,world.mats.metal,"CoolingFan")
		"laundrette":
			for i in range(4):
				var drum = cylinder(root,Vector3(-w*0.3+i*w*0.2,1.4,d/2+0.2),0.7,0.22,glass,"LaundryPorthole")
				drum.rotation_degrees.x=90
			box(roof,Vector3(0,h+0.8,0),Vector3(w*0.7,1,d*0.5),accent,"DryingScreen")
		"produce_market", "fashion_market", "bookshop":
			# Stepped flat canopies, display counters and racks vary along each lane.
			for i in range(3+variant%2):
				var x = -w*0.33+i*w*0.22
				box(roof,Vector3(x,h+0.6+(i%3)*0.55,0),Vector3(w*0.2,0.25,d*0.78),accent,"SteppedMarketCanopy")
				box(root,Vector3(x,0.65,d/2+1.25),Vector3(w*0.17,1.2,1.1),roof_material,"DisplayCounter")
				if style=="produce_market":
					for j in range(3): cylinder(root,Vector3(x-0.6+j*0.6,1.4,d/2+1.25),0.25,0.35,world.mats.leaf if j%2==0 else accent,"ProduceBasket")
				else:
					box(root,Vector3(x,1.9,d/2+0.65),Vector3(w*0.13,1.1,0.16),warm if style=="bookshop" else accent,"BookDisplay" if style=="bookshop" else "FabricDisplay")
		"tea_house", "lake_pavilion":
			var screen_count = 4+variant%4
			for i in range(screen_count):
				box(root,Vector3(w/2+0.2,1.7,-d*0.38+i*d*0.75/(screen_count-1)),Vector3(0.35,3.0,0.18),accent,"TeaHouseScreen")
			box(roof,Vector3(handedness*w*0.22,h+1.0,-d*0.15),Vector3(w*0.4,1.5,d*0.45),glass,"TeaRoomClerestory")
			if style=="lake_pavilion":
				for i in range(5): box(roof,Vector3(-w*0.35+i*w*0.17,h+1.9,0),Vector3(0.22,0.18,d*0.85),accent,"LakePergola")
		_:
			box(roof,Vector3(handedness*w*0.22,h+1.3,0),Vector3(w*0.35,2.2,d*0.5),accent,"ShopMezzanine")
