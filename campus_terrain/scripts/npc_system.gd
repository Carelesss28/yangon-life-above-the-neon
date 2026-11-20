extends Node
## Townspeople: a game clock (30 real minutes = 24 game hours), 20 authored NPCs who walk their daily
## routines on the town's sidewalks, talk / gift / schedule / quest interactions, relationship levels,
## gift pickups that respawn each morning, a journal, and a save file. Clock pauses in dialogue.
const Data=preload("res://scripts/npc_data.gd")
const Layout=preload("res://scripts/terrain_layout.gd")
const Roads=preload("res://scripts/road_layout.gd")
const StudentVisual=preload("res://scripts/student_visual.gd")
const SAVE_PATH="user://yust_social.json"
const GAME_MINUTES_PER_SECOND=0.8   # 1 game hour = 75 real seconds
const WALK_SPEED=1.7
const LEVELS=[[0,"Acquaintance"],[20,"Familiar"],[45,"Friend"],[70,"Close friend"]]

var world
var minutes: float=7*60.0
var day: int=1
var npcs: Array=[]
var ambient: Array=[]
var ambient_spots: Array=[]
var arng=RandomNumberGenerator.new()
var by_id: Dictionary={}
var places: Dictionary={}
var pickups: Array=[]
var inventory: Dictionary={}
var kyat: int=5000
var stats: Dictionary={"Energy":100.0,"Study":0,"Piloting":0,"Engineering":0,"Fitness":0,"Charm":0,"outfit":0}
var activities
var pending_garage: Dictionary={}
var social: Dictionary={}      # id -> {points, talked_day, gifted_day, quest: "offer"/"active"/"done", reached}
var talking: Dictionary={}
var journal_open=false
var dirty=false
var follow_clock=true
var last_mode=-1
# UI
var clock_label: Label
var prompt: Label
var panel: PanelContainer
var name_label: Label
var level_label: Label
var text_label: Label
var options_box: HBoxContainer
var journal: PanelContainer
var journal_text: RichTextLabel
var toast: Label
var toast_time=0.0

func _ready() -> void:
	name="Townspeople"
	_resolve_places()
	_load()
	activities=load("res://scripts/activities.gd").new(self)
	if int(stats.get("outfit",0))!=0: activities.apply_outfit.call_deferred()
	for entry in Data.NPCS: _spawn(entry)
	_spawn_pickups()
	_ui()
	for npc in npcs: _settle(npc)
	_spawn_ambient(150)
	if not pending_garage.is_empty() and world.garage: world.garage.load_state.call_deferred(pending_garage)
	print("NPC_SYSTEM_READY npcs=",npcs.size()," ambient=",ambient.size()," pickups=",pickups.size()," unresolved=",places.get("_unresolved",[]))

# ---------------------------------------------------------------- places and routes
func _resolve_places() -> void:
	var unresolved=[]
	for key in Data.PLACES: places[key]={"point":Data.PLACES[key][0],"label":Data.PLACES[key][1],"door":false}
	for record in world.interiors.records:
		var title: String=record.title
		var out: Vector3=record.outside
		places["b:"+title]={"point":Vector2(out.x,out.z),"label":"the "+title.get_slice(" / ",0).capitalize(),"door":true,"record":record}
	for entry in Data.NPCS:
		for step in entry.routine:
			if not places.has(step[1]): unresolved.append(step[1])
	for p in Data.PICKUPS:
		if p[1] is String and not places.has(p[1]): unresolved.append(p[1])
	places["_unresolved"]=unresolved

func place_point(key: String) -> Vector2:
	if places.has(key): return places[key].point
	return Vector2(697.18,646)

func place_label(key: String) -> String:
	return places[key].label if places.has(key) else "somewhere in town"

func _ground(p: Vector2) -> float:
	return Layout.height_at(p.x,p.y)+0.12

func _nearest_edge(p: Vector2) -> Dictionary:
	var best={}
	var nearest=INF
	for edge in Roads.EDGES:
		if Roads.is_mountain(edge): continue
		var a: Vector3=Roads.NODES[edge[0]]
		var b: Vector3=Roads.NODES[edge[1]]
		var q=Geometry2D.get_closest_point_to_segment(p,Vector2(a.x,a.z),Vector2(b.x,b.z))
		var d=q.distance_to(p)
		if d<nearest:
			nearest=d
			best={"edge":edge,"point":q}
	return best

func _sidewalk(point: Vector2,toward: Vector2,edge: Array) -> Vector2:
	var half=Roads.width(edge)*0.5+2.0
	var a: Vector3=Roads.NODES[edge[0]]
	var b: Vector3=Roads.NODES[edge[1]]
	var dir=Vector2(b.x-a.x,b.z-a.z).normalized()
	var side=Vector2(-dir.y,dir.x)
	if side.dot(toward-point)<0: side=-side
	return point+side*half

func _node_corner(key: String,toward: Vector2) -> Vector2:
	# Walk around junctions on the corner that faces the next leg, not through the carriageway.
	var n: Vector3=Roads.NODES[key]
	var half=6.0
	for edge in Roads.EDGES:
		if edge[0]==key or edge[1]==key: half=maxf(half,Roads.width(edge)*0.5+2.0)
	var c=Vector2(n.x,n.z)
	var d=toward-c
	return c+Vector2(half*signf(d.x if absf(d.x)>0.01 else 1.0),half*signf(d.y if absf(d.y)>0.01 else 1.0))

func _graph_path(from_key: String,to_key: String) -> Array:
	if from_key==to_key: return [from_key]
	var open=[from_key]
	var came={}
	var cost={from_key:0.0}
	while not open.is_empty():
		var best_i=0
		for i in range(open.size()):
			if cost[open[i]]<cost[open[best_i]]: best_i=i
		var current=open.pop_at(best_i)
		if current==to_key: break
		for edge in Roads.EDGES:
			if Roads.is_mountain(edge): continue
			var next=""
			if edge[0]==current: next=edge[1]
			elif edge[1]==current: next=edge[0]
			if next=="": continue
			var a: Vector3=Roads.NODES[current]
			var b: Vector3=Roads.NODES[next]
			var c=cost[current]+Vector2(a.x,a.z).distance_to(Vector2(b.x,b.z))
			if not cost.has(next) or c<cost[next]:
				cost[next]=c
				came[next]=current
				if not open.has(next): open.append(next)
	var path=[to_key]
	while path[0]!=from_key:
		if not came.has(path[0]): return []
		path.push_front(came[path[0]])
	return path

