extends RefCounted
## Every vehicle-road endpoint is a shared graph vertex; walking paths are separate.
const NODES={
 "nw":Vector3(8,4,8),"n":Vector3(302,0,8),"ne_return":Vector3(580,0,8),"ne":Vector3(610,0,8),
 "w":Vector3(8,0,302),"c":Vector3(302,0,302),"e":Vector3(610,0,302),
 "sw":Vector3(8,10,616),"s":Vector3(302,10,616),"se":Vector3(610,10,616),
 "market_nw":Vector3(8,18,-680),"market_ne":Vector3(610,18,-680),
 "market_sw":Vector3(8,18,-360),"market_return":Vector3(580,18,-360),"market_se":Vector3(610,18,-360),
 "upper_w":Vector3(-250,10,618),"upper_c":Vector3(300,10,618),
 "ramp_w_top":Vector3(-250,10,638),"ramp_w_bottom":Vector3(-90,0,638),"lower_w":Vector3(-90,0,654),
 "ramp_e_top":Vector3(300,10,638),"ramp_e_bottom":Vector3(460,0,638),"lower_e":Vector3(460,0,654),
 "tech_nw":Vector3(335,0,60),"tech_ne":Vector3(594,0,60),"tech_se":Vector3(594,0,255),"tech_sw":Vector3(335,0,255),
 "home_nw":Vector3(25,0,365),"home_ne":Vector3(270,0,365),
 "home_w_mid":Vector3(25,2,450),"home_e_mid":Vector3(270,2,450),
 "home_sw":Vector3(25,4,550),"home_se":Vector3(270,4,550),"home_exit":Vector3(270,8,590),"home_join":Vector3(270,10,614),
 "hill_north_gate":Vector3(32,7.6,-42),"hill_north_approach":Vector3(75,13.8,-113),
 "hill_north_lookout":Vector3(108,19.5,-185),"hill_north_crest":Vector3(102,25.5,-260),
 "hill_north_pass":Vector3(65,23,-308),"hill_market_bend":Vector3(35,19.9,-345),
 "hill_west_gate":Vector3(-40,7.8,29),"hill_west_approach":Vector3(-105,13,62),
 "hill_west_ridge":Vector3(-171,19,105),"hill_west_crest":Vector3(-218,24,178),
 "hill_west_lookout":Vector3(-207,21,251),"hill_west_bend":Vector3(-170,16,323),
 "hill_west_valley":Vector3(-127,13,393),"hill_west_slope":Vector3(-102,15,470),
 "hill_west_descent":Vector3(-129,14,545),"hill_west_join":Vector3(-168,10,618)
}
const NORTH_PASS = ["nw","hill_north_gate","hill_north_approach","hill_north_lookout",
 "hill_north_crest","hill_north_pass","hill_market_bend","market_sw"]
const WEST_PASS = ["nw","hill_west_gate","hill_west_approach","hill_west_ridge","hill_west_crest",
 "hill_west_lookout","hill_west_bend","hill_west_valley","hill_west_slope","hill_west_descent","hill_west_join"]

const EDGES=[
 ["nw","n"],["n","ne_return"],["ne_return","ne"],
 ["nw","w"],["w","sw"],["n","c"],["c","s"],["ne","e"],["e","se"],
 ["w","c"],["c","e"],["sw","s"],["s","se"],
 ["market_nw","market_ne"],["market_nw","market_sw"],
 ["market_sw","market_return"],["market_return","market_se"],["market_se","market_ne"],
 ["market_return","ne_return"],["market_se","ne"],
 ["s","upper_c"],["upper_w","hill_west_join"],["hill_west_join","upper_c"],
 ["upper_w","ramp_w_top"],["ramp_w_top","ramp_w_bottom"],["ramp_w_bottom","lower_w"],
 ["lower_w","lower_e"],["lower_e","ramp_e_bottom"],["ramp_e_bottom","ramp_e_top"],["ramp_e_top","upper_c"],
 ["n","tech_nw"],["tech_nw","tech_ne"],["tech_ne","tech_se"],["tech_se","tech_sw"],["tech_sw","tech_nw"],["tech_se","e"],
 ["home_nw","home_ne"],["home_ne","home_e_mid"],["home_e_mid","home_se"],
 ["home_se","home_sw"],["home_sw","home_w_mid"],["home_w_mid","home_nw"],
 ["home_se","home_exit"],["home_exit","home_join"],["home_join","s"],
 ["nw","hill_north_gate"],["hill_north_gate","hill_north_approach"],["hill_north_approach","hill_north_lookout"],
 ["hill_north_lookout","hill_north_crest"],["hill_north_crest","hill_north_pass"],["hill_north_pass","hill_market_bend"],
 ["hill_market_bend","market_sw"],
 ["nw","hill_west_gate"],["hill_west_gate","hill_west_approach"],["hill_west_approach","hill_west_ridge"],
 ["hill_west_ridge","hill_west_crest"],["hill_west_crest","hill_west_lookout"],["hill_west_lookout","hill_west_bend"],
 ["hill_west_bend","hill_west_valley"],["hill_west_valley","hill_west_slope"],["hill_west_slope","hill_west_descent"],
 ["hill_west_descent","hill_west_join"]
]
const MOUNTAIN_SHOULDER := 43.0
static var spatial: Dictionary={}
static var mountain_spatial: Dictionary={}

