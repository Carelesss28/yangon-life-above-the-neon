extends SceneTree
const Roads=preload("res://scripts/road_layout.gd")
var failures=0
func check(ok: bool,message: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+message)
	if not ok: failures+=1
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var adjacency={}
	for key in Roads.NODES: adjacency[key]=[]
	for edge in Roads.EDGES:
		adjacency[edge[0]].append(edge[1])
		adjacency[edge[1]].append(edge[0])
		var a: Vector3=Roads.NODES[edge[0]]
		var b: Vector3=Roads.NODES[edge[1]]
		check(absf(b.y-a.y)/Vector2(b.x-a.x,b.z-a.z).length()<=0.1,"Road grade <= 10 percent "+str(edge))
	for key in adjacency: check(adjacency[key].size()>=2,"No vehicle dead end: "+key)
	var visited={}
	var todo=["c"]
	while not todo.is_empty():
		var key=todo.pop_back()
		if visited.has(key): continue
		visited[key]=true
		for next in adjacency[key]: todo.append(next)
	check(visited.size()==Roads.NODES.size(),"All town, market and waterfront roads form one connected network")
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	var player=world.player
	player.test_mode=true
	player.test_speed=18
	for edge in Roads.EDGES:
		var a: Vector3=Roads.NODES[edge[0]]
		var b: Vector3=Roads.NODES[edge[1]]
		player.test_direction=Vector3.ZERO
		player.teleport(a+Vector3.UP*0.25)
		for i in range(20): await physics_frame
		var reached=false
		for i in range(2400):
			var delta=Vector2(b.x-player.position.x,b.z-player.position.z)
			if delta.length()<0.6:
				reached=true
				break
			player.test_direction=Vector3(delta.x,0,delta.y).normalized()
			await physics_frame
		check(reached,"Road deck traversal "+str(edge)+" "+str(player.position))
	player.test_direction=Vector3.ZERO
	print("ROAD_CHECK_COMPLETE failures=",failures)
	quit(1 if failures else 0)