func route(from: Vector2,to: Vector2) -> Array:
	if from.distance_to(to)<25.0: return [to]
	var ea=_nearest_edge(from)
	var eb=_nearest_edge(to)
	if ea.is_empty() or eb.is_empty(): return [to]
	var pts: Array=[]
	# Leave a doorway into the forecourt alley, then out to the sidewalk.
	pts.append(from+Vector2(0,3.0))
	var sa=_sidewalk(ea.point,from,ea.edge)
	pts.append(sa)
	var best=[]
	var best_len=INF
	for ka in ea.edge:
		for kb in eb.edge:
			var path=_graph_path(ka,kb)
			if path.is_empty(): continue
			var length=0.0
			var prev=sa
			for k in path:
				var n: Vector3=Roads.NODES[k]
				length+=prev.distance_to(Vector2(n.x,n.z))
				prev=Vector2(n.x,n.z)
			length+=prev.distance_to(eb.point)
			if length<best_len: best_len=length; best=path
	var sb=_sidewalk(eb.point,to,eb.edge)
	for i in range(best.size()):
		var toward=sb
		if i+1<best.size():
			var n2: Vector3=Roads.NODES[best[i+1]]
			toward=Vector2(n2.x,n2.z)
		pts.append(_node_corner(best[i],toward))
	pts.append(sb)
	pts.append(to+Vector2(0,3.0))
	pts.append(to)
	return pts

# ---------------------------------------------------------------- npcs
func _spawn(entry: Dictionary) -> void:
	var node=_make_body()
	node.name="NPC_"+entry.id
	world.add_child(node)
	var visual=StudentVisual.new()
	visual.palette=entry.look
	node.add_child(visual)
	var tag=Label3D.new()
	tag.text=entry.name
	tag.font_size=36
	tag.pixel_size=0.012
	tag.position=Vector3(0,2.35,0)
	tag.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate=Color("ffe9b8")
	tag.outline_size=6
	tag.outline_modulate=Color("1a1626")
	tag.no_depth_test=true
	tag.visible=false
	node.add_child(tag)
	var marker=Label3D.new()
	marker.text="!"
	marker.font_size=96
	marker.pixel_size=0.012
	marker.position=Vector3(0,2.85,0)
	marker.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	marker.modulate=Color("ffcf3a")
	marker.outline_size=8
	marker.outline_modulate=Color("3a2a00")
	marker.no_depth_test=true
	node.add_child(marker)
	if not social.has(entry.id): social[entry.id]={"points":0,"talked_day":0,"gifted_day":0,"quest":"offer","reached":false}
	var npc={"data":entry,"node":node,"visual":visual,"tag":tag,"marker":marker,"slot":-1,"path":[],"inside":false,"activity":"idle","place":"","home":Vector2.ZERO,"stopped":false}
	npcs.append(npc)
	by_id[entry.id]=npc

func _slot_for(npc: Dictionary) -> int:
	var hour=minutes/60.0
	var index=0
	for i in range(npc.data.routine.size()):
		if hour>=float(npc.data.routine[i][0]): index=i
	return index

func _settle(npc: Dictionary) -> void:
	# Place an NPC directly at its current routine spot (start of game / after a long skip).
	var slot=_slot_for(npc)
	npc.slot=slot
	var step=npc.data.routine[slot]
	var p=_stand_point(npc,step[1])
	npc.node.position=_free_spot(p)
	npc.path=[]
	npc.place=step[1]
	npc.activity=step[2]
	npc.inside=step[2]=="inside" and places.has(step[1]) and places[step[1]].door
	_set_present(npc.node,not npc.inside)

func _stand_point(npc: Dictionary,key: String) -> Vector2:
	# Spread people who share a spot so they don't stand inside each other.
	var base=place_point(key)
	var h=absi(hash(npc.data.id))
	return base+Vector2(float(h%7)-3.0,float((h/7)%5)-1.0)*0.9

func _player_near(p: Vector3,radius: float) -> bool:
	return world.player.global_position.distance_to(p)<radius

func _process(delta: float) -> void:
	if world.player==null: return
	var frozen=not talking.is_empty() or journal_open or world.player.paused or world.interiors.inside
	if not frozen: _advance_clock(delta)
	clock_label.text="DAY %d   %02d:%02d   ·   %s K\nENERGY %d" % [day,int(minutes/60)%24,int(minutes)%60,_commas(kyat),int(stats.Energy)]
	for npc in npcs: _update_npc(npc,delta,frozen)
	for walker in ambient: _update_ambient(walker,delta,frozen)
	_update_prompt()
	_check_quest_triggers()
	if toast_time>0:
		toast_time-=delta
		toast.modulate.a=clampf(toast_time,0,1)
	if dirty: _save(); dirty=false

func _advance_clock(delta: float) -> void:
	minutes+=delta*GAME_MINUTES_PER_SECOND
	stats.Energy=maxf(0.0,float(stats.Energy)-delta*GAME_MINUTES_PER_SECOND/60.0*2.0)
	if minutes>=24*60:
		minutes-=24*60
		day+=1
		_spawn_pickups()
		dirty=true
	# Lighting follows the clock: day 06-17, dusk 17-19, night 19-06. N still overrides until the next change.
	var hour=minutes/60.0
	var mode=0 if hour>=6 and hour<17 else (1 if hour>=17 and hour<19 else 2)
	if follow_clock and mode!=last_mode:
		last_mode=mode
		world.time_mode=mode
		world._apply_time()

func _update_npc(npc: Dictionary,delta: float,frozen: bool) -> void:
	var node: Node3D=npc.node
	var marker: Label3D=npc.marker
	var state=social[npc.data.id]
	marker.visible=node.visible and _quest_marker(npc)!=""
	marker.text=_quest_marker(npc)
	npc.tag.visible=node.visible and _player_near(node.global_position,14.0)
	if frozen or npc.stopped:
		npc.visual.animate(delta,0.0,0.0,false,true)
		return
	var slot=_slot_for(npc)
	if slot!=npc.slot:
		npc.slot=slot
		var step=npc.data.routine[slot]
		var target=_stand_point(npc,step[1])
		npc.place=step[1]
		npc.activity=step[2]
		var here=Vector2(node.position.x,node.position.z)
		if npc.inside:
			# Leave by the door they went in.
			npc.inside=false
			_set_present(node,true)
		var far=not _player_near(node.global_position,110.0) and not _player_near(Vector3(target.x,0,target.y),110.0)
		if far:
			# Off-screen travel: never teleports in view of the player.
			node.position=_free_spot(target)
			npc.path=[]
		else:
			npc.path=route(here,target)
	if not npc.path.is_empty():
		var goal: Vector2=npc.path[0]
		var result=_walk_step(npc,goal,WALK_SPEED,delta)
		if result!=0: npc.path.pop_front()
		if npc.path.is_empty() and npc.activity=="inside" and places.has(npc.place) and places[npc.place].door:
			npc.inside=true
			_set_present(node,false)
	else:
		npc.visual.animate(delta,0.0,0.0,false,true)
		if not _player_near(node.global_position,4.0) and npc.activity!="inside":
			# Idle: face the street (south, toward the camera).
			npc.visual.rotation.y=lerp_angle(npc.visual.rotation.y,PI,clampf(delta*2.0,0,1))