static func is_mountain(edge: Array) -> bool:
	return edge[0] not in ["upper_w","hill_west_join"] and (
		edge[0].begins_with("hill_") or edge[1].begins_with("hill_"))

static func width(edge: Array) -> float:
	return 18.0 if edge in [["n","c"],["c","s"],["w","c"],["c","e"]] else 8.0
static func initialise() -> void:
	if not spatial.is_empty(): return
	for edge in EDGES:
		var a: Vector3=NODES[edge[0]]
		var b: Vector3=NODES[edge[1]]
		var radius=width(edge)*0.5+1.5
		var mountain=is_mountain(edge)
		var segment={"a":a,"b":b,"radius":radius,"mountain":mountain}
		_index_segment(spatial,segment,radius)
		if mountain: _index_segment(mountain_spatial,segment,MOUNTAIN_SHOULDER)

static func _index_segment(index: Dictionary,segment: Dictionary,radius: float) -> void:
	var a=Vector2(segment.a.x,segment.a.z)
	var b=Vector2(segment.b.x,segment.b.z)
	var rect=Rect2(a,Vector2.ZERO).expand(b).grow(radius)
	for x in range(floori(rect.position.x/20),floori(rect.end.x/20)+1):
		for z in range(floori(rect.position.y/20),floori(rect.end.y/20)+1):
			var key=Vector2i(x,z)
			if not index.has(key): index[key]=[]
			index[key].append(segment)

static func sample(x: float,z: float) -> Dictionary:
	initialise()
	return _nearest(spatial,x,z,false)

static func mountain_sample(x: float,z: float) -> Dictionary:
	initialise()
	return _nearest(mountain_spatial,x,z,true)

static func _nearest(index: Dictionary,x: float,z: float,shoulder: bool) -> Dictionary:
	var best={}
	var nearest=INF
	for edge in index.get(Vector2i(floori(x/20),floori(z/20)),[]):
		var a=Vector2(edge.a.x,edge.a.z)
		var b=Vector2(edge.b.x,edge.b.z)
		var t=clampf((Vector2(x,z)-a).dot(b-a)/a.distance_squared_to(b),0,1)
		var d=Vector2(x,z).distance_to(a.lerp(b,t))
		if d<(MOUNTAIN_SHOULDER if shoulder else edge.radius) and d<nearest:
			nearest=d
			best={"y":elevation(edge.a,edge.b,t,edge.mountain),"distance":d,"half":edge.radius-1.5,"mountain":edge.mountain}
	return best

static func has_clearance(center: Vector2,radius: float) -> bool:
	initialise()
	var first=Vector2i(floori((center.x-radius)/20),floori((center.y-radius)/20))
	var last=Vector2i(floori((center.x+radius)/20),floori((center.y+radius)/20))
	for x in range(first.x,last.x+1):
		for z in range(first.y,last.y+1):
			for edge in spatial.get(Vector2i(x,z),[]):
				var a=Vector2(edge.a.x,edge.a.z)
				var b=Vector2(edge.b.x,edge.b.z)
				var nearest=Geometry2D.get_closest_point_to_segment(center,a,b)
				if nearest.distance_to(center)<edge.radius+radius: return false
	return true

static func elevation(a: Vector3,b: Vector3,t: float,mountain=false) -> float:
	var length=Vector2(b.x-a.x,b.z-a.z).length()
	# Flat approaches extend beyond the junction caps so uphill vehicles meet no lip.
	var inset=minf((5.5 if mountain else 10.0)/length,0.18)
	return lerpf(a.y,b.y,clampf((t-inset)/(1-2*inset),0,1))
static func point(a: Vector3,b: Vector3,t: float,mountain=false) -> Vector3:
	var p=a.lerp(b,t)
	p.y=elevation(a,b,t,mountain)
	return p
