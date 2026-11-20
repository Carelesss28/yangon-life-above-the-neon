extends "res://scripts/prototype_buildings.gd"
## Architecture reconstructed from town_connected_roads_20261118_01.png.
## Meshes are editable prototypes, not extracted geometry from the image.
var frame: StandardMaterial3D
var blue_roof: StandardMaterial3D
var window_light: StandardMaterial3D
var facade: StandardMaterial3D
var window_palette: Array=[]
var wall_palette: Array=[]

const Blocks=preload("res://scripts/reference_blocks.gd")
const STOREY_HEIGHT := 3.0

func setup(owner_world) -> void:
	world=owner_world
	district=Node3D.new()
	district.name="PrototypeBuildings"
	world.add_child(district)
	wall=world._mat("a3acaa")
	frame=world._mat("d2d5cb",0.55)
	glass=world._mat("2a4f65",0.24)
	roof_material=world._mat("445565")
	blue_roof=world._mat("365e90",0.3)
	facade=world._mat("c3ccc5")
	warm=world._mat("c89558",0.6)
	window_light=world._mat("ffd098",0.6,2.4)
	for colour in ["ffbe78","ffdaa5","ffe4bf","a2dbe0"]:
		window_palette.append(world._mat(colour,0.6,2.2))
	accents=[world._mat("47787b"),world._mat("ac825a"),world._mat("4b6078"),world._mat("698268")]
	# Toy-town facade palette (soft, sunlit colours by day; neon and windows take over at night).
	for colour in ["eadfc8","f1ece0","d98a6a","a9c4a0","a9c8dc","c4b4d8","e2c79a","b5dccb","e7b9a4","9fb6c9"]:
		wall_palette.append(world._mat(colour,0.75))
	for block in [Blocks.CAMPUS,Blocks.TECH,Blocks.HOMES,Blocks.LAKE,Blocks.MARKET]:
		for entry in block:
			build(entry[0],entry[1],entry[2])
	build(Blocks.LANDMARKS.engineering_hangar,"YUST ENGINEERING / HANGAR",1)
	for hall in Blocks.HALLS:
		market_hall(hall[0],hall[1],hall[2],hall[3])
	print("REFERENCE_BUILDINGS_READY: ",count," original low-poly buildings")

func new_roof(root: Node3D) -> Node3D:
	var roof=Node3D.new()
	roof.name="roof"
	root.add_child(roof)
	return roof

func beam(parent: Node3D, a: Vector3, b: Vector3, thickness: float, material: Material, title: String) -> void:
	var node=box(parent,(a+b)/2,Vector3(thickness,thickness,a.distance_to(b)),material,title)
	node.basis=Basis.looking_at((b-a).normalized(),Vector3.UP)

func module(root: Node3D, roof: Node3D, origin: Vector3, w: float, d: float, floors: int, variant: int, balconies=false) -> float:
	var h=floors*STOREY_HEIGHT
	box(root,origin+Vector3(0,h/2,0),Vector3(w,h,d),wall,"CompositeShell",true)
	for floor_index in range(floors):
		var y=origin.y+floor_index*STOREY_HEIGHT
		for side in [-1,1]:
			# Continuous glazing subdivided by physical mullions and floor slabs.
			box(root,Vector3(origin.x,y+1.65,origin.z+side*(d/2+0.04)),Vector3(w-0.8,2.15,0.1),glass,"RibbonGlazing")
			var bays=maxi(2,int(w/3))
			for bay in range(bays):
				var x=origin.x-w/2+0.6+(bay+0.5)*(w-1.2)/bays
				if (bay+floor_index+variant)%4!=0:
					var choice=(bay+floor_index*3+variant)%3
					if (bay+floor_index+variant)%11==0: choice=3
					lit_window(box(root,Vector3(x,y+1.65,origin.z+side*(d/2+0.11)),Vector3((w-1.2)/bays-0.22,1.9,0.06),window_palette[choice],"emit_window"))
				box(root,Vector3(x-(w-1.2)/bays/2,y+1.65,origin.z+side*(d/2+0.18)),Vector3(0.12,2.18,0.18),frame,"WindowMullion")
			box(root,Vector3(origin.x,y+STOREY_HEIGHT-0.1,origin.z+side*(d/2+0.22)),Vector3(w+0.45,0.28,0.55),facade,"FloorSlab")
		for side in [-1,1]:
			box(root,Vector3(origin.x+side*(w/2+0.05),y+1.65,origin.z),Vector3(0.1,2.15,d-1),glass,"SideGlazing")
			for z in range(maxi(1,int(d/3))):
				if (z+floor_index+variant)%3!=0:
					lit_window(box(root,Vector3(origin.x+side*(w/2+0.11),y+1.65,origin.z-d/2+1.5+z*3),Vector3(0.06,1.9,2.45),window_palette[(z+variant)%3],"emit_side_window"))
				box(root,Vector3(origin.x+side*(w/2+0.16),y+1.65,origin.z-d/2+1.5+z*3),Vector3(0.2,2.18,0.18),frame,"SideFrame")
		if balconies and floor_index>0:
			var x=origin.x+(-1 if (variant+floor_index)%2==0 else 1)*w*0.2
			box(root,Vector3(x,y+0.12,origin.z+d/2+0.85),Vector3(w*0.47,0.22,1.8),facade,"Balcony")
			box(root,Vector3(x,y+0.8,origin.z+d/2+1.65),Vector3(w*0.47,1.15,0.1),glass,"BalconyGlass")
			garden(root,Vector3(x,y+0.25,origin.z+d/2+0.8),w*0.28)
	box(roof,origin+Vector3(0,h+0.15,0),Vector3(w+0.65,0.3,d+0.65),facade,"RoofSlab")
	for side in [-1,1]:
		box(roof,origin+Vector3(side*w/2,h+0.58,0),Vector3(0.18,0.75,d),frame,"Parapet")
		garden(roof,origin+Vector3(side*(w/2-1.0),h+0.3,-d*0.25),minf(3,d*0.4))
	return h