# ---------------------------------------------------------------- relationships and quests
func level_of(points: int) -> int:
	var level=0
	for i in range(LEVELS.size()):
		if points>=LEVELS[i][0]: level=i
	return level

func level_name(points: int) -> String:
	return LEVELS[level_of(points)][1]

func hearts(points: int) -> String:
	var full=int(points/10)
	return "♥".repeat(full)+"♡".repeat(10-full)

func add_points(id: String,amount: int,reason: String) -> void:
	var state=social[id]
	var before=level_of(state.points)
	state.points=clampi(state.points+amount,0,100)
	dirty=true
	var after=level_of(state.points)
	var name_text=by_id[id].data.name
	if after>before: show_toast("%s is now your %s!  (%s)" % [name_text,LEVELS[after][1].to_lower(),reason])
	elif amount!=0: show_toast("%s  %+d friendship  (%s)" % [name_text,amount,reason])

func _quest_marker(npc: Dictionary) -> String:
	var q=npc.data.quest
	var state=social[npc.data.id]
	if state.quest=="offer": return "!"
	if state.quest=="active" and _quest_ready(npc): return "?"
	# Delivery and collection targets also show a marker.
	for other in npcs:
		var oq=other.data.quest
		if social[other.data.id].quest!="active": continue
		if oq.type=="deliver" and oq.to==npc.data.id and inventory.get(oq.item,0)>0: return "?"
		if oq.type=="collect" and oq.from==npc.data.id and inventory.get(oq.item,0)==0: return "?"
	return ""

func _quest_ready(npc: Dictionary) -> bool:
	var q=npc.data.quest
	var state=social[npc.data.id]
	match q.type:
		"fetch": return inventory.get(q.item,0)>0
		"visit": return state.reached
		"collect": return inventory.get(q.item,0)>0
		_: return false

func _check_quest_triggers() -> void:
	var p=Vector2(world.player.global_position.x,world.player.global_position.z)
	for npc in npcs:
		var q=npc.data.quest
		var state=social[npc.data.id]
		if state.quest!="active": continue
		if q.type=="visit" and not state.reached and p.distance_to(place_point(q.place))<9.0:
			state.reached=true
			dirty=true
			show_toast("Quest: %s  ·  reached %s. Report back to %s." % [q.title,place_label(q.place),npc.data.name])
		if q.type=="meet":
			var hour=minutes/60.0
			var spot=place_point(q.place)
			if hour>=q.window[0] and hour<q.window[1] and p.distance_to(spot)<9.0 and npc.node.visible and Vector2(npc.node.position.x,npc.node.position.z).distance_to(spot)<12.0:
				_complete(npc)

func _complete(npc: Dictionary) -> void:
	var q=npc.data.quest
	var state=social[npc.data.id]
	state.quest="done"
	if q.has("item") and q.type in ["fetch","collect"]: _take(q.item)
	kyat+=int(q.kyat)
	add_points(npc.data.id,int(q.points),"quest: "+q.title)
	show_toast("Quest complete: %s   +%d K" % [q.title,int(q.kyat)])
	_say(npc,q.done)
	dirty=true

func _give(item: String) -> void:
	inventory[item]=int(inventory.get(item,0))+1
	dirty=true

func _take(item: String) -> void:
	inventory[item]=maxi(0,int(inventory.get(item,0))-1)
	if inventory[item]==0: inventory.erase(item)
	dirty=true

# ---------------------------------------------------------------- pickups
func _spawn_pickups() -> void:
	for p in pickups:
		if is_instance_valid(p.node): p.node.queue_free()
	pickups.clear()
	for entry in Data.PICKUPS:
		var at: Vector2=place_point(entry[1])+Vector2(2.5,0.5) if entry[1] is String else entry[1]
		var node=Node3D.new()
		node.name="Pickup_"+entry[0]
		node.position=Vector3(at.x,_ground(at)+0.6,at.y)
		world.add_child(node)
		var gem=MeshInstance3D.new()
		var mesh=BoxMesh.new()
		mesh.size=Vector3(0.35,0.35,0.35)
		gem.mesh=mesh
		gem.material_override=world._mat("ffd36a",0.3,3.0)
		gem.rotation=Vector3(0.6,0.6,0)
		node.add_child(gem)
		var label=Label3D.new()
		label.text=Data.ITEMS[entry[0]]
		label.font_size=32
		label.pixel_size=0.01
		label.position=Vector3(0,0.55,0)
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate=Color("fff2c0")
		label.outline_size=5
		label.outline_modulate=Color("2a2000")
		label.no_depth_test=true
		node.add_child(label)
		pickups.append({"item":entry[0],"node":node,"gem":gem})

# ---------------------------------------------------------------- interaction
func _nearest_npc() -> Dictionary:
	var best={}
	var nearest=2.8
	for npc in npcs:
		if not npc.node.visible: continue
		var d=world.player.global_position.distance_to(npc.node.global_position)
		if d<nearest: nearest=d; best=npc
	return best

func _nearest_walker() -> Dictionary:
	for w in ambient:
		if w.node.visible and world.player.global_position.distance_to(w.node.global_position)<2.2: return w
	return {}

func _nearest_spot() -> Dictionary:
	for sp in world.activity_spots:
		if sp.has("bay_index"): continue
		if world.player.global_position.distance_to(sp.pos)<3.2: return sp
	return {}

func _nearest_pickup() -> Dictionary:
	for p in pickups:
		if is_instance_valid(p.node) and world.player.global_position.distance_to(p.node.global_position)<2.4: return p
	return {}

