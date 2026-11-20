extends RefCounted
const Roads=preload("res://scripts/road_layout.gd")
## Compact 300 x 300 m campus; north is z=0.
const MIN_X: float = 0.0
const WIDTH: float = 300.0
const DEPTH: float = 300.0
const CENTRES: Array[float] = [50.0, 150.0, 250.0]
const SECTION_NAMES = ["CENTRAL QUAD", "DORMS & GARDENS", "TEACHING PRECINCT", "HANGAR & TRAINING", "SOUTH ENTRANCE"]
const DISTRICT_VISITS = [Vector2(150,150),Vector2(450,150),Vector2(150,450),Vector2(430,460),Vector2(150,-40),Vector2(-40,150),Vector2(300,-390),Vector2(200,676)]
const DISTRICT_NAMES = ["YUST CAMPUS", "STUDENT / TECH HUB", "HOME NEIGHBOURHOOD", "LAKESIDE / MARKET", "NORTH HILLS", "WEST HILLS", "NORTHERN MARKET", "SOUTH RIVERFRONT"]
const VISITS = [Vector2(150,150), Vector2(50,150), Vector2(150,65), Vector2(250,150), Vector2(150,275)]
const PADS: Array[Rect2] = [Rect2(110,20,35,35), Rect2(160,20,35,35), Rect2(17,104,27,35), Rect2(17,157,27,35), Rect2(78,108,25,25), Rect2(203,105,35,40), Rect2(205,160,70,40)]
const PAD_NAMES = ["PILOT SCHOOL", "CLASSROOMS", "DORM A", "DORM B", "FOOD & COMMONS", "ENGINEERING / HANGAR", "TRAINING GROUND"]
static func stream_x(z: float) -> float:
	return 67.0 + 4.0*sin(z*0.035)
static func dry_height(x: float, z: float) -> float:
	if z >= 290 or x >= 286: return 0.0
	var h = 4.0 if z <= 80 else (2.0 if z <= 210 else 0.0)
	for cx in CENTRES:
		for edge in [80.0,210.0]:
			var high = 4.0 if edge == 80 else 2.0
			if absf(x-cx) <= 4 and absf(z-edge) <= 4:
				h = lerpf(high,high-2,(z-edge+4)/8)
			if absf(x-(cx+28)) <= 3 and absf(z-edge) <= 20:
				h = lerpf(high,high-2,(z-edge+20)/40)
	return h
static func natural_height_at(x: float,z: float) -> float:
	# Grade pedestrian landings before the raised southern perimeter road.
	for cx in [-30.0,150.0,520.0]:
		if absf(x-cx)<4 and z>=595 and z<=624:
			var start=river_height(x,595) if x<0 else district_height(x,595)
			return lerpf(start,10.12,clampf((z-595)/15,0,1))
	if z>=614 or (x<0 and z>=500): return river_height(x,z)
	if z < -300: return market_height(x,z)
	if z<0 and x>=500: return approach_height(x,z)
	if x<0 or z<0: return hill_height(x,z)
	if x > 300 or z > 300: return district_height(x,z)
	var h = dry_height(x,z)
	if z > 95 and z < 200:
		h -= 1.2*(1-smoothstep(2.5,6.0,absf(x-stream_x(z))))
	return h
static func wet(x: float,z: float) -> bool:
	return (z > 95 and z < 200 and absf(x-stream_x(z)) < 3) or (x>314 and z>314 and lake_distance(x,z)<1.065)
static func clear_for_planting(x: float,z: float) -> bool:
	if x > 280 or z > 284 or x < 5 or z < 5: return false
	if absf(z-80)<23 or absf(z-210)<23: return false
	if absf(z-150)<7 or absf(z-270)<6 or absf(z-65)<6: return false
	if z>90 and z<205 and absf(x-stream_x(z))<8: return false
	for cx in CENTRES:
		if absf(x-cx)<7: return false
	for pad in PADS:
		if pad.grow(4).has_point(Vector2(x,z)): return false
	if Rect2(122,120,56,65).has_point(Vector2(x,z)): return false
	return true

static func lake_distance(x: float,z: float) -> float:
	return Vector2((x-550)/46.0,(z-548)/43.0).length()