func lit_window(mesh: MeshInstance3D) -> void:
	mesh.add_to_group("city_window_panels")

func garden(root: Node3D, at: Vector3, width: float) -> void:
	box(root,at+Vector3(0,0.25,0),Vector3(width,0.5,0.8),roof_material,"PlanterTrough")
	for i in range(4):
		var shrub=cylinder(root,at+Vector3(-width*0.35+i*width*0.23,0.8+(i%2)*0.2,0),0.45,0.9,world.mats.leaf,"RoofShrub")
		var foliage=SphereMesh.new()
		foliage.radius=0.48
		foliage.height=1.1
		foliage.radial_segments=12
		foliage.rings=6
		shrub.mesh=foliage
		shrub.scale.x=1.2

func solar(roof: Node3D, at: Vector3, w: float, d: float) -> void:
	box(roof,at,Vector3(w,0.15,d),blue_roof,"SolarArray")
	for i in range(1,5): box(roof,at+Vector3(-w/2+i*w/5,0.1,0),Vector3(0.05,0.04,d),frame,"PanelGrid")
	for i in range(1,3): box(roof,at+Vector3(0,0.1,-d/2+i*d/3),Vector3(w,0.04,0.05),frame,"PanelGrid")

func entry(root: Node3D, at: Vector3, title: String, width: float) -> void:
	root.set_meta("entrance_local",at)
	box(root,at+Vector3(0,1.1,0),Vector3(2.1,2.2,0.18),glass,"door_1")
	box(root,at+Vector3(0,2.51,0.9),Vector3(width,0.18,2),roof_material,"EntranceAwning")
	box(root,at+Vector3(0,2.38,1.95),Vector3(width-0.3,0.08,0.08),window_light,"emit_canopy")
	# Signs are small physical storefront details, not map labels.
	sign_on(root,title,at+Vector3(0,2.79,0.2))
	var light=OmniLight3D.new()
	light.name="EntranceLight"
	light.position=at+Vector3(0,2.5,1.2)
	light.light_color=Color("ffc482")
	light.omni_range=12
	light.set_meta("night_energy",1.8)
	light.light_energy=0.7 if world.night else 0
	root.add_child(light)
	world.lamps.append(light)

func terrace(root: Node3D, roof: Node3D, at: Vector3, w: float, d: float, solar_shade=true) -> void:
	box(roof,at+Vector3(0,3.0,0),Vector3(w,0.18,d),blue_roof if solar_shade else facade,"CafeCanopy")
	if solar_shade: solar(roof,at+Vector3(0,3.15,0),w-0.35,d-0.25)
	for x in [-1,1]:
		for z in [-1,1]: box(roof,at+Vector3(x*(w/2-0.35),1.5,z*(d/2-0.35)),Vector3(0.15,3,0.15),frame,"CanopyLeg")
	for i in range(3):
		var x=-w*0.3+i*w*0.3
		box(root,at+Vector3(x,0.8,0),Vector3(1.2,0.13,1.0),warm,"CafeTable")
		box(root,at+Vector3(x,0.4,0),Vector3(0.12,0.8,0.12),frame,"TableSupport")
		for side in [-1,1]: cylinder(root,at+Vector3(x,0.27,side*0.9),0.28,0.5,accents[i%4],"PlasticStool")
	box(root,at+Vector3(0,2.8,d/2),Vector3(w-0.5,0.08,0.08),window_light,"emit_cafe_light")