func _update_prompt() -> void:
	for p in pickups:
		if is_instance_valid(p.gem): p.gem.rotate_y(0.04)
	if talking.is_empty() and not journal_open and world.interiors.inside and world.interiors.active_index>=0:
		var title: String=world.interiors.records[world.interiors.active_index].title
		var n=activities.actions_for(title).size()
		prompt.text="[Q] %d thing%s to do in %s" % [n,"" if n==1 else "s",title.get_slice(" / ",0).capitalize()] if n>0 else ""
		return
	if not talking.is_empty() or journal_open or world.player.transit_mode or world.interiors.inside:
		prompt.text=""
		return
	var bay: Dictionary=world.garage.nearby_hangar_bay()
	if not bay.is_empty():
		prompt.text="[Q] %s   ·   [C] Pilot" % bay.interaction.title.capitalize()
		return
	var npc=_nearest_npc()
	if not npc.is_empty():
		var state=social[npc.data.id]
		prompt.text="[Q] Talk to %s   ·   %s %s" % [npc.data.name,level_name(state.points),hearts(state.points)]
		return
	var pick=_nearest_pickup()
	if not pick.is_empty():
		prompt.text="[Q] Pick up %s" % Data.ITEMS[pick.item]
		return
	var sp=_nearest_spot()
	if not sp.is_empty():
		prompt.text="[Q] %s" % sp.title.capitalize()
		return
	if not _nearest_walker().is_empty():
		prompt.text="[Q] Say hello"
		return
	prompt.text=""

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	var key=event.physical_keycode
	if not talking.is_empty():
		if key in [KEY_ESCAPE,KEY_Q]: _close_dialogue()
		elif key>=KEY_1 and key<=KEY_9:
			var buttons=options_box.get_children()
			var i=key-KEY_1
			if i<buttons.size(): buttons[i].pressed.emit()
		get_viewport().set_input_as_handled()
		return
	if key==KEY_H:
		_toggle_journal()
		get_viewport().set_input_as_handled()
		return
	if journal_open and key==KEY_ESCAPE:
		_toggle_journal()
		get_viewport().set_input_as_handled()
		return
	if key==KEY_Q and world.interiors.inside and world.interiors.active_index>=0 and not world.interiors.busy:
		var title: String=world.interiors.records[world.interiors.active_index].title
		if not activities.actions_for(title).is_empty():
			activities.open(title)
			get_viewport().set_input_as_handled()
			return
	if key==KEY_Q and not world.player.transit_mode and not world.interiors.inside and not world.player.paused:
		var bay: Dictionary=world.garage.nearby_hangar_bay()
		if not bay.is_empty():
			activities.open(bay.interaction.title)
			get_viewport().set_input_as_handled()
			return
		var npc=_nearest_npc()
		if not npc.is_empty():
			_open_dialogue(npc)
			get_viewport().set_input_as_handled()
			return
		var walker=_nearest_walker()
		if not walker.is_empty() and _nearest_pickup().is_empty() and _nearest_spot().is_empty():
			var hellos=["Mingalaba!","Nice weather today, cadet.","Have you tried the night market?","The ferry's running late again.","Good luck with your training!","Busy day at the market.","Mind the traffic lights!","Lovely sunset tonight."]
			show_toast(hellos[(day*7+int(minutes)+absi(hash(walker.node.name)))%hellos.size()])
			if int(stats.get("greet_day",0))!=day:
				stats.greet_day=day
				stats.Charm=int(stats.Charm)+1
			get_viewport().set_input_as_handled()
			return
		var sp=_nearest_spot()
		if not sp.is_empty() and _nearest_pickup().is_empty():
			activities.open(sp.title)
			get_viewport().set_input_as_handled()
			return
		var pick=_nearest_pickup()
		if not pick.is_empty():
			_give(pick.item)
			show_toast("Picked up: %s" % Data.ITEMS[pick.item])
			pick.node.queue_free()
			pickups.erase(pick)
			get_viewport().set_input_as_handled()

func _open_dialogue(npc: Dictionary) -> void:
	talking=npc
	npc.stopped=true
	var to_player=world.player.global_position-npc.node.global_position
	npc.visual.rotation.y=atan2(-to_player.x,-to_player.z)
	world.player.velocity=Vector3.ZERO
	world.player.paused=true
	panel.visible=true
	var state=social[npc.data.id]
	var greeting=_greeting(npc)
	_say(npc,greeting)
	_refresh_options()

func _close_dialogue() -> void:
	if talking.is_empty(): return
	talking.stopped=false
	talking={}
	panel.visible=false
	world.player.paused=false

func _say(npc: Dictionary,text: String) -> void:
	var state=social[npc.data.id]
	name_label.text=npc.data.name
	level_label.text="%s   ·   %s   %s" % [npc.data.role,level_name(state.points),hearts(state.points)]
	text_label.text=text

func _greeting(npc: Dictionary) -> String:
	var level=level_of(social[npc.data.id].points)
	var hour=int(minutes/60)
	var time_word="Good morning" if hour<12 else ("Good afternoon" if hour<17 else "Good evening")
	match level:
		0: return "%s. Oh, you're one of the YUST cadets, aren't you?" % time_word
		1: return "%s! Nice to see you again." % time_word
		2: return "Hey, friend! %s." % time_word.to_lower()
		_: return "There you are! I was hoping you'd come by."

func _refresh_options() -> void:
	for child in options_box.get_children(): child.queue_free()
	var npc=talking
	var state=social[npc.data.id]
	var q=npc.data.quest
	_option("Chat",_chat)
	if not inventory.is_empty(): _option("Give a gift",_gift_menu)
	_option("Ask about schedule",_schedule)
	# Quest actions for this NPC (as giver, delivery target or collection source).
	if state.quest=="offer": _option("Any favour I can do?",_offer_quest)
	elif state.quest=="active":
		if _quest_ready(npc): _option("Finish: "+q.title,_finish_quest)
		else: _option("About: "+q.title,_quest_about)
	for other in npcs:
		var oq=other.data.quest
		if social[other.data.id].quest!="active": continue
		if oq.type=="deliver" and oq.to==npc.data.id and inventory.get(oq.item,0)>0:
			_option("Deliver "+Data.ITEMS[oq.item],func(): _deliver(other,npc))
		if oq.type=="collect" and oq.from==npc.data.id and inventory.get(oq.item,0)==0:
			_option("Ask for "+Data.ITEMS[oq.item],func(): _collect(other,npc))
	_option("Bye",_close_dialogue)

func _option(text: String,action: Callable) -> void:
	var button=Button.new()
	button.text="%d  %s" % [options_box.get_child_count()+1,text]
	button.focus_mode=Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size",14)
	button.pressed.connect(action)
	options_box.add_child(button)

func _chat() -> void:
	var npc=talking
	var state=social[npc.data.id]
	var lines: Array=npc.data.lines
	var line=lines[(day+int(minutes/90)+absi(hash(npc.data.id)))%lines.size()]
	_say(npc,line)
	if int(state.talked_day)!=day:
		state.talked_day=day
		add_points(npc.data.id,4,"chat")

func _schedule() -> void:
	var npc=talking
	var parts=[]
	for step in npc.data.routine:
		var where=place_label(step[1])
		if step[2]=="inside": where="inside "+where
		parts.append("%02d:00 %s" % [int(step[0]),where])
	var nxt=npc.data.routine[(npc.slot+1)%npc.data.routine.size()]
	_say(npc,"Next I'll be at %s around %02d:00.\n%s" % [place_label(nxt[1]),int(nxt[0]),"   ·   ".join(parts)])

func _gift_menu() -> void:
	for child in options_box.get_children(): child.queue_free()
	for item in inventory.keys():
		var it: String=item
		_option("%s x%d" % [Data.ITEMS[it],inventory[it]],func(): _gift(it))
	_option("Back",_refresh_options)

