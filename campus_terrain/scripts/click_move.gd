extends Node
## Dota-style click-to-move. Left-click the ground to walk there (hold the button to keep steering);
## long trips follow the sidewalks. Clicking a person, building, shop counter, pickup, station, bus stop
## or your vehicle walks you over and uses it. The cursor shows a hand and a hint over usable things.
## Keyboard movement still works and cancels a click path.
const Layout=preload("res://scripts/terrain_layout.gd")
const Data=preload("res://scripts/npc_data.gd")
var mark_plain: Material
var mark_action: Material
var world
var path: Array=[]
var target_action: Dictionary={}
var marker: MeshInstance3D
var marker_time=0.0
var hint: Label
var hover_clock=0.0
var hover: Dictionary={}
var holding=false
var hold_clock=0.0
var stuck_clock=0.0
var best_distance=INF
var sidestep=0.0
var sidestep_dir=Vector3.ZERO
var attempts=0
var finder

func _ready() -> void:
	name="ClickMove"
	finder=load("res://scripts/path_finder.gd").new(world)
	marker=MeshInstance3D.new()
	var torus=TorusMesh.new()
	torus.inner_radius=0.45
	torus.outer_radius=0.6
	marker.mesh=torus
	mark_plain=world._mat("2fe6e0",0.3,3.0)
	mark_action=world._mat("ffcf3a",0.3,3.0)
	marker.material_override=mark_plain
	marker.visible=false
	world.add_child(marker)
	var layer=CanvasLayer.new()
	layer.layer=40
	add_child(layer)
	hint=Label.new()
	hint.add_theme_font_size_override("font_size",16)
	hint.add_theme_color_override("font_color",Color("fff2c8"))
	hint.add_theme_color_override("font_shadow_color",Color("15121c"))
	hint.add_theme_constant_override("shadow_offset_y",2)
	hint.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hint.visible=false
	layer.add_child(hint)

# ---------------------------------------------------------------- picking
func _ray(screen: Vector2) -> Dictionary:
	var cam: Camera3D=world.camera
	var from=cam.project_ray_origin(screen)
	var normal=cam.project_ray_normal(screen)
	# Stop the ray 50 m below sea level: a ray that ends far outside the physics world (the old
	# fixed 3 km) silently misses everything.
	var length=3000.0
	if normal.y<-0.01: length=minf(length,(from.y+50.0)/-normal.y)
	var to=from+normal*length
	var q=PhysicsRayQueryParameters3D.create(from,to)
	q.exclude=[world.player.get_rid()]
	return world.get_world_3d().direct_space_state.intersect_ray(q)

func _resolve(hit: Dictionary) -> Dictionary:
	# What did the player click on? Returns {kind, at (where to walk), label, ...}.
	var p: Vector3=hit.position
	# Lambdas capture locals by value, so the running best lives in a shared dictionary.
	var state={"best":{},"d":INF}
	var consider=func(kind: String,at: Vector3,label: String,radius: float,extra: Dictionary) -> void:
		var d=Vector2(at.x-p.x,at.z-p.z).length()
		if d<radius and d<state.d and absf(at.y-p.y)<6.0:
			state.d=d
			state.best=extra.merged({"kind":kind,"at":at,"label":label})
	if world.npcs:
		for npc in world.npcs.npcs:
			if npc.node.visible: consider.call("npc",npc.node.global_position,"Talk to "+npc.data.name,2.2,{"npc":npc})
		for pk in world.npcs.pickups:
			if is_instance_valid(pk.node): consider.call("use",pk.node.global_position-Vector3(0,0.6,0),"Pick up "+Data.ITEMS[pk.item],2.0,{})
		for w in world.npcs.ambient:
			if w.node.visible: consider.call("use",w.node.global_position,"Say hello",1.6,{})
	for sp in world.activity_spots:
		consider.call("use",sp.pos,str(sp.title).capitalize(),3.0,{})
	if world.garage:
		for v in world.garage.owned.values():
			consider.call("vehicle",v.global_position,"Get in "+v.title,3.0,{"vehicle":v})
	if world.skytrain:
		for st in world.skytrain.stations:
			consider.call("skytrain",st.ground,"Skytrain lift: "+st.title,4.0,{})
			consider.call("skytrain",st.platform,"Board the skytrain",4.0,{})
	if world.buses:
		for stop in world.buses.stops:
			consider.call("bus",stop.queue,"Bus stop: "+stop.title,4.0,{})
	if not world.interiors.inside:
		for i in range(world.interiors.records.size()):
			var r=world.interiors.records[i]
			consider.call("enter",r.outside,"Enter "+str(r.title).get_slice(" / ",0).capitalize(),3.5,{"index":i})
		# Clicking a building's walls also walks to its door.
		if state.best.is_empty() and hit.collider:
			var node: Node=hit.collider
			while node and not node.has_meta("interior_index"): node=node.get_parent()
			if node:
				var r=world.interiors.records[int(node.get_meta("interior_index"))]
				state.best={"kind":"enter","at":r.outside,"label":"Enter "+str(r.title).get_slice(" / ",0).capitalize(),"index":int(node.get_meta("interior_index"))}
	elif world.player.global_position.distance_to(world.interiors.exit_position)<40.0:
		consider.call("exit",world.interiors.exit_position,"Leave the building",2.5,{})
	return state.best