func build(plot: Rect2, title: String, floors: int) -> void:
	var root=root_for(plot,title)
	root.set_meta("reference_image","town_connected_roads_20261118_01.png")
	root.set_meta("architectural_style",style_for(title))
	var variant=count
	var w=plot.size.x-6
	var d=plot.size.y-10
	var roof=new_roof(root)
	foundation(root,w,d)
	var style=style_for(title)
	wall=wall_palette[(variant*7+3)%wall_palette.size()]
	if "CIVIC" in title:
		civic_hall(root,roof,w,d,floors,variant,title)
	elif is_cyber(title):
		cyber_building(root,roof,w,d,floors,variant,title)
	elif "TOWER" in title:
		tower(root,roof,w,d,floors,variant,title)
	elif title=="PILOT SCHOOL" or style=="teaching_atrium":
		var h=module(root,roof,Vector3(-w*0.16,0,-d*0.08),w*0.68,d*0.88,floors,variant)
		module(root,roof,Vector3(w*0.32,0,d*0.14),w*0.32,d*0.7,maxi(1,floori(floors*0.5)),variant)
		var atrium=Vector3(-w*0.16,0,d*0.30)
		glass_atrium(root,roof,atrium,w*0.44,d*0.28,h+0.45,variant)
		var panels=roof_plate(roof,Vector3(-w*0.16,h+0.95,-d*0.15),w*0.54,d*0.63,2.0,0.42,facade)
		panels.rotation.x=-0.06
		solar(panels,Vector3(0,0.34,0),w*0.50,d*0.55)
		entry(root,atrium+Vector3(0,0,d*0.14+0.2),"YUST / "+title,12)
	elif style in ["rooftop_cafe_home","student_residence","garden_apartments"]:
		var left_floors=maxi(1,floors-1)
		var h=module(root,roof,Vector3(-w*0.23,0,0),w*0.54,d*0.85,left_floors,variant,true)
		var right_floors=maxi(1,left_floors-1+variant%2)
		var right_height=module(root,roof,Vector3(w*0.27,0,-d*0.12),w*0.43,d*0.62,right_floors,variant+1,true)
		if style=="rooftop_cafe_home":
			terrace(root,roof,Vector3(-w*0.23,h+0.35,0),w*0.48,d*0.6)
			entry(root,Vector3(-w*0.18,0,d*0.43),"SKY LEAF / HOME",5)
		else:
			solar(roof,Vector3(-w*0.23,h+0.45,d*0.20),w*0.35,d*0.22)
			entry(root,Vector3(-w*0.15,0,d*0.43),title,5)
			var upper=Vector3(-w*0.23,h,-d*0.17)
			var upper_height=module(root,roof,upper,w*0.27,d*0.32,1,variant+3,true)
			roof_plate(roof,upper+Vector3(0,upper_height+0.24,0),w*0.32,d*0.38,1.3,0.3,facade)
		green_roof(roof,Vector3(w*0.27,right_height+0.29,-d*0.12),w*0.35,d*0.49)
	elif "ENGINEERING / HANGAR" in title:
		mecha_hangar(root,roof,w,d)
	elif style=="engineering_hall":
		var eaves=9.0
		barrel_roof(roof,w,d,eaves,5.6)
		box(root,Vector3(0,eaves/2,0),Vector3(w,eaves,d),glass,"HangarShell",true)
		for side in [-1,1]:
			for i in range(7): box(root,Vector3(-w/2+i*w/6,eaves/2,side*(d/2+0.15)),Vector3(0.3,eaves,0.3),frame,"HangarFrame")
		var bay_width=minf(20.0,w*0.45)
		box(root,Vector3(0,4.25,d/2+0.23),Vector3(bay_width,8.5,0.16),roof_material,"MechBayDoor")
		box(root,Vector3(0,8.45,d/2+0.35),Vector3(bay_width,0.16,0.16),window_light,"MechBayLight")
		entry(root,Vector3(w*0.28,0,d/2+0.23),"YUST ENGINEERING",5)
	elif style=="medical_centre":
		var h=module(root,roof,Vector3(-w*0.17,0,0),w*0.65,d*0.85,floors,variant)
		module(root,roof,Vector3(w*0.32,0,d*0.08),w*0.3,d*0.7,1,variant)
		roof_plate(roof,Vector3(-w*0.17,h+0.25,0),w*0.70,d*0.90,4.0,0.55,facade)
		green_roof(roof,Vector3(w*0.32,STOREY_HEIGHT+0.34,d*0.08),w*0.25,d*0.57)
		box(roof,Vector3(-w*0.1,h+1.35,0),Vector3(4.3,2.2,1.1),facade,"MedicalSign")
		box(roof,Vector3(-w*0.1,h+1.35,0.62),Vector3(1.65,0.42,0.12),world.mats.cyan,"emit_medical_cross")
		box(roof,Vector3(-w*0.1,h+1.35,0.62),Vector3(0.42,1.65,0.12),world.mats.cyan,"emit_medical_cross")
		entry(root,Vector3(0,0,d*0.45),"STUDENT HEALTH",6)
	elif style in ["cold_storage","logistics_depot"]:
		var h=module(root,roof,Vector3.ZERO,w,d,floors,variant)
		solar(roof,Vector3(0,h+0.45,-d*0.13),w*0.78,d*0.5)
		for i in range(3):
			var x=-w*0.32+i*w*0.32
			box(root,Vector3(x,1.4,d/2+0.2),Vector3(w*0.22,2.7,0.2),roof_material,"LoadingBay")
			box(root,Vector3(x,0.25,d/2+1.3),Vector3(w*0.24,0.5,2),frame,"LoadingPlatform",true)
		entry(root,Vector3(0,0,d/2+0.4),title,5)
	else:
		var h=module(root,roof,Vector3(-w*0.1,0,-d*0.1),w*0.8,d*0.75,floors,variant)
		if "ROBOT WORKSHOP" in title or style=="arcade":
			box(root,Vector3(w*0.15,h*0.55,d*0.29),Vector3(w*0.5,h*0.55,0.2),glass,"DigitalBillboard")
			for i in range(5): box(root,Vector3(-w*0.04+i*w*0.09,h*0.55,d*0.29+0.15),Vector3(w*0.04,h*(0.1+0.035*(i%3)),0.1),world.mats.cyan,"emit_screen_graphic")
			solar(roof,Vector3(-w*0.23,h+0.4,-d*0.1),w*0.48,d*0.55)
			green_roof(roof,Vector3(w*0.15,h+0.28,-d*0.13),w*0.21,d*0.61)
			var front=Vector3(w*0.15,0,d*0.25)
			glass_atrium(root,roof,front,w*0.39,d*0.35,h*0.8,variant)
			entry(root,front+Vector3(0,0,d*0.175+0.2),title,8)
		elif style in ["tea_house","lake_pavilion"]:
			terrace(root,roof,Vector3(w*0.03,0,d*0.35),w*0.7,8,style!="lake_pavilion")
			green_roof(roof,Vector3(-w*0.1,h+0.28,-d*0.11),w*0.69,d*0.6)
			if "TERRACE" in title or "COMMUNITY" in title:
				terrace(roof,roof,Vector3(-w*0.11,h+0.42,0),w*0.5,d*0.38,false)
		else:
			module(root,roof,Vector3(w*0.29,0,-d*0.1),w*0.2,d*0.7,maxi(1,floors-1),variant+2)
			solar(roof,Vector3(-w*0.2,h+0.4,-d*0.15),w*0.38,d*0.4)
		if not root.has_meta("entrance_local"):
			entry(root,Vector3(-w*0.1,0,d*0.28),title,5)
	for side in [-1,1]: garden(root,Vector3(side*(w/2-1),0,d*0.4+1.5),2.0)