func _gift(item: String) -> void:
	var npc=talking
	var state=social[npc.data.id]
	if int(state.gifted_day)==day:
		_say(npc,"You already gave me something today. Save it for tomorrow!")
		_refresh_options()
		return
	_take(item)
	state.gifted_day=day
	if item in npc.data.loves:
		_say(npc,"%s? This is my favourite! How did you know?" % Data.ITEMS[item])
		add_points(npc.data.id,12,"loved gift")
	elif item in npc.data.likes:
		_say(npc,"Oh, %s. That's thoughtful, thank you." % Data.ITEMS[item].to_lower())
		add_points(npc.data.id,7,"liked gift")
	else:
		_say(npc,"For me? Thanks.")
		add_points(npc.data.id,2,"gift")
	_refresh_options()

func _offer_quest() -> void:
	var npc=talking
	var q=npc.data.quest
	_say(npc,q.text)
	for child in options_box.get_children(): child.queue_free()
	_option("Accept: "+q.title,_accept_quest)
	_option("Maybe later",_refresh_options)

func _accept_quest() -> void:
	var npc=talking
	var q=npc.data.quest
	social[npc.data.id].quest="active"
	if q.type=="deliver": _give(q.item)
	show_toast("Quest accepted: %s  (H for journal)" % q.title)
	dirty=true
	_say(npc,"Thank you! "+_quest_status(npc))
	_refresh_options()

func _finish_quest() -> void:
	_complete(talking)
	_refresh_options()

func _quest_about() -> void:
	_say(talking,_quest_status(talking))

func _quest_status(npc: Dictionary) -> String:
	var q=npc.data.quest
	match q.type:
		"fetch": return "Bring me %s." % Data.ITEMS[q.item].to_lower()
		"deliver": return "Take the %s to %s." % [Data.ITEMS[q.item].to_lower(),by_id[q.to].data.name]
		"collect": return "Get the %s from %s." % [Data.ITEMS[q.item].to_lower(),by_id[q.from].data.name]
		"visit": return "Go to %s, then come back to me." % place_label(q.place)
		"meet": return "Meet me at %s between %02d:00 and %02d:00." % [place_label(q.place),int(q.window[0]),int(q.window[1])]
	return ""

func _deliver(giver: Dictionary,receiver: Dictionary) -> void:
	var q=giver.data.quest
	_take(q.item)
	social[giver.data.id].quest="done"
	kyat+=int(q.kyat)
	add_points(giver.data.id,int(q.points),"quest: "+q.title)
	add_points(receiver.data.id,5,"delivery")
	show_toast("Quest complete: %s   +%d K" % [q.title,int(q.kyat)])
	_say(receiver,"From %s? That's so kind of you both." % giver.data.name)
	dirty=true
	_refresh_options()

func _collect(giver: Dictionary,source: Dictionary) -> void:
	var q=giver.data.quest
	_give(q.item)
	_say(source,"Ugh, fine. Tell %s I'm sorry it's late." % giver.data.name)
	add_points(source.data.id,2,"errand")
	_refresh_options()

# ---------------------------------------------------------------- journal, toast, UI
func _toggle_journal() -> void:
	journal_open=not journal_open
	journal.visible=journal_open
	if not journal_open: return
	var t="[b]RELATIONSHIPS[/b]\n"
	for npc in npcs:
		var s=social[npc.data.id]
		var where=place_label(npc.place)
		t+="%s  [color=#b9a8d8]%s[/color]\n    %s %s   ·   now: %s\n" % [npc.data.name,npc.data.role,level_name(s.points),hearts(s.points),("inside " if npc.inside else "")+where]
	t+="\n[b]QUESTS[/b]\n"
	for npc in npcs:
		var s=social[npc.data.id]
		var q=npc.data.quest
		if s.quest=="active": t+="[color=#ffd36a]ACTIVE[/color]  %s  (%s): %s\n" % [q.title,npc.data.name,_quest_status(npc)]
	for npc in npcs:
		if social[npc.data.id].quest=="done": t+="[color=#7dff9a]DONE[/color]  %s  (%s)\n" % [npc.data.quest.title,npc.data.name]
	var offers=0
	for npc in npcs:
		if social[npc.data.id].quest=="offer": offers+=1
	t+="%d more people have a favour to ask (look for [color=#ffcf3a]![/color]).\n" % offers
	t+="\n[b]YOU[/b]   Energy %d   ·   %s\n" % [int(stats.Energy),activities._stats_line()]
	t+="\n[b]BAG[/b]   %s K\n" % _commas(kyat)
	for item in inventory: t+="  %s x%d\n" % [Data.ITEMS[item],inventory[item]]
	journal_text.text=t

func show_toast(text: String) -> void:
	toast.text=text
	toast_time=4.0
	toast.modulate.a=1.0

func _commas(v: int) -> String:
	var s=str(v)
	var out=""
	while s.length()>3:
		out=","+s.substr(s.length()-3)+out
		s=s.substr(0,s.length()-3)
	return s+out

func _ui() -> void:
	var layer=CanvasLayer.new()
	layer.layer=30
	add_child(layer)
	clock_label=Label.new()
	clock_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	clock_label.position=Vector2(-252,332)
	clock_label.add_theme_font_size_override("font_size",18)
	clock_label.add_theme_color_override("font_color",Color("fff2d6"))
	clock_label.add_theme_color_override("font_shadow_color",Color("1a1626"))
	clock_label.add_theme_constant_override("shadow_offset_y",2)
	layer.add_child(clock_label)
	prompt=Label.new()
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.position=Vector2(-260,-170)
	prompt.add_theme_font_size_override("font_size",19)
	prompt.add_theme_color_override("font_color",Color("ffe9b8"))
	prompt.add_theme_color_override("font_shadow_color",Color("1a1626"))
	prompt.add_theme_constant_override("shadow_offset_y",2)
	layer.add_child(prompt)
	toast=Label.new()
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast.position=Vector2(-300,110)
	toast.add_theme_font_size_override("font_size",18)
	toast.add_theme_color_override("font_color",Color("ffd6f2"))
	toast.add_theme_color_override("font_shadow_color",Color("1a1626"))
	toast.add_theme_constant_override("shadow_offset_y",2)
	layer.add_child(toast)
	panel=PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	panel.position=Vector2(-430,-300)
	panel.custom_minimum_size=Vector2(860,190)
	var style=StyleBoxFlat.new()
	style.bg_color=Color(0.07,0.06,0.13,0.95)
	style.border_color=Color("b07dff")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left=20
	style.content_margin_right=20
	style.content_margin_top=14
	style.content_margin_bottom=14
	panel.add_theme_stylebox_override("panel",style)
	var col=VBoxContainer.new()
	col.add_theme_constant_override("separation",6)
	panel.add_child(col)
	name_label=Label.new()
	name_label.add_theme_font_size_override("font_size",20)
	name_label.add_theme_color_override("font_color",Color("ffd36a"))
	col.add_child(name_label)
	level_label=Label.new()
	level_label.add_theme_font_size_override("font_size",13)
	level_label.add_theme_color_override("font_color",Color("cbb8ff"))
	col.add_child(level_label)
	text_label=Label.new()
	text_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size=Vector2(820,56)
	text_label.add_theme_font_size_override("font_size",16)
	text_label.add_theme_color_override("font_color",Color("f4f0fa"))
	col.add_child(text_label)
	options_box=HBoxContainer.new()
	options_box.add_theme_constant_override("separation",8)
	col.add_child(options_box)
	panel.visible=false
	layer.add_child(panel)
	journal=PanelContainer.new()
	journal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	journal.position=Vector2(-460,-330)
	journal.custom_minimum_size=Vector2(920,660)
	journal.add_theme_stylebox_override("panel",style)
	var scroll=ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(880,620)
	journal.add_child(scroll)
	journal_text=RichTextLabel.new()
	journal_text.bbcode_enabled=true
	journal_text.custom_minimum_size=Vector2(860,1400)
	journal_text.add_theme_font_size_override("normal_font_size",15)
	journal_text.add_theme_font_size_override("bold_font_size",17)
	scroll.add_child(journal_text)
	journal.visible=false
	layer.add_child(journal)

