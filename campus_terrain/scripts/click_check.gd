extends SceneTree
## Click-to-move check (run with a window, not headless): click the ground, a far point (sidewalk
## route), a person (opens dialogue) and a building (walks in).
var failures=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,msg: String) -> void:
	print(("PASS " if ok else "FAIL ")+msg)
	if not ok: failures+=1
func frames(n: int) -> void:
	for i in range(n): await physics_frame

func click_at(world,point: Vector3) -> void:
	var screen=world.camera.unproject_position(point)
	world.click_move._command(screen,true)

func key(code: Key,pressed: bool) -> void:
	var event=InputEventKey.new()
	event.physical_keycode=code
	event.pressed=pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func flat_speed(player: CharacterBody3D) -> float:
	return Vector2(player.velocity.x,player.velocity.z).length()

func walk_until(world,cond: Callable,limit: int) -> bool:
	for i in range(limit):
		await physics_frame
		if cond.call(): return true
	return false

func run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await frames(30)
	var cm=world.click_move
	var p=world.player
	var L=world.Layout
	# 1. Short click on open paving.
	p.teleport(Vector3(693.66,L.height_at(693.66,646)+0.2,646))
	await frames(20)
	var goal=Vector3(683.1,L.height_at(683.1,646),646)
	click_at(world,goal)
	check(not cm.path.is_empty(),"Clicking the ground sets a destination")
	await frames(32)
	var short_speed=flat_speed(p)
	check(absf(short_speed-p.run_speed)<0.15,"Short clicks reach the normal jog speed")
	var travel: Vector3=p.get_position_delta()
	travel.y=0
	check((-p.visual.global_basis.z).dot(travel.normalized())>0.9,"Character faces the direction of travel")
	var ok=await walk_until(world,func(): return cm.path.is_empty(),60*12)
	check(ok and Vector2(p.global_position.x-goal.x,p.global_position.z-goal.z).length()<1.5,"Walked to the clicked spot")
	# 2. Far click: follows the sidewalks.
	var far=Vector3(633.8,L.height_at(633.8,575),575)
	p.teleport(Vector3(693.66,L.height_at(693.66,646)+0.2,646))
	await frames(20)
	world.camera.zoom=1.8
	await frames(20)
	click_at(world,far)
	var waypoints=cm.path.size()
	await frames(32)
	check(absf(flat_speed(p)-short_speed)<0.15,"Long clicks use the same jog speed")
	ok=await walk_until(world,func(): return cm.path.is_empty(),60*60)
	print("   long click ended at ",p.global_position," path left ",cm.path.size()," target ",far)
	check(ok and Vector2(p.global_position.x-far.x,p.global_position.z-far.z).length()<3.0,"Long click reaches the target (%d waypoints)"%waypoints)
	world.camera.zoom=1.0
	p.teleport(Vector3(693.66,L.height_at(693.66,646)+0.2,646))
	await frames(20)
	cm._command(world.camera.unproject_position(goal),false)
	await frames(32)
	check(absf(flat_speed(p)-short_speed)<0.15,"Held mouse steering uses the same jog speed")
	key(KEY_D,true)
	await frames(38)
	check(absf(flat_speed(p)-p.walk_speed)<0.15,"WASD walks")
	key(KEY_SHIFT,true)
	await frames(27)
	check(absf(flat_speed(p)-p.run_speed)<0.15,"Shift runs")
	key(KEY_D,false)
	key(KEY_SHIFT,false)
	# 3. Click a person: walk over and talk.
	var mother=world.npcs.by_id["mother"]
	mother.node.visible=true
	var mp: Vector3=mother.node.global_position
	p.teleport(mp+Vector3(6,0.3,6))
	await frames(25)
	click_at(world,mp+Vector3(0,0.9,0))
	check(cm.target_action.get("kind","")=="npc","Clicking Daw Khin May targets her")
	ok=await walk_until(world,func(): return world.npcs.panel.visible,60*12)
	check(ok,"Walked over and opened the conversation")
	world.npcs._close_dialogue()
	# 4. Click a building: walk to its door and go in.
	var rec=world.interiors.records[0]
	var door: Vector3=rec.outside
	p.teleport(door+Vector3(0,0.3,8))
	await frames(25)
	click_at(world,door)
	ok=await walk_until(world,func(): return world.interiors.inside,60*15)
	check(ok,"Clicking %s walks in"%rec.title)
	print("CLICK_CHECK ","PASS" if failures==0 else "FAIL"," failures=",failures)
	if DisplayServer.get_name()=="headless": quit(failures)
	else: await world._quit_cleanly()
