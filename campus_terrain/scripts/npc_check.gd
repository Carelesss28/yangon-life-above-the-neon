extends SceneTree
## Townspeople check: routines resolve, NPCs walk their day, and the full social loop works
## (talk, gift, accept quests, pick up items, fetch / deliver / collect / visit / meet, save file).
## Run: godot --headless --fixed-fps 60 --path . --script res://scripts/npc_check.gd -- --fresh-social
var failures=0
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func check(ok: bool,msg: String) -> void:
	print(("PASS " if ok else "FAIL ")+msg)
	if not ok: failures+=1

func run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await frames(5)
	var sys=world.npcs
	check(sys.npcs.size()==20,"Twenty townspeople spawned")
	check(sys.places["_unresolved"].is_empty(),"Every routine place and pickup resolves")
	check(sys.ambient.size()==150,"150 background people spawned")
	var interactive_only=true
	for w in sys.ambient:
		for n in sys.npcs:
			if w.node==n.node: interactive_only=false
	check(interactive_only,"Ambient pedestrians are not in the talk list")
	var homes=0
	for npc in sys.npcs:
		if npc.inside: homes+=1
	check(homes>=4 and homes<=16,"At 07:00 people are split between home, work and early shifts (%d inside)"%homes)
	# Walk the day: jump the clock to 08:30 next to Thura so he is visibly routed, then watch him move.
	var thura=sys.by_id["thura"]
	sys.minutes=8*60+30
	var start: Vector3=thura.node.position
	world.player.teleport(start+Vector3(5,0,5))
	await frames(10)
	check(not thura.path.is_empty() or thura.inside,"Thura sets off for class when the hour changes")
	await frames(60*20)
	check(thura.node.position.distance_to(start)>8.0 or thura.inside,"Thura walks along the streets (moved %.1f m)"%thura.node.position.distance_to(start))
	# Ambient crowd keeps moving: watch the pedestrians nearest the player.
	var moved=0
	var starts=[]
	for w in sys.ambient: starts.append(w.node.position)
	await frames(60*30)
	for i in range(sys.ambient.size()):
		if sys.ambient[i].node.position.distance_to(starts[i])>3.0: moved+=1
	check(moved>=15,"Ambient pedestrians walk around town (%d/50 moved in 30 s)"%moved)
	# Social loop with the mother: chat, gift, fetch quest.
	var mother=sys.by_id["mother"]
	mother.node.visible=true
	world.player.teleport(mother.node.position+Vector3(1.2,0.3,0))
	await frames(5)
	check(not sys._nearest_npc().is_empty() and sys._nearest_npc().data.id=="mother","Talk prompt appears next to Daw Khin May")
	sys._open_dialogue(mother)
	check(sys.panel.visible and world.player.paused,"Dialogue opens and pauses the player and clock")
	sys._chat()
	check(sys.social["mother"].points==4,"Daily chat raises friendship")
	sys._chat()
	check(sys.social["mother"].points==4,"Chatting twice the same day does not farm points")
	sys._offer_quest()
	sys._accept_quest()
	check(sys.social["mother"].quest=="active","Quest accepted: Tea leaves run")
	sys._close_dialogue()
	var pick=null
	for p in sys.pickups:
		if p.item=="tea_leaves": pick=p
	check(pick!=null,"Tea leaves pickup exists at the market tea house")
	world.player.teleport(pick.node.global_position-Vector3(0,0.5,0))
	await frames(5)
	check(not sys._nearest_pickup().is_empty(),"Pickup prompt appears")
	var ev=InputEventKey.new(); ev.physical_keycode=KEY_Q; ev.pressed=true
	sys._input(ev)
	check(sys.inventory.get("tea_leaves",0)==1,"Q picks up the tea leaves")
	world.player.teleport(mother.node.position+Vector3(1.2,0.3,0))
	sys._open_dialogue(mother)
	check(sys._quest_ready(mother),"Quest shows as ready to hand in")
	var before=sys.kyat
	sys._finish_quest()
	check(sys.social["mother"].quest=="done" and sys.kyat>before and sys.social["mother"].points>=19,"Fetch quest completes with friendship and kyat")
	sys.inventory["jasmine"]=1
	sys.social["mother"].gifted_day=0
	sys._gift("jasmine")
	check(sys.social["mother"].points>=31,"Loved gift gives a big boost (now %d, %s)"%[sys.social["mother"].points,sys.level_name(sys.social["mother"].points)])
	sys._close_dialogue()
	# Delivery: Dr. Yamin's chip to Nandar.
	sys._open_dialogue(sys.by_id["yamin"]); sys._offer_quest(); sys._accept_quest(); sys._close_dialogue()
	check(sys.inventory.get("chip",0)==1,"Delivery quest hands over the sensor data chip")
	sys._open_dialogue(sys.by_id["nandar"])
	sys._deliver(sys.by_id["yamin"],sys.by_id["nandar"])
	sys._close_dialogue()
	check(sys.social["yamin"].quest=="done" and sys.inventory.get("chip",0)==0,"Deliver to Nandar completes Dr. Yamin's quest")
	# Collection: Aye Chan's overdue book from Kyaw Zin.
	sys._open_dialogue(sys.by_id["ayechan"]); sys._offer_quest(); sys._accept_quest(); sys._close_dialogue()
	sys._open_dialogue(sys.by_id["kyawzin"]); sys._collect(sys.by_id["ayechan"],sys.by_id["kyawzin"]); sys._close_dialogue()
	sys._open_dialogue(sys.by_id["ayechan"]); sys._finish_quest(); sys._close_dialogue()
	check(sys.social["ayechan"].quest=="done","Collect-and-return quest completes")
	# Visit: Kyaw Zin's hill sprint.
	sys._open_dialogue(sys.by_id["kyawzin"]); sys._offer_quest(); sys._accept_quest(); sys._close_dialogue()
	var look: Vector2=sys.place_point("lookout")
	world.player.teleport(Vector3(look.x,world.Layout.height_at(look.x,look.y)+0.3,look.y))
	await frames(5)
	check(sys.social["kyawzin"].reached,"Reaching the hill lookout marks the visit")
	sys._open_dialogue(sys.by_id["kyawzin"]); sys._finish_quest(); sys._close_dialogue()
	check(sys.social["kyawzin"].quest=="done","Visit quest completes on return")
	# Meet: Thura at the launch bay between 16:00 and 18:00.
	sys._open_dialogue(thura); sys._offer_quest(); sys._accept_quest(); sys._close_dialogue()
	sys.minutes=16*60+20
	sys._settle(thura)
	var bay: Vector2=sys.place_point("launch_bay")
	world.player.teleport(Vector3(bay.x+2,world.Layout.height_at(bay.x+2,bay.y)+0.3,bay.y))
	await frames(10)
	check(sys.social["thura"].quest=="done","Meeting Thura at the launch bay in the time window completes")
	# Save file.
	sys._save()
	check(FileAccess.file_exists(sys.SAVE_PATH),"Progress saves to "+sys.SAVE_PATH)
	var done=0
	for id in sys.social:
		if sys.social[id].quest=="done": done+=1
	print("NPC_CHECK ","PASS" if failures==0 else "FAIL"," failures=",failures," quests_done=",done)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(sys.SAVE_PATH))
	await world._quit_cleanly()