# ---------------------------------------------------------------- save / load
func _save() -> void:
	if "--no-save" in OS.get_cmdline_user_args(): return
	var file=FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if file==null: return
	file.store_string(JSON.stringify({"day":day,"minutes":minutes,"kyat":kyat,"inventory":inventory,"social":social,"stats":stats,"garage":world.garage.save_state() if world.garage else {}}))

func _load() -> void:
	if "--fresh-social" in OS.get_cmdline_user_args() or not FileAccess.file_exists(SAVE_PATH): return
	var data=JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(data)!=TYPE_DICTIONARY: return
	day=int(data.get("day",1))
	minutes=float(data.get("minutes",7*60))
	kyat=int(data.get("kyat",5000))
	for k in data.get("inventory",{}): inventory[k]=int(data.inventory[k])
	for k in data.get("stats",{}): stats[k]=data.stats[k]
	if data.has("garage"): pending_garage=data.garage
	for k in data.get("social",{}):
		var s=data.social[k]
		social[k]={"points":int(s.get("points",0)),"talked_day":int(s.get("talked_day",0)),"gifted_day":int(s.get("gifted_day",0)),"quest":str(s.get("quest","offer")),"reached":bool(s.get("reached",false))}


# ---------------------------------------------------------------- ambient crowd (non-interactive)
const SHIRTS=["e2574c","4fa3c7","f2c94c","7ad08a","ef8fb0","b07ad8","ff9a4a","3fb3a3","f1ece0","2f4a63","c0505a","6aa060"]
const LONGYI=["5a3a6a","3a4a7a","6a3a3a","2f5a4a","4a3a2a","7a2f4a","33465f","2a2a30","8a5a3a"]
const HAIR=["15151a","1e1a1a","2a2420","3a2a20","c8c8c8","241c20"]
const SKIN=["be885e","a8774f","c9966b","8f6342","d2a379"]

func _spawn_ambient(count: int) -> void:
	arng.seed=2026112002
	# Destinations: every building door, routine place, bus stop, station entrance and promenade spot.
	for key in places:
		if key=="_unresolved": continue
		var pl=places[key]
		ambient_spots.append(pl.point+(Vector2(0,3.0) if pl.door else Vector2.ZERO))
	for stop in world.buses.stops:
		ambient_spots.append(Vector2(stop.queue.x,stop.queue.z))
	for station in world.skytrain.stations:
		ambient_spots.append(Vector2(station.ground.x,station.ground.z))
	var x=60.0
	while x<802.82:
		ambient_spots.append(Vector2(x,Layout.shore(x)+14.0))
		x+=60.0
	for i in range(count):
		# Background people are data, not physics: a plain marker on a sidewalk route (see _ghost_step).
		var node=Node3D.new()
		node.name="Pedestrian_%d"%i
		world.add_child(node)
		var visual=StudentVisual.new()
		var student=arng.randf()<0.3
		visual.palette={"jacket":SHIRTS[arng.randi_range(0,SHIRTS.size()-1)],"sleeve":SHIRTS[arng.randi_range(0,SHIRTS.size()-1)],
			"trousers":LONGYI[arng.randi_range(0,LONGYI.size()-1)],"hair":HAIR[arng.randi_range(0,HAIR.size()-1)],
			"skin":SKIN[arng.randi_range(0,SKIN.size()-1)],"backpack":student,"thanaka":arng.randf()<0.35,
			"height":arng.randf_range(0.82,1.06),"pack":SHIRTS[arng.randi_range(0,SHIRTS.size()-1)]}
		node.add_child(visual)
		var start: Vector2=ambient_spots[arng.randi_range(0,ambient_spots.size()-1)]
		start+=Vector2(arng.randf_range(-3,3),arng.randf_range(-1,1))
		node.position=_free_spot(start)
		var walker={"ray_clock":arng.randf_range(0,0.2),"think":arng.randf_range(0,1.0),"want":"","inside":false,"node":node,"visual":visual,"path":[],"wait":arng.randf_range(0,40),"night_owl":arng.randf()<0.3,"home":start,"speed":arng.randf_range(1.3,1.9)}
		_assign_life(walker)
		ambient.append(walker)
	# Start everyone where their routine says they are right now.
	for walker in ambient:
		walker.want=_wanted(walker)
		_head_to(walker,walker.want,true)

const HOTSPOTS={
	"morning":["b:TEA / MOHINGA SHOP","b:TEA HOUSE","campus_walk","campus_quad","station_c1","b:PILOT SCHOOL","b:CLASSROOMS A","b:FOOD & COMMONS","b:NOODLE / FOOD COURT"],
	"midday":["b:PRODUCE / EVERYDAY MARKET","b:FOOD QUARTER","b:MARKET TEA HOUSE","b:TEA HOUSE","b:NOODLE / FOOD COURT","central_park","b:STUDENT UNION / CAFE","b:FISH MARKET / FOOD","b:DEPARTMENT STORE / SHOPS"],
	"evening":["promenade","promenade_west","beach","central_park","campus_quad","b:HARBOUR TEA SHOP","b:TEA HOUSE","harbour_quay","canal_bridge"],
	"night":["night_market","b:NIGHT MARKET ARCADE","b:NEON ARCADE","promenade","b:CINEMA / KARAOKE","b:TEA HOUSE","b:SEAFOOD RESTAURANTS / FOOD"],
}

func _hotspot_now() -> Vector2:
	var hour=minutes/60.0
	var key="night" if hour>=19 or hour<6 else ("morning" if hour<10 else ("midday" if hour<15 else "evening"))
	var list: Array=HOTSPOTS[key]
	var place: String=list[arng.randi_range(0,list.size()-1)]
	var p=place_point(place)
	if places.has(place) and places[place].door: p+=Vector2(0,3.5)
	# Loose cluster: people gather within a few metres of the spot, not on one point.
	return p+Vector2(arng.randf_range(-6,6),arng.randf_range(-2.5,4))