func foundation(root: Node3D, width: float, depth: float) -> void:
	var low=0.0
	for x in [-width/2,width/2]:
		for z in [-depth/2,depth/2]:
			var at=root.position+Vector3(x,0,z)
			low=minf(low,Layout.height_at(at.x,at.z)-root.position.y)
	box(root,Vector3(0,low/2-0.2,0),Vector3(width+1.5,0.5-low,depth+1.5),facade,"Foundation")

func roof_plate(parent: Node3D, at: Vector3, width: float, depth: float, cut: float,
		height: float, material: Material) -> MeshInstance3D:
	var x=width/2
	var z=depth/2
	var bevel=minf(cut,minf(x,z)*0.48)
	var points=[Vector2(-x+bevel,-z),Vector2(x-bevel,-z),Vector2(x,-z+bevel),
		Vector2(x,z-bevel),Vector2(x-bevel,z),Vector2(-x+bevel,z),Vector2(-x,z-bevel),Vector2(-x,-z+bevel)]
	var surface=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(points.size()):
		var a: Vector2=points[i]
		var b: Vector2=points[(i+1)%points.size()]
		var p=Vector3(a.x,height/2,a.y)
		var q=Vector3(b.x,height/2,b.y)
		var low_p=p-Vector3.UP*height
		var low_q=q-Vector3.UP*height
		for vertex in [Vector3.UP*height/2,p,q,p,low_p,q,q,low_p,low_q]:
			surface.add_vertex(vertex)
	surface.generate_normals()
	var mesh=MeshInstance3D.new()
	mesh.name="ChamferedVolume"
	mesh.mesh=surface.commit()
	mesh.material_override=material
	mesh.position=at
	parent.add_child(mesh)
	return mesh

func glass_atrium(root: Node3D, roof: Node3D, at: Vector3, width: float, depth: float,
		height: float, variant: int) -> void:
	var glass_face=glass.duplicate()
	glass_face.cull_mode=BaseMaterial3D.CULL_DISABLED
	roof_plate(root,at+Vector3.UP*height/2,width,depth,3.5,height,glass_face)
	roof_plate(roof,at+Vector3.UP*(height+0.2),width+1,depth+1,3.5,0.4,facade)
	var facade_width=width-7
	var bays=maxi(3,ceili(facade_width/3.4))
	var glazing_rows=maxi(1,floori((height-0.30)/STOREY_HEIGHT+0.1))
	var window_height=minf(2.1,height-0.35)
	for i in range(bays):
		var x=((i+0.5)/bays-0.5)*facade_width
		for floor_index in range(glazing_rows):
			if (i+floor_index+variant)%5==0: continue
			lit_window(box(root,at+Vector3(x,window_height/2+0.18+floor_index*STOREY_HEIGHT,depth/2+0.055),
				Vector3(facade_width/bays-0.21,window_height,0.09),window_palette[(i+floor_index)%4],"AtriumGlazing"))
		box(root,at+Vector3(x-facade_width/bays/2,height/2,depth/2+0.14),
			Vector3(0.15,height,0.2),frame,"AtriumMullion")
	var collider=StaticBody3D.new()
	var shape=CollisionShape3D.new()
	var prism=BoxShape3D.new()
	prism.size=Vector3(width-6.8,height,depth)
	shape.shape=prism
	collider.position=at+Vector3.UP*height/2
	collider.add_child(shape)
	root.add_child(collider)

func green_roof(roof: Node3D, at: Vector3, width: float, depth: float) -> void:
	box(roof,at,Vector3(width,0.25,depth),world.mats.leaf,"PlantedRoof")
	for side in [-1,1]:
		garden(roof,at+Vector3(0,0,side*(depth/2-0.7)),width*0.96)

