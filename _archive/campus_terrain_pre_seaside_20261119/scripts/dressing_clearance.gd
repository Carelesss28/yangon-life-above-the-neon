extends RefCounted
## Horizontal envelopes keep even the widest tree crown and lamp head clear.
const Layout=preload("res://scripts/terrain_layout.gd")
const Roads=preload("res://scripts/road_layout.gd")
const CELL_SIZE := 24.0
const ZONES := [
	Rect2(0,0,300,291),
	Rect2(0,314,286,295),
	Rect2(340,318,254,87),
	Layout.NORTH_HILLS,
	Layout.WEST_HILLS,
	Rect2(500,-300,84,300),
	Rect2(-300,500,298,114),
]
var rail_cells: Dictionary={}
var station_areas: Array[Rect2]=[]
var stop_access: Array[Dictionary]=[]
var placements: Array[Dictionary]=[]
var fountain_areas: Array[Dictionary]=[]

func setup(world) -> void:
	for line in world.skytrain.lines:
		var data: Dictionary=world.skytrain.lines[line]
		for i in range(ceili(data.length/3.0)+1):
			var p: Vector3=world.skytrain.sample(line,i*3.0)
			var center=Vector2(p.x,p.z)
			var key=_cell(center)
			if not rail_cells.has(key): rail_cells[key]=[]
			rail_cells[key].append(center)
	for station in world.skytrain.stations:
		var root: Node3D=station.root
		var bounds: AABB=world._scene_bounds(root,root.get_parent_node_3d().global_transform)
		station_areas.append(Rect2(Vector2(bounds.position.x,bounds.position.z),Vector2(bounds.size.x,bounds.size.z)).grow(2.0))
		var landing=Vector2(station.ground.x,station.ground.z)
		var lift=Vector2(station.upper.x,station.upper.z)
		station_areas.append(Rect2(landing,Vector2.ZERO).expand(lift).grow(4.0))
	for pier in world.skytrain.find_children("ViaductPier*","MeshInstance3D",true,false):
		station_areas.append(Rect2(Vector2(pier.global_position.x,pier.global_position.z)-Vector2.ONE,Vector2.ONE*2))
	for stop in world.buses.stops:
		stop_access.append({"queue":Vector2(stop.queue.x,stop.queue.z),"access":Vector2(stop.access.x,stop.access.z)})

func _cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x/CELL_SIZE),floori(p.y/CELL_SIZE))

func allowed_area(center: Vector2) -> bool:
	for zone in ZONES:
		if zone.has_point(center): return true
	return false

func clears_transport(center: Vector2,radius: float) -> bool:
	if not Roads.has_clearance(center,radius): return false
	var rail_distance=radius+4.0
	var first=_cell(center-Vector2.ONE*rail_distance)
	var last=_cell(center+Vector2.ONE*rail_distance)
	for x in range(first.x,last.x+1):
		for z in range(first.y,last.y+1):
			for point in rail_cells.get(Vector2i(x,z),[]):
				if center.distance_squared_to(point)<rail_distance*rail_distance: return false
	for area in station_areas:
		if area.grow(radius).has_point(center): return false
	for stop in stop_access:
		var nearest=Geometry2D.get_closest_point_to_segment(center,stop.queue,stop.access)
		if nearest.distance_to(center)<radius+3.0: return false
	return true

func reserve(center: Vector2,radius: float,kind: String) -> bool:
	if not allowed_area(center) or not clears_transport(center,radius): return false
	for area in fountain_areas:
		if center.distance_to(area.center)<radius+area.radius: return false
	var item={"center":center,"radius":radius,"kind":kind}
	placements.append(item)
	if kind=="fountain": fountain_areas.append(item)
	return true