func _pick_destination(from: Vector2) -> Vector2:
	# Busy places draw most people (they change through the day); the rest wander the town.
	if arng.randf()<0.7: return _hotspot_now()
	for attempt in range(8):
		var p: Vector2=ambient_spots[arng.randi_range(0,ambient_spots.size()-1)]
		var d=p.distance_to(from)
		if d>40.0 and d<380.0: return p+Vector2(arng.randf_range(-3,3),arng.randf_range(-1,1))
	return ambient_spots[arng.randi_range(0,ambient_spots.size()-1)]

# Background people: role, home and workplace from the real buildings, and a simple daily routine.
const ROLES=[
	["student",22,["CLASSROOMS","PILOT SCHOOL","LIBRARY","SIMULATOR","RESEARCH","PRIMARY SCHOOL","STUDENT UNION"],8.0,16.0],
	["office",16,["OFFICE","BANK","CITY HALL","CUSTOMS","DATA","DESIGN STUDIOS","POST OFFICE","MEDIA","SHIPPING"],9.0,17.0],
	["shopkeeper",14,["SHOP","MART","GROCERY","STORE","PHARMACY","BOOKSHOP","CONVENIENCE","LAUNDRY","TAILOR","AUGMENT","VENDING"],8.0,20.0],
	["food",12,["TEA","CAFE","NOODLE","FOOD","RESTAURANT","BAKERY","MOHINGA","SEAFOOD"],6.0,21.0],
	["vendor",8,["MARKET","CRAFTS","TEXTILES","PRODUCE","SPICE","WHOLESALE"],6.0,18.0],
	["harbour",8,["FISH MARKET","WAREHOUSE","SHIPYARD","MARINE","COLD STORAGE","CHANDLERY","DEPOT","DELIVERY"],6.0,16.0],
	["mechanic",8,["REPAIR","WORKSHOP","GARAGE","MECHA","ROBOT","CHARGING","BATTERY","ENGINEERING"],8.0,18.0],
	["medic",4,["HOSPITAL","CLINIC","CYBERNETICS"],7.0,19.0],
	["retiree",8,[],0.0,0.0],
]
const HOME_WORDS=["APARTMENTS","DORM","HOSTEL","HOME","CAPSULE","TERRACE"]

func _buildings_with(words: Array) -> Array:
	var out=[]
	for key in places:
		if not str(key).begins_with("b:"): continue
		for w in words:
			if w in str(key):
				out.append(key)
				break
	return out

func _assign_life(walker: Dictionary) -> void:
	var total=0
	for r in ROLES: total+=int(r[1])
	var roll=arng.randi_range(0,total-1)
	var role=ROLES[0]
	for r in ROLES:
		roll-=int(r[1])
		if roll<0:
			role=r
			break
	walker.role=role[0]
	var homes=_buildings_with(["DORM"] if role[0]=="student" and arng.randf()<0.6 else HOME_WORDS)
	if role[0]!="student": homes=homes.filter(func(k): return not "DORM" in str(k))   # dorms are for students
	if homes.is_empty(): homes=_buildings_with(HOME_WORDS)
	walker.home_key=homes[arng.randi_range(0,homes.size()-1)] if not homes.is_empty() else ""
	var works=_buildings_with(role[2])
	walker.work_key=works[arng.randi_range(0,works.size()-1)] if not works.is_empty() else ""
	if walker.work_key=="": walker.role="retiree"
	var jitter=arng.randf_range(-0.6,0.6)
	walker.start=float(role[3])+jitter
	walker.finish=float(role[4])+jitter
	walker.lunch=arng.randf()<0.5 and walker.role in ["student","office","mechanic","medic"]
	walker.evening=arng.randf()<0.6
	walker.bed=arng.randf_range(20.5,22.5) if not walker.night_owl else 23.8

func _wanted(walker: Dictionary) -> String:
	# Where this person should be right now: a building key ("b:...") or "spot" (a busy public place).
	var h=fposmod(minutes/60.0,24.0)
	var home: String=walker.home_key
	if h<6.0: return "spot" if walker.night_owl and h<1.5 else home
	if walker.role=="retiree":
		if h<7.0 or h>=walker.bed: return home
		if h<19.0: return "spot"
		return home
	if h>=walker.start-0.75 and h<walker.finish:
		if walker.lunch and h>=12.0 and h<13.0: return "spot"
		return walker.work_key if h>=walker.start-0.25 else "commute"
	if h>=walker.finish and h<walker.bed and walker.evening: return "spot"
	if h>=walker.bed or h<walker.start-0.75: return home
	return home

func _head_to(walker: Dictionary,want: String,instant=false) -> void:
	var node: Node3D=walker.node
	var goal: Vector2
	if want=="spot" or want=="commute" or want=="":
		goal=_hotspot_now() if want=="spot" else _pick_destination(Vector2(node.position.x,node.position.z))
	else:
		goal=place_point(want)+Vector2(arng.randf_range(-1.5,1.5),0.0)
	var here=Vector2(node.position.x,node.position.z)
	var was_inside: bool=walker.inside
	walker.inside=false
	node.visible=true
	var seen=_player_near(Vector3(here.x,0,here.y),110.0) or _player_near(Vector3(goal.x,0,goal.y),110.0)
	if instant or not seen:
		# Nobody is watching this trip: just be there.
		node.position=_free_spot(goal)
		walker.path=[]
		_arrived(walker)
	else:
		if was_inside: node.position=Vector3(here.x,_ground(here),here.y)
		walker.path=route(here,goal)
		walker.wait=0.0

func _arrived(walker: Dictionary) -> void:
	var want: String=walker.want
	if want.begins_with("b:"):
		walker.inside=true
		walker.node.visible=false
	else:
		walker.wait=arng.randf_range(20,90)

func _update_ambient(walker: Dictionary,delta: float,frozen: bool) -> void:
	var node: Node3D=walker.node
	var near=_player_near(node.position,90.0)
	if frozen:
		if near and node.visible: walker.visual.animate(delta,0.0,0.0,false,true)
		return
	walker.think=float(walker.think)-delta
	if walker.think<=0.0:
		walker.think=arng.randf_range(1.0,2.0)
		var want=_wanted(walker)
		# Changed plans, or a wanderer who has lingered long enough at a spot: go somewhere new.
		if want!=walker.want or (not walker.inside and walker.path.is_empty() and walker.wait<=0.0 and want in ["spot","commute"]):
			walker.want=want
			_head_to(walker,want)
	if walker.inside:
		return
	# Only people near the camera are drawn and animated; the rest are just a moving position.
	walker.visual.visible=near
	if walker.path.is_empty():
		walker.wait=float(walker.wait)-delta
		if near: walker.visual.animate(delta,0.0,0.0,false,true)
		return
	var target: Vector2=walker.path[0]
	if _ghost_step(walker,target,walker.speed,delta,near)!=0:
		walker.path.pop_front()
		if walker.path.is_empty(): _arrived(walker)