static func district_height(x: float,z: float) -> float:
	if (x>=286 and x<=314) or (z>=290 and z<=314): return 0.0
	if x>314 and z<290:
		# A broad, gently raised pedestrian plaza, with ramped approaches.
		return 2.0*smoothstep(345.0,395.0,x)*(1-smoothstep(535.0,585.0,x))*smoothstep(35.0,85.0,z)*(1-smoothstep(220.0,270.0,z))
	if x<286 and z>314:
		# Home neighbourhood rises inland from the south road.
		return 2*smoothstep(385.0,425.0,z)+2*smoothstep(485.0,525.0,z)
	if x>314 and z>314:
		var h=-2*smoothstep(435.0,490.0,x)*smoothstep(410.0,470.0,z)
		return h-1.6*(1-smoothstep(0.8,1.15,lake_distance(x,z)))
	return 0.0

# Two separate parcels; the northwest gap remains outside the playable world.
const NORTH_HILLS = Rect2(0,-300,500,300)
const WEST_HILLS = Rect2(-300,0,300,500)
const NORTH_TRAIL = [Vector2(150,0),Vector2(150,-35),Vector2(205,-65),Vector2(240,-105),Vector2(205,-145),Vector2(145,-175),Vector2(180,-215),Vector2(260,-235),Vector2(305,-210),Vector2(320,-180)]
const WEST_TRAIL = [Vector2(0,150),Vector2(-35,150),Vector2(-75,195),Vector2(-115,230),Vector2(-160,195),Vector2(-195,145),Vector2(-235,175),Vector2(-250,250),Vector2(-205,300),Vector2(-155,340),Vector2(-115,395),Vector2(-60,445)]
static func in_world(x: float,z: float) -> bool:
	return Rect2(-300,614,914,196).has_point(Vector2(x,z)) or Rect2(-300,500,300,114).has_point(Vector2(x,z)) or Rect2(0,0,614,614).has_point(Vector2(x,z)) or NORTH_HILLS.has_point(Vector2(x,z)) or WEST_HILLS.has_point(Vector2(x,z)) or Rect2(0,-700,614,400).has_point(Vector2(x,z)) or Rect2(500,-300,114,300).has_point(Vector2(x,z))
static func hill_raw(x: float,z: float) -> float:
	if z<0:
		var d=-z
		var base=4.0 if x<286 else 0.0
		var ridge=28+10*sin(x*0.012+0.5)+5*sin(x*0.031)
		return base+smoothstep(0,210,d)*ridge+sin(x*0.042+z*0.023)*sin(z*0.038)*2.8*smoothstep(0,50,d)
	var base=natural_height_at(0,clampf(z,0,499))
	var ridge=27+10*sin(z*0.014)+6*sin(z*0.032)
	return base+smoothstep(0,230,-x)*ridge+sin(x*0.037+z*0.024)*sin(z*0.041)*2.6*smoothstep(0,40,-x)
static func trail_distance(point: Vector2, route: Array) -> float:
	var distance=INF
	for i in range(route.size()-1):
		var a: Vector2=route[i]
		var b: Vector2=route[i+1]
		var t=clampf((point-a).dot(b-a)/a.distance_squared_to(b),0,1)
		distance=minf(distance,point.distance_to(a.lerp(b,t)))
	return distance
static func north_stream_x(z: float) -> float:
	return 355+8*sin(z*0.027)
const NORTH_FALLS = [Vector2i(-240,-229),Vector2i(-165,-151)]
static func north_water_y(z: float) -> float:
	if z < -240: return lerpf(47,43,clampf((z+300)/60,0,1))
	if z < -229: return lerpf(43,31,(z+240)/11)
	if z < -165: return lerpf(31,28,(z+229)/64)
	if z < -151: return lerpf(28,12,(z+165)/14)
	return lerpf(12,4,clampf((z+151)/116,0,1))
static func hill_height(x: float,z: float) -> float:
	var h=hill_raw(x,z)
	var point=Vector2(x,z)
	var route=NORTH_TRAIL if z<0 else WEST_TRAIL
	# Grade a narrow trail into the slope; do not drape it over roots or sharp ridges.
	for i in range(route.size()-1):
		var a: Vector2=route[i]
		var b: Vector2=route[i+1]
		var t=clampf((point-a).dot(b-a)/a.distance_squared_to(b),0,1)
		var distance=point.distance_to(a.lerp(b,t))
		if distance<5:
			var grade=lerpf(hill_raw(a.x,a.y),hill_raw(b.x,b.y),t)
			h=lerpf(grade,h,smoothstep(2,5,distance))
	if z < -30:
		var distance=absf(x-north_stream_x(z))
		var bed=north_water_y(z)-1.0
		var pool_width=11.0 if z>=-229 and z<=-208 else 4.0
		if distance<22: h=lerpf(bed,h,smoothstep(pool_width,22,distance))
	var pool=Vector2((x-north_stream_x(-36))/14.0,(z+36)/10.0).length()
	if z<0 and pool<1.25: h=lerpf(3.2,h,smoothstep(0.85,1.25,pool))
	return h

