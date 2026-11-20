extends RefCounted
## Grid A* over the real world: cells are tested lazily with a physics shape query (buildings, walls,
## railings, trees, props) plus water and steepness, so click-to-move walks around anything solid.
## Paths are smoothed by line-of-sight checks so the walk is natural, not a staircase.
const Layout=preload("res://scripts/terrain_layout.gd")
const STEP=1.5
var world
var space: PhysicsDirectSpaceState3D
var probe: PhysicsShapeQueryParameters3D
var blocked_cache: Dictionary={}

func _init(owner_world) -> void:
	world=owner_world
	probe=PhysicsShapeQueryParameters3D.new()
	var box=BoxShape3D.new()
	box.size=Vector3(0.7,1.1,0.7)
	probe.shape=box
	probe.collision_mask=1

func _key(p: Vector2) -> Vector2i:
	return Vector2i(roundi(p.x/STEP),roundi(p.y/STEP))

func _pos(k: Vector2i) -> Vector2:
	return Vector2(k.x*STEP,k.y*STEP)

func blocked(k: Vector2i) -> bool:
	if blocked_cache.has(k): return blocked_cache[k]
	var p=_pos(k)
	var b=false
	if not Layout.in_world(p.x,p.y) or Layout.wet(p.x,p.y) or (p.y<Layout.shore(p.x)-1.0 and Layout.harbour_weight(p.x)>0.5):
		b=true
	else:
		var y=Layout.height_at(p.x,p.y)
		probe.transform=Transform3D(Basis(),Vector3(p.x,y+1.15,p.y))
		probe.exclude=[world.player.get_rid()]
		b=not space.intersect_shape(probe,1).is_empty()
	blocked_cache[k]=b
	return b

func _clear_line(a: Vector2,b: Vector2) -> bool:
	var n=int(a.distance_to(b)/0.75)+1
	for i in range(1,n):
		if blocked(_key(a.lerp(b,float(i)/n))): return false
	return true

func find(from: Vector3,to: Vector3,max_nodes: int=40000) -> Array:
	space=world.get_world_3d().direct_space_state
	if blocked_cache.size()>200000: blocked_cache.clear()
	var start=_key(Vector2(from.x,from.z))
	var goal_key=_key(Vector2(to.x,to.z))
	# A blocked goal (e.g. a shop counter) is approached from the nearest open cell.
	if blocked(goal_key):
		var best=goal_key
		var found=false
		for r in range(1,5):
			for dx in range(-r,r+1):
				for dz in range(-r,r+1):
					var k=goal_key+Vector2i(dx,dz)
					if not blocked(k) and not found:
						best=k
						found=true
		goal_key=best
	var open={start:0.0}
	var g={start:0.0}
	var came={}
	var closed={}
	var dirs=[Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1),Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(-1,-1)]
	var expanded=0
	var reached=false
	while not open.is_empty() and expanded<max_nodes:
		var current: Vector2i
		var best_f=INF
		for k in open:
			if open[k]<best_f: best_f=open[k]; current=k
		open.erase(current)
		if current==goal_key:
			reached=true
			break
		closed[current]=true
		expanded+=1
		for d in dirs:
			var n: Vector2i=current+d
			if closed.has(n) or blocked(n): continue
			if d.x!=0 and d.y!=0 and (blocked(current+Vector2i(d.x,0)) or blocked(current+Vector2i(0,d.y))): continue
			var cost=float(g[current])+(1.414 if d.x!=0 and d.y!=0 else 1.0)
			if not g.has(n) or cost<g[n]:
				g[n]=cost
				came[n]=current
				open[n]=cost+Vector2(n-goal_key).length()*1.05
	if not reached: return []
	var cells=[goal_key]
	while cells[0]!=start: cells.push_front(came[cells[0]])
	# String-pull: keep only the corners needed for line of sight.
	var pts=[Vector2(from.x,from.z)]
	var anchor=pts[0]
	for i in range(1,cells.size()):
		var p=_pos(cells[i])
		if i+1<cells.size() and _clear_line(anchor,_pos(cells[i+1])): continue
		pts.append(p)
		anchor=p
	pts.append(Vector2(to.x,to.z) if not blocked(_key(Vector2(to.x,to.z))) else _pos(goal_key))
	var out=[]
	for i in range(1,pts.size()): out.append(Vector3(pts[i].x,0,pts[i].y))
	return out