func barrel_roof(roof: Node3D, w: float, d: float, spring: float, rise: float, skylight=false, material: Material=null) -> void:
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps=12
	for i in range(steps):
		var a=-PI/2+PI*i/steps
		var b=-PI/2+PI*(i+1)/steps
		var p=Vector3(sin(a)*w/2,spring+cos(a)*rise,0)
		var q=Vector3(sin(b)*w/2,spring+cos(b)*rise,0)
		for v in [p+Vector3(0,0,-d/2),q+Vector3(0,0,-d/2),q+Vector3(0,0,d/2),p+Vector3(0,0,-d/2),q+Vector3(0,0,d/2),p+Vector3(0,0,d/2)]: st.add_vertex(v)
	st.generate_normals()
	var mesh=MeshInstance3D.new()
	mesh.name="CurvedGlassRoof"
	mesh.mesh=st.commit()
	mesh.material_override=material if material else (world._mat("417184",0.24) if skylight else blue_roof)
	roof.add_child(mesh)
	# Close each curved gable with glazing, rather than leaving a black roof gap.
	for side in [-1,1]:
		var end=SurfaceTool.new()
		end.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(steps):
			var a=-PI/2+PI*i/steps
			var b=-PI/2+PI*(i+1)/steps
			for v in [Vector3(0,spring,side*d/2),Vector3(sin(a)*w/2,spring+cos(a)*rise,side*d/2),Vector3(sin(b)*w/2,spring+cos(b)*rise,side*d/2)]: end.add_vertex(v)
		end.generate_normals()
		var end_mesh=MeshInstance3D.new()
		end_mesh.name="CurvedEndGlazing"
		end_mesh.mesh=end.commit()
		var end_material=glass.duplicate()
		end_material.cull_mode=BaseMaterial3D.CULL_DISABLED
		end_mesh.material_override=end_material
		roof.add_child(end_mesh)
		for i in range(1,12):
			var x=-w/2+i*w/12
			var arch_height=sqrt(maxf(0,1-pow(x/(w/2),2)))*rise
			box(roof,Vector3(x,spring+arch_height/2,side*(d/2+0.12)),Vector3(0.12,arch_height,0.15),frame,"GableMullion")
			if skylight and i>1 and i%3!=0:
				lit_window(box(roof,Vector3(x-w/24,spring+arch_height*0.28,side*(d/2+0.07)),
					Vector3(w/12-0.3,arch_height*0.45,0.05),window_palette[(i+1)%3],"GableWindow"))
	for row in range(5):
		var z=-d/2+row*d/4
		for i in range(steps):
			var a=-PI/2+PI*i/steps
			var b=-PI/2+PI*(i+1)/steps
			beam(roof,Vector3(sin(a)*w/2,spring+cos(a)*rise+0.08,z),Vector3(sin(b)*w/2,spring+cos(b)*rise+0.08,z),0.14,frame,"CurvedSteelRib")
	for i in range(1,12):
		var a=-PI/2+PI*i/12
		box(roof,Vector3(sin(a)*w/2,spring+cos(a)*rise+0.1,0),Vector3(0.1,0.1,d),frame,"RoofLongitudinal")

func market_hall(plot: Rect2, title: String, spring: float, rise: float) -> void:
	var root=root_for(plot,title)
	root.set_meta("architectural_style","curved_glass_market")
	root.set_meta("reference_image","town_connected_roads_20261118_01.png")
	var roof=new_roof(root)
	var w=plot.size.x-12
	var d=plot.size.y-14
	box(root,Vector3(0,0.2,0),Vector3(w,0.4,d),frame,"MarketFloor",true)
	foundation(root,w,d)
	box(root,Vector3(0,spring/2,0),Vector3(w-0.6,spring,d-0.6),glass,"MarketShell",true)
	hall_roof(root,roof,w,d,spring,rise,title)
	for side in [-1,1]:
		lit_window(box(root,Vector3(0,spring/2,side*(d/2+0.06)),Vector3(w-0.3,spring-0.4,0.1),window_light,"emit_market_glazing"))
		for i in range(int(w/4)+1):
			var x=-w/2+i*w/int(w/4)
			box(root,Vector3(x,spring/2,side*(d/2+0.2)),Vector3(0.22,spring,0.24),frame,"MarketFacadePost")
		for y in [1.0,spring*0.5,spring-0.2]: box(root,Vector3(0,y,side*(d/2+0.23)),Vector3(w,0.15,0.2),frame,"MarketFacadeRail")
	for side in [-1,1]:
		for i in range(6):
			var z=-d*0.38+i*d*0.15
			var canopy_colour: Material=accents[(i+count)%4]
			box(root,Vector3(side*(w/2+1.4),2.6,z),Vector3(2.6,0.18,3.4),canopy_colour,"StallAwning")
			box(root,Vector3(side*(w/2+1.1),0.6,z),Vector3(1.7,1.1,2.7),warm,"StallCounter")
	entry(root,Vector3(0,0,d/2+0.3),title,6)


# --- Distinct market-hall roofs: each hall has its own silhouette, colour and stalls. ---
func prism(parent: Node3D, points: Array, length: float, material: Material, title: String) -> MeshInstance3D:
	# Extrudes a 2D (x,y) profile along z, centred. Profile is convex and listed counter-clockwise.
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n=points.size()
	for i in range(1,n-1):
		for z in [-length/2,length/2]:
			var tri=[Vector3(points[0].x,points[0].y,z),Vector3(points[i].x,points[i].y,z),Vector3(points[i+1].x,points[i+1].y,z)]
			if z<0: tri.reverse()
			for v in tri: st.add_vertex(v)
	for i in range(n):
		var p=points[i]
		var q=points[(i+1)%n]
		for v in [Vector3(p.x,p.y,-length/2),Vector3(q.x,q.y,-length/2),Vector3(q.x,q.y,length/2),Vector3(p.x,p.y,-length/2),Vector3(q.x,q.y,length/2),Vector3(p.x,p.y,length/2)]: st.add_vertex(v)
	st.generate_normals()
	var node=MeshInstance3D.new()
	node.name=title
	node.mesh=st.commit()
	node.material_override=material
	parent.add_child(node)
	return node