# Northern market: 600 x 400 m, with an eastern access road outside its footprint.
const MARKET_TRAIL = [Vector2(320,-180),Vector2(290,-230),Vector2(300,-285),Vector2(300,-330),Vector2(300,-365)]
const MARKET_RECT = Rect2(0,-700,600,400)
static func market_height(x: float,z: float) -> float:
	var plateau=18.0
	if z > -340:
		var edge=hill_height(x,-300.0) if x<500 else 18.0
		return lerpf(edge,plateau,1-smoothstep(-340,-300,z))
	# Raised pedestrian shopping core, approached over broad gentle ramps.
	var plaza=2*smoothstep(150,185,x)*(1-smoothstep(415,450,x))*smoothstep(-635,-605,z)*(1-smoothstep(-465,-435,z))
	return plateau+plaza
static func approach_height(x: float,z: float) -> float:
	var road_grade=18.0*clampf(-z/300,0,1)
	var edge=hill_height(499.99,z)
	return lerpf(edge,road_grade,smoothstep(500,585,x))

const RIVER_LAND_Y: float = 10.0
const WATERFRONT_ROAD_Y: float = 0.0
const RIVER_WATER_Y: float = -1.5 # Slightly below the lower waterfront road.
const RIVER_BED_Y: float = -6.0
const RIVER_RECT = Rect2(-300,614,914,196)
static func river_north_bank(x: float) -> float:
	return 685+7*sin(x*0.012)+3*sin(x*0.032)
static func river_width(x: float) -> float:
	return 65+7*sin(x*0.016+1)
static func river_water_edge(x: float,north: bool) -> float:
	var bank=river_north_bank(x)
	var south=bank+river_width(x)
	var low=bank-1 if north else south-9
	var high=bank+9 if north else south+14
	for i in range(18):
		var mid=(low+high)*0.5
		var above=river_height(x,mid)>RIVER_WATER_Y
		if above==north: low=mid
		else: high=mid
	return (low+high)*0.5
static func river_height(x: float,z: float) -> float:
	var bank=river_north_bank(x)
	var south=bank+river_width(x)
	var town_edge=district_height(x,614) if x>=0 else hill_height(x,499.99)
	var h=10.0 if z<=645 else 0.0
	if z<624:
		var start=614.0 if x>=0 else 500.0
		h=lerpf(town_edge,10.0,smoothstep(start,624,z))
	# Three walkable stair slopes, with visible treads added by the world builder.
	for cx in [-30.0,150.0,520.0]:
		if absf(x-cx)<=3.5 and z>=624 and z<=650:
			h=lerpf(10.0,0.0,(z-624)/26)
	# Two 160 m longitudinal vehicle ramps: gentle 6.25 percent grades.
	for start_x in [-250.0,300.0]:
		var end_x=start_x+160
		if x>=start_x and x<=end_x and absf(z-638)<=6:
			var grade=lerpf(10.0,0.0,(x-start_x)/160)
			h=lerpf(grade,h,smoothstep(4,6,absf(z-638)))
		if absf(x-end_x)<=5 and z>=638 and z<=659: h=0.0
	if z<bank-1: return h
	if z<bank+9: return lerpf(0.0,RIVER_BED_Y,smoothstep(bank-1,bank+9,z))
	if z<south-9: return RIVER_BED_Y
	if z<south+14: return lerpf(RIVER_BED_Y,0.0,smoothstep(south-9,south+14,z))
	return 0.6*sin(x*0.025)*smoothstep(south+14,810,z)

