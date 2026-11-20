extends SceneTree
## Nobody walks through obstacles: the player against the seafront railing, a tree and a lamp post;
## townspeople never end up inside building footprints while walking their routes.
var failures=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,msg: String) -> void:
	print(("PASS " if ok else "FAIL ")+msg)
	if not ok: failures+=1
func frames(n: int) -> void:
	for i in range(n): await physics_frame

func push(world,start: Vector3,dir: Vector3,seconds: float) -> Vector3:
	var p=world.player
	p.teleport(start)
	await frames(10)
	p.test_mode=true
	p.test_direction=dir.normalized()
	await frames(int(seconds*60))
	p.test_direction=Vector3.ZERO
	p.test_mode=false
	return p.global_position

func run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await frames(10)
	var L=world.Layout
	# Seafront railing (west of x=150 where there is no beach stair gap).
	for x in [320.0,505.0,690.0]:
		var s=L.shore(x)
		var start=Vector3(x,L.PROMENADE_Y+0.3,s+4.0)
		var end=await push(world,start,Vector3(0,0,-1),3.0)
		check(end.z>s-0.2 and end.y>L.PROMENADE_Y-0.5,"Railing stops the player at x=%d (z %.1f, shore %.1f)"%[x,end.z,s])
	# A tree trunk and a boulevard lamp.
	var dressing=world.get_node("MasterplanDressing")
	var trunks=dressing.get_node("TreeTrunkSolids")
	var t: Vector3=trunks.get_child(200).position
	var end2=await push(world,Vector3(t.x+3.0,L.height_at(t.x+3.0,t.z)+0.3,t.z),Vector3(-1,0,0),2.0)
	check(Vector2(end2.x-t.x,end2.z-t.z).length()>0.5,"Tree trunk blocks the player (%.2f m from centre)"%Vector2(end2.x-t.x,end2.z-t.z).length())
	# People never stand inside buildings.
	await frames(60*45)
	var inside=0
	var where=[]
	var space=world.get_world_3d().direct_space_state
	var q=PhysicsShapeQueryParameters3D.new()
	var cap=CapsuleShape3D.new()
	cap.radius=0.2
	cap.height=1.2
	q.shape=cap
	q.collision_mask=1
	for group in [world.npcs.ambient,world.npcs.npcs]:
		for e in group:
			if not e.node.visible: continue
			q.transform=Transform3D(Basis(),e.node.global_position+Vector3(0,1.0,0))
			q.exclude=[e.node.get_rid()]
			var hits=space.intersect_shape(q,4)
			for h in hits:
				var c=h.collider
				if c is StaticBody3D or c is AnimatableBody3D:
					inside+=1
					where.append("%s at %s in %s"%[e.node.name,str(e.node.global_position.round()),str(c.get_parent().name)])
					break
	check(inside==0,"Nobody stands inside a wall, railing, tree or prop (%d: %s)"%[inside,str(where.slice(0,4))])
	print("OBSTACLE_CHECK ","PASS" if failures==0 else "FAIL"," failures=",failures)
	await world._quit_cleanly()