func hall_roof(root: Node3D, roof: Node3D, w: float, d: float, spring: float, rise: float, title: String) -> void:
	var kind="barrel"
	var colour="365e90"
	var trim=window_palette[0]
	if "PRODUCE" in title: kind="barrel"; colour="2f7d57"
	elif "CLOTHING" in title: kind="double"; colour="8a3c7a"
	elif "TEXTILES" in title: kind="sawtooth"; colour="b8873a"
	elif "FOOD" in title: kind="gable"; colour="b5472f"
	elif "TECH" in title: kind="monopitch"; colour="3d6a94"
	var material=world._mat(colour,0.4)
	match kind:
		"barrel":
			barrel_roof(roof,w,d,spring,rise,false,material)
			# Hanging produce lights and crates under the eaves.
			for i in range(6):
				var x=-w/2+(i+0.5)*w/6
				box(roof,Vector3(x,spring+rise*0.55,d/2+0.5),Vector3(0.35,0.35,0.35),window_light,"emit_hanging_light")
		"double":
			for side in [-1,1]:
				var half=Node3D.new()
				half.name="BarrelHalf"
				half.position.x=side*w/4
				roof.add_child(half)
				barrel_roof(half,w/2-0.2,d,spring,rise*0.8,side>0,material)
			box(roof,Vector3(0,spring+rise*0.1,0),Vector3(0.5,0.4,d),frame,"ValleyGutter")
			# Craft banners on both ends.
			for i in range(5):
				var banner=box(roof,Vector3(-w*0.4+i*w*0.2,spring+1.2,d/2+0.6),Vector3(1.0,2.4,0.08),accents[(i+1)%4],"HallBanner")
		"sawtooth":
			var teeth=5
			var tw=w/teeth
			var tooth_height=maxf(rise*0.8,2.4)
			for i in range(teeth):
				var x0=-w/2+i*tw
				prism(roof,[Vector2(x0,spring+0.06),Vector2(x0+tw,spring+0.06),Vector2(x0+tw,spring+tooth_height)],d,material,"SawtoothRoof")
				lit_window(box(roof,Vector3(x0+tw-0.04,spring+tooth_height/2,0),Vector3(0.08,tooth_height-0.2,d-0.6),window_palette[(i+1)%3],"emit_sawtooth_glazing"))
		"gable":
			prism(roof,[Vector2(-w/2-0.8,spring+0.06),Vector2(w/2+0.8,spring+0.06),Vector2(0,spring+rise)],d+1.2,material,"GableRoof")
			box(roof,Vector3(0,spring+rise+0.12,0),Vector3(0.4,0.3,d+1.4),frame,"RidgeBeam")
			# Lantern ridge along the roof of the food quarter.
			for i in range(8):
				box(roof,Vector3(0,spring+rise+0.5,-d/2+(i+0.5)*d/8),Vector3(0.35,0.5,0.35),window_light,"emit_ridge_lantern")
		"monopitch":
			var slant=prism(roof,[Vector2(-w/2,spring+0.06),Vector2(w/2,spring+0.06),Vector2(w/2,spring+rise*0.55),Vector2(-w/2,spring+rise*1.1)],d+0.8,material,"SlantedRoof")
			var pivot=Node3D.new()
			pivot.name="SolarPivot"
			pivot.position=Vector3(0,spring+rise*0.83+0.18,0)
			pivot.rotation_degrees.z=rad_to_deg(atan2(rise*0.55,w))
			roof.add_child(pivot)
			solar(pivot,Vector3.ZERO,w*0.78,d*0.6)
			box(roof,Vector3(0,spring+rise*0.12,d/2+0.5),Vector3(w,0.12,0.12),window_palette[3],"emit_edge_strip")
	# Hall-specific stall clutter: crates, hanging goods and extra awnings along the long sides.
	for side in [-1,1]:
		for i in range(7):
			var z=-d*0.42+i*d*0.14
			var crate_colour=accents[(i+count+int(side>0))%4]
			box(root,Vector3(side*(w/2+3.4),0.35,z),Vector3(0.9,0.7,0.9),crate_colour,"StallCrate")
			if i%2==0: box(root,Vector3(side*(w/2+3.4),0.95,z),Vector3(0.7,0.5,0.7),accents[(i+2)%4],"StallCrate")


func tower(root: Node3D,roof: Node3D,w: float,d: float,floors: int,variant: int,title: String) -> void:
	if world.get("skyline")!=null:
		world.skyline.build_tower(self,root,roof,w,d,floors,variant,title)
		return
	# Podium plus a slimmer shaft and a lit crown with an aircraft beacon.
	var podium=module(root,roof,Vector3.ZERO,w*0.92,d*0.88,2,variant)
	var shaft_w=w*0.56
	var shaft_d=d*0.6
	var shaft=module(root,roof,Vector3(w*0.08,podium,-d*0.06),shaft_w,shaft_d,maxi(3,floors-2),variant+1)
	var top=podium+shaft
	roof_plate(roof,Vector3(w*0.08,top+0.9,-d*0.06),shaft_w*0.8,shaft_d*0.8,1.6,1.2,facade)
	box(roof,Vector3(w*0.08,top+1.6,-d*0.06+shaft_d*0.4),Vector3(shaft_w*0.8,0.18,0.18),window_light,"emit_crown_strip")
	box(roof,Vector3(w*0.08,top+4.5,-d*0.06),Vector3(0.18,6,0.18),frame,"TowerMast")
	box(roof,Vector3(w*0.08,top+7.6,-d*0.06),Vector3(0.35,0.35,0.35),world._mat("ff3030",0.3,4.0),"AircraftBeacon")
	solar(roof,Vector3(-w*0.3,podium+0.45,d*0.18),w*0.25,d*0.3)
	entry(root,Vector3(-w*0.12,0,d*0.44),title,8)