const WATER_ROUTES = [
 {"name":"Hill supply / campus / river trunk", "width":1.6,"points":[Vector3(355,4.2,-36),Vector3(260,3.5,-70),Vector3(100,3.2,-50),Vector3(65,3.1,0),Vector3(65,2.9,65),Vector3(65,1.8,95),Vector3(63,1.5,150),Vector3(70,1.3,198),Vector3(75,-0.55,235),Vector3(75,-0.65,350),Vector3(65,-0.85,450),Vector3(65,-1.0,560),Vector3(65,-1.1,625),Vector3(65,-1.2,675),Vector3(65,-1.5,705)]},
 {"name":"Home garden recirculation", "width":0.85,"points":[Vector3(130,3.4,550),Vector3(135,3.2,535),Vector3(135,1.2,475),Vector3(135,1.0,440),Vector3(135,-0.4,380),Vector3(135,-0.6,350),Vector3(75,-0.65,350)]},
 {"name":"Tech plaza recirculation / lake inlet", "width":1.1,"points":[Vector3(460,1.4,105),Vector3(465,1.3,150),Vector3(465,1.1,215),Vector3(470,-0.4,265),Vector3(470,-0.55,330),Vector3(465,-0.75,395),Vector3(490,-1.7,465),Vector3(520,-2.25,520)]},
 {"name":"Market rainwater / treatment / east drain", "width":1.2,"points":[Vector3(565,17.4,-640),Vector3(565,17.2,-520),Vector3(565,17.0,-365),Vector3(575,16.0,-280),Vector3(575,10.5,-190),Vector3(575,4.5,-85),Vector3(575,-0.55,0),Vector3(575,-0.65,150),Vector3(575,-0.7,270),Vector3(465,-0.75,395)]},
 {"name":"Lake pumped discharge", "width":1.0,"points":[Vector3(605,-0.9,565),Vector3(608,-1.0,610),Vector3(608,-1.2,660),Vector3(608,-1.5,710)]}
]
static var water_segments: Dictionary={}
static func init_water_index() -> void:
	if not water_segments.is_empty(): return
	for route in WATER_ROUTES:
		for i in range(route.points.size()-1):
			var a: Vector3=route.points[i]
			var b: Vector3=route.points[i+1]
			var radius=route.width*0.5+1.2
			var rect=Rect2(Vector2(a.x,a.z),Vector2.ZERO).expand(Vector2(b.x,b.z)).grow(radius)
			var entry={"a":a,"b":b,"width":route.width}
			for xx in range(floori(rect.position.x/20),floori(rect.end.x/20)+1):
				for zz in range(floori(rect.position.y/20),floori(rect.end.y/20)+1):
					var key=Vector2i(xx,zz)
					if not water_segments.has(key): water_segments[key]=[]
					water_segments[key].append(entry)
static func channel_sample(x: float,z: float) -> Dictionary:
	init_water_index()
	var best={}
	var nearest=INF
	for entry in water_segments.get(Vector2i(floori(x/20),floori(z/20)),[]):
		var a=Vector2(entry.a.x,entry.a.z)
		var b=Vector2(entry.b.x,entry.b.z)
		var t=clampf((Vector2(x,z)-a).dot(b-a)/a.distance_squared_to(b),0,1)
		var d=Vector2(x,z).distance_to(a.lerp(b,t))
		if d<entry.width*0.5+0.8 and d<nearest:
			nearest=d
			best={"distance":d,"width":entry.width,"water_y":lerpf(entry.a.y,entry.b.y,t)}
	return best
static func height_at(x: float,z: float) -> float:
	var base=base_height_at(x,z)
	var channel=channel_sample(x,z)
	if channel.is_empty(): return base
	# Water cannot float above the ground. Covered sections handle higher terraces.
	var depth=base-channel.water_y
	if depth<0.15 or depth>2.3: return base
	var half=channel.width*0.5
	return lerpf(channel.water_y-0.45,base,smoothstep(half,half+0.8,channel.distance))

static func base_height_at(x: float,z: float) -> float:
	var ground=natural_height_at(x,z)
	var road=Roads.sample(x,z)
	if road.is_empty() or road.mountain:
		var pass_grade=Roads.mountain_sample(x,z)
		if not pass_grade.is_empty():
			var blend_width=clampf(8.0+absf(pass_grade.y-ground)*1.35,10.0,37.0)
			var shoulder=pass_grade.half+0.9
			var blend=smoothstep(shoulder,shoulder+blend_width,pass_grade.distance)
			return lerpf(pass_grade.y-0.16,ground,blend)
	if road.is_empty() or road.y>=ground: return ground
	# Cut high ground only. Raised road portions are supported decks above the ground.
	return lerpf(road.y+0.10,ground,smoothstep(road.half,road.half+1.5,road.distance))