# ---------------------------------------------------------------- input
func _blocked() -> bool:
	return world.player.transit_mode or world.player.paused or (world.interiors and world.interiors.busy) \
		or (world.npcs and (not world.npcs.talking.is_empty() or world.npcs.journal_open)) \
		or world.camera.overview or world.camera.masterplan

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		holding=event.pressed
		if event.pressed and not _blocked():
			_command(event.position,true)
			get_viewport().set_input_as_handled()

func _command(screen: Vector2,fresh: bool) -> void:
	var hit=_ray(screen)
	if hit.is_empty(): return
	var target=_resolve(hit) if fresh else {}
	var goal: Vector3=hit.position
	target_action={}
	if not target.is_empty():
		target_action=target
		goal=target.at
	var here=world.player.global_position
	path=[]
	if world.interiors.inside or not fresh:
		path=[goal]
	else:
		# Real pathfinding around buildings, walls, railings, trees and props.
		path=finder.find(here,goal)
		if path.is_empty(): path=[goal]
	# One steady pace for click-to-move (like a top-down RPG): the speed never depends on how far
	# away you clicked or where the cursor is while steering.
	world.player.auto_run=true
	stuck_clock=0.0
	best_distance=INF
	attempts=0
	marker.visible=true
	marker.global_position=goal+Vector3.UP*0.12
	marker_time=0.0
	marker.material_override=mark_action if not target_action.is_empty() else mark_plain

# ---------------------------------------------------------------- following
func _physics_process(delta: float) -> void:
	var player=world.player
	if player==null: return
	var keys=Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_D) \
		or Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_RIGHT)
	if keys or _blocked():
		if keys: _stop()
		player.auto_direction=Vector3.ZERO
		return
	# Hold the button to keep steering toward the cursor, like holding right-click in Dota.
	if holding:
		hold_clock+=delta
		if hold_clock>0.18:
			hold_clock=0.0
			_command(get_viewport().get_mouse_position(),false)
	marker_time+=delta
	marker.scale=Vector3.ONE*(1.0+0.15*sin(marker_time*8.0))
	if path.is_empty():
		player.auto_direction=Vector3.ZERO
		return
	var goal: Vector3=path[0]
	var here=player.global_position
	var flat=Vector2(goal.x-here.x,goal.z-here.z)
	var reach=0.7
	if path.size()==1 and not target_action.is_empty():
		reach=1.6 if target_action.kind in ["npc","use","vehicle"] else 2.2
	if path.size()>1: reach=2.0
	if flat.length()<reach:
		path.pop_front()
		best_distance=INF
		stuck_clock=0.0
		if path.is_empty(): _arrive()
		return
	var dir=Vector3(flat.x,0,flat.y).normalized()
	# Stuck? Slide sideways for a moment, then try again; give up after a few tries.
	if flat.length()<best_distance-0.15:
		best_distance=flat.length()
		stuck_clock=0.0
	else:
		stuck_clock+=delta
	if sidestep>0.0:
		sidestep-=delta
		dir=(dir*0.3+sidestep_dir).normalized()
	elif stuck_clock>0.6:
		attempts+=1
		if attempts>4:
			attempts=0
			path.pop_front()
			if path.is_empty(): _stop()
			return
		sidestep=0.5
		sidestep_dir=Vector3(-dir.z,0,dir.x)*(1.0 if attempts%2==1 else -1.0)
		stuck_clock=0.0
	player.auto_direction=dir

func _stop() -> void:
	path=[]
	target_action={}
	marker.visible=false
	world.player.auto_direction=Vector3.ZERO

func _key(target: Object,code: int) -> void:
	var e=InputEventKey.new()
	e.physical_keycode=code
	e.keycode=code
	e.pressed=true
	target._input(e)

func _arrive() -> void:
	world.player.auto_direction=Vector3.ZERO
	marker.visible=false
	var a=target_action
	target_action={}
	if a.is_empty(): return
	match a.kind:
		"npc": world.npcs._open_dialogue(a.npc)
		"use": _key(world.npcs,KEY_Q)
		"vehicle": world.garage._enter(a.vehicle)
		"skytrain": _key(world.skytrain,KEY_F)
		"bus": _key(world.buses,KEY_B)
		"enter","exit": world.interiors.interact()

# ---------------------------------------------------------------- hover feedback
func _process(delta: float) -> void:
	hover_clock+=delta
	if hover_clock<0.1: return
	hover_clock=0.0
	if _blocked() or world.player==null:
		hint.visible=false
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		return
	var mouse=get_viewport().get_mouse_position()
	var hit=_ray(mouse)
	hover=_resolve(hit) if not hit.is_empty() else {}
	if hover.is_empty():
		hint.visible=false
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	else:
		hint.text=hover.label
		hint.position=mouse+Vector2(18,14)
		hint.visible=true
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