func civic_hall(root: Node3D,roof: Node3D,w: float,d: float,floors: int,variant: int,title: String) -> void:
	# Stepped, armoured civic block with an antenna array and hazard banding (civic-defence mood).
	var armour=world._mat("5b5470",0.55)
	var keep=wall
	wall=armour
	var a=module(root,roof,Vector3.ZERO,w*0.95,d*0.9,3,variant)
	wall=world._mat("d6cfc0",0.7)
	var b=module(root,roof,Vector3(0,a,-d*0.05),w*0.7,d*0.66,2,variant+1)
	wall=armour
	var c=module(root,roof,Vector3(0,a+b,-d*0.1),w*0.4,d*0.4,maxi(1,floors-5),variant+2)
	wall=keep
	var top=a+b+c
	for i in range(int(w*0.95/2.0)):
		box(root,Vector3(-w*0.475+1+i*2,a-0.5,d*0.45+0.05),Vector3(2,0.5,0.1),world.mats.hazard if i%2==0 else world.mats.hazard_dark,"HazardBand")
	for k in [-1,0,1]:
		box(roof,Vector3(k*w*0.12,top+5,-d*0.1),Vector3(0.22,9.0-absf(k)*3.0,0.22),frame,"AntennaMast")
		box(roof,Vector3(k*w*0.12,top+9.6-absf(k)*3.0,-d*0.1),Vector3(0.4,0.4,0.4),world._mat("ff3030",0.3,4.0),"MastBeacon")
	var dish=cylinder(roof,Vector3(w*0.16,top+1.4,d*0.02),1.6,0.3,frame,"CivicDish")
	dish.rotation_degrees.x=-55
	box(root,Vector3(0,a+b*0.5,d*0.33+0.2),Vector3(w*0.3,1.4,0.16),world._mat("ff8a3d",0.4,2.2),"emit_civic_sign")
	entry(root,Vector3(0,0,d*0.45),title,12)


const CYBER_WORDS=["CHARGING HUB","DRONE PORT","VR NET","CYBERNETICS","ROBOT REPAIR","CAPSULE","BATTERY SWAP","HOLO CINEMA","MECHA GARAGE","DATA CAFE","SIM ARENA","AUGMENT","VENDING HALL","NOODLE BAR","SYNTH"]

func is_cyber(title: String) -> bool:
	for k in CYBER_WORDS:
		if k in title: return true
	return false

func cyber_building(root: Node3D,roof: Node3D,w: float,d: float,floors: int,variant: int,title: String) -> void:
	# Dark composite block with a glass shopfront, an animated LED face, neon edges and a roof sign;
	# drone ports get a lit landing pad, charging and battery shops get charging posts out front.
	var keep=wall
	wall=world._mat(["23262f","2b2438","1f2d33","30282a"][variant%4],0.6)
	var h=module(root,roof,Vector3(0,0,-d*0.05),w*0.9,d*0.85,floors,variant)
	wall=keep
	var neon=["ff3d9a","2fe6e0","b07dff","ffb84a","7dff9a"][variant%5]
	var strip=world._mat(neon,0.3,3.6)
	for x in [-w*0.45,w*0.45]:
		box(root,Vector3(x,h*0.5,d*0.375),Vector3(0.18,h,0.18),strip,"CyberEdgeNeon")
	box(roof,Vector3(0,h+0.35,d*0.375),Vector3(w*0.9,0.16,0.16),strip,"CyberRoofNeon")
	if world.get("skyline")!=null:
		world.skyline.led(root,Vector3(0,h*0.62,d*0.38+0.1),Vector2(w*0.7,minf(h*0.45,7.0)))
		world.skyline.sign_frame(roof,Vector3(0,h+0.3,-d*0.1),minf(w*0.85,14.0),title)
	if "DRONE PORT" in title:
		var pad=Vector3(0,h+0.45,-d*0.12)
		box(roof,pad,Vector3(9,0.2,9),world._mat("2a2c33",0.6),"DronePad")
		box(roof,pad+Vector3(0,0.12,0),Vector3(5,0.04,0.6),world._mat("f2f0e8",0.6),"PadMarkH")
		for x in [-2.2,2.2]: box(roof,pad+Vector3(x,0.12,0),Vector3(0.6,0.04,4.6),world._mat("f2f0e8",0.6),"PadMarkH")
		for c in [Vector2(-4.3,-4.3),Vector2(4.3,-4.3),Vector2(-4.3,4.3),Vector2(4.3,4.3)]:
			box(roof,pad+Vector3(c.x,0.2,c.y),Vector3(0.3,0.3,0.3),world._mat("2fe6e0",0.3,5.0),"PadLight")
	if "CHARGING" in title or "BATTERY" in title:
		for i in range(4):
			var x=-w*0.3+i*w*0.2
			box(root,Vector3(x,0.9,d*0.5+2.0),Vector3(0.5,1.8,0.4),world._mat("e8e4dc",0.5),"ChargingPost",true)
			box(root,Vector3(x,1.35,d*0.5+2.21),Vector3(0.36,0.5,0.04),world._mat("7dff9a",0.3,3.5),"ChargeScreen")
	entry(root,Vector3(0,0,d*0.38+0.2),title,8)


const MECHA_NAMES=["AZURE RAMPART","SERAPH","DUNE RANGER","STARLANCE"]