func _ghost_step(e: Dictionary,goal: Vector2,speed: float,delta: float,near: bool) -> int:
	# Background walker: follow the sidewalk route with no physics body. Near the player, one short ray
	# every 0.2 s spots a planter, cart or post ahead and the walker steps around it.
	var node: Node3D=e.node
	var here=Vector2(node.position.x,node.position.z)
	var d=here.distance_to(goal)
	if d<0.6: return 1
	var dir=(goal-here)/d
	if near:
		e.ray_clock=float(e.ray_clock)-delta
		if e.ray_clock<=0.0:
			e.ray_clock=0.2
			var from=node.position+Vector3.UP*0.6
			var q=PhysicsRayQueryParameters3D.create(from,from+Vector3(dir.x,0,dir.y)*1.2,1)
			if not world.get_world_3d().direct_space_state.intersect_ray(q).is_empty():
				e.side_dir=Vector2(-dir.y,dir.x)*(1.0 if arng.randf()<0.5 else -1.0)
				e.side_time=0.6
		if float(e.get("side_time",0.0))>0.0:
			e.side_time=float(e.side_time)-delta
			dir=(dir*0.3+Vector2(e.side_dir.x,e.side_dir.y)).normalized()
		for other in ambient:
			if other.node==node or not other.node.visible: continue
			var o=Vector2(other.node.position.x,other.node.position.z)
			var gap=here.distance_to(o)
			if gap<0.9 and gap>0.01: dir=(dir+(here-o)/gap*0.6).normalized()
	var step=minf(speed*delta,d)
	var p=here+dir*step
	node.position=Vector3(p.x,_ground(p),p.y)
	if near:
		e.visual.rotation.y=lerp_angle(e.visual.rotation.y,atan2(-dir.x,-dir.y),clampf(delta*10.0,0,1))
		e.visual.animate(delta,step,step/maxf(delta,0.0001),false,true)
	return 1 if step>=d else 0

# ---------------------------------------------------------------- bodies and obstacle-aware walking
const LAYER_PEOPLE := 2

func _make_body() -> CharacterBody3D:
	# People are physical: they collide with the world (layer 1) and the player cannot walk through them.
	# They do not collide with each other; a gentle separation keeps crowds from overlapping.
	var b=CharacterBody3D.new()
	b.collision_layer=LAYER_PEOPLE
	b.collision_mask=1
	b.floor_snap_length=0.6
	b.floor_max_angle=deg_to_rad(48)
	b.add_collision_exception_with(world.player)
	var shape=CollisionShape3D.new()
	var capsule=CapsuleShape3D.new()
	capsule.radius=0.28
	capsule.height=1.6
	shape.shape=capsule
	shape.position=Vector3(0,0.8,0)
	b.add_child(shape)
	return b

func _set_present(node: Node3D,present: bool) -> void:
	node.visible=present
	node.collision_layer=LAYER_PEOPLE if present else 0
	node.collision_mask=1 if present else 0

func _walk_step(e: Dictionary,goal: Vector2,speed: float,delta: float) -> int:
	# Returns 0 while walking, 1 on arrival, 2 when a waypoint is unreachable (caller skips it).
	var node: CharacterBody3D=e.node
	var here=Vector2(node.global_position.x,node.global_position.z)
	var d=here.distance_to(goal)
	if d<0.6: return 1
	var near=_player_near(node.global_position,130.0)
	var dir=(goal-here)/d
	if not near:
		# Far from the player nobody can see the street: cheap kinematic step along the route.
		var step=minf(speed*delta,d)
		var p=here+dir*step
		# Off-screen walkers still never stand inside anything solid.
		node.global_position=_free_spot(p)
		return 1 if step>=d else 0
	# Step aside for a moment when blocked, like a person would.
	if float(e.get("side_time",0.0))>0.0:
		e.side_time=float(e.side_time)-delta
		dir=(dir*0.35+Vector2(e.side_dir.x,e.side_dir.y)).normalized()
	# Keep a little personal space from other people nearby.
	for other in ambient:
		if other.node==node or not other.node.visible: continue
		var o=Vector2(other.node.global_position.x,other.node.global_position.z)
		var gap=here.distance_to(o)
		if gap<0.9 and gap>0.01: dir=(dir+(here-o)/gap*0.6).normalized()
	node.velocity=Vector3(dir.x*speed,node.velocity.y-18.0*delta if not node.is_on_floor() else -0.3,dir.y*speed)
	node.move_and_slide()
	var moved=Vector2(node.global_position.x,node.global_position.z).distance_to(here)
	e.visual.rotation.y=lerp_angle(e.visual.rotation.y,atan2(-dir.x,-dir.y),clampf(delta*10.0,0,1))
	e.visual.animate(delta,moved,moved/maxf(delta,0.0001),false,true)
	if moved<speed*delta*0.25:
		e.stuck=float(e.get("stuck",0.0))+delta
	else:
		e.stuck=0.0
	if float(e.get("stuck",0.0))>0.5:
		e.stuck=0.0
		e.tries=int(e.get("tries",0))+1
		var side=Vector2(-dir.y,dir.x)*(1.0 if int(e.tries)%2==1 else -1.0)
		e.side_dir=side
		e.side_time=0.7
		if int(e.tries)>6:
			e.tries=0
			return 2
	elif moved>speed*delta*0.6 and float(e.get("side_time",0.0))<=0.0:
		e.tries=0
	return 0


var _free_query: PhysicsShapeQueryParameters3D
func _free_spot(p: Vector2) -> Vector3:
	# Drop-in placements (spawns, off-screen arrivals) never land inside a wall, shelter or prop.
	if _free_query==null:
		_free_query=PhysicsShapeQueryParameters3D.new()
		var cap=CapsuleShape3D.new()
		cap.radius=0.32
		cap.height=1.4
		_free_query.shape=cap
		_free_query.collision_mask=1
	var space=world.get_world_3d().direct_space_state
	for r in [0.0,1.0,2.0,3.0,4.5,6.0,8.0]:
		for k in range(8 if r>0.0 else 1):
			var q=p+Vector2(cos(k*PI/4),sin(k*PI/4))*r
			if Layout.wet(q.x,q.y) or q.y<Layout.shore(q.x)+1.0: continue
			var y=_ground(q)
			_free_query.transform=Transform3D(Basis(),Vector3(q.x,y+1.05,q.y))
			if space.intersect_shape(_free_query,1).is_empty(): return Vector3(q.x,y,q.y)
	return Vector3(p.x,_ground(p),p.y)