func mecha_hangar(root: Node3D,roof: Node3D,w: float,d: float) -> void:
	# Open-front hangar: solid back and side walls, a glass roof on steel trusses (so the frames are
	# visible from the high camera), four bays with gantries, hazard floor markings and bay plates.
	var eaves=15.0
	world.hangar_roof=roof
	var steel=world._mat("4a4f5c",0.5)
	var concrete=world.mats.concrete
	box(root,Vector3(0,0.1,0),Vector3(w,0.2,d),world._mat("7a7f86",0.8),"HangarFloor",true)
	box(root,Vector3(0,eaves/2,-d/2),Vector3(w,eaves,0.6),steel,"HangarBackWall",true)
	for sx in [-1,1]:
		box(root,Vector3(sx*w/2,eaves/2,0),Vector3(0.6,eaves,d),steel,"HangarSideWall",true)
		for k in range(6):
			box(root,Vector3(sx*(w/2+0.02),1+k*2.4,d/2-0.4),Vector3(0.62,1.2,0.6),world.mats.hazard if k%2==0 else world.mats.hazard_dark,"HazardColumn")
	# Open-top truss roof (no glazing): the frames stay visible from the high camera.
	for k in range(7):
		box(roof,Vector3(-w/2+k*w/6,eaves+0.6,0),Vector3(0.4,0.8,d+1),steel,"RoofTruss")
	box(roof,Vector3(0,eaves-0.5,d/2),Vector3(w,1.0,0.6),steel,"FrontHeader")
	for k in range(int(w/2)):
		box(roof,Vector3(-w/2+1+k*2,eaves-1.25,d/2+0.02),Vector3(2,0.5,0.62),world.mats.hazard if k%2==0 else world.mats.hazard_dark,"HeaderStripe")
	var bay_w=w/4.0
	for i in range(4):
		var x=-w/2+bay_w*(i+0.5)
		# Bay floor box and gantry frame.
		for sx in [-1,1]:
			box(root,Vector3(x+sx*bay_w*0.48,0.22,0),Vector3(0.3,0.04,d-4),world.mats.hazard,"BayLine")
		for sx in [-1,1]:
			box(root,Vector3(x+sx*(bay_w*0.5-0.8),6.5,d/2-15),Vector3(0.6,13,0.6),world.mats.hazard,"GantryPost",true)
		box(root,Vector3(x,12.8,d/2-15),Vector3(bay_w-1.0,0.6,0.8),world.mats.hazard,"GantryBeam")
		for k in range(3): box(root,Vector3(x,3+k*3.5,d/2-13.4),Vector3(bay_w-3.0,0.25,1.6),world.mats.hazard_dark,"GantryWalkway")
		var lamp=OmniLight3D.new()
		lamp.position=Vector3(x,eaves-2.0,0)
		lamp.light_color=Color("e8f4ff")
		lamp.omni_range=16
		lamp.light_energy=1.6
		lamp.set_meta("night_energy",2.4)
		lamp.shadow_enabled=false
		root.add_child(lamp)
		world.lamps.append(lamp)
		# The frame itself (the user's models), facing out of the open front.
		var path="res://models/mecha/mecha_%d_rigged.glb"%(i+1)
		if not ResourceLoader.exists(path): path="res://models/mecha/mecha_%d.glb"%(i+1)
		if ResourceLoader.exists(path):
			var m=(load(path) as PackedScene).instantiate() as Node3D
			m.name="MechaFrame_%d"%(i+1)
			m.position=Vector3(x,0.2,d/2-10.0)   # stands at the open front, easy to see and reach
			root.add_child(m)
			load("res://scripts/mecha_rig.gd").attach(m,world,true)   # servo idle while parked
			var body=StaticBody3D.new()
			var shape=CollisionShape3D.new()
			var b=BoxShape3D.new()
			b.size=Vector3(minf(bay_w-2.0,5.0),10,4)
			shape.shape=b
			shape.position=m.position+Vector3(0,5,0)
			body.add_child(shape)
			root.add_child(body)
			var home=root.global_position+m.position
			var approach=Rect2(Vector2(home.x-bay_w*0.46,home.z+2.5),Vector2(bay_w*0.92,13.5))
			var interaction={"pos":home+Vector3(0,0,8.0),"title":"BAY %02d · %s" % [i+1,MECHA_NAMES[i]],"bay_index":i}
			world.hangar_bays.append({"index":i,"node":m,"body":body,"home":home,"name":MECHA_NAMES[i],"path":path,"approach":approach,"interaction":interaction})
			world.activity_spots.append(interaction)
		var plate=Label3D.new()
		plate.text="BAY %02d
%s" % [i+1,MECHA_NAMES[i]]
		plate.font_size=40
		plate.pixel_size=0.022
		plate.position=Vector3(x,0.25,d/2-2.0)
		plate.rotation.x=-PI/2
		plate.modulate=Color("f0b429")
		plate.shaded=false
		root.add_child(plate)
	var sign=Label3D.new()
	sign.text="YUST MECHA HANGAR"
	sign.font_size=96
	sign.pixel_size=0.03
	sign.position=Vector3(0,eaves+2.2,d/2)
	sign.modulate=Color("ffd06a")
	sign.outline_size=10
	sign.outline_modulate=Color("15121c")
	sign.shaded=false
	sign.billboard=BaseMaterial3D.BILLBOARD_FIXED_Y
	roof.add_child(sign)
	root.set_meta("entrance_local",Vector3(w*0.42,0,d/2+0.5))
	world.activity_spots.append({"pos":root.global_position+Vector3(0,0.2,d/2-3.0) if root.is_inside_tree() else root.position+Vector3(0,0.2,d/2-3.0),"title":"MECHA HANGAR"})
