extends SceneTree
## Usability check: buy and drive vehicles, call them with G, ride the cable car / zipline / Ferris wheel /
## ferry like the metro, pilot the training frame, and seafront / bench spots have actions.
var failures=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,msg: String) -> void:
	print(("PASS " if ok else "FAIL ")+msg)
	if not ok: failures+=1
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func key(code: int,down: bool) -> void:
	var e=InputEventKey.new()
	e.physical_keycode=code
	e.keycode=code
	e.pressed=down
	Input.parse_input_event(e)

func run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await frames(5)
	var sys=world.npcs
	var A=sys.activities
	var g=world.garage
	sys.kyat=1000000
	# Showroom: buy a car and a bicycle.
	var acts=A.actions_for("CAR SHOWROOM")
	check(acts.size()>=6,"Car showroom sells %d vehicles"%acts.size())
	A._do("CAR SHOWROOM",acts[1])   # Honda Fit
	check(g.owned.has("t_fit") and sys.kyat==1000000-120000,"Buying the Honda Fit takes the money and delivers the car")
	A._do("BIKE & SCOOTER SHOWROOM",A.actions_for("BIKE & SCOOTER SHOWROOM")[0])
	check(g.owned.has("bicycle"),"Bought a bicycle")
	# Drive the car along the district ring road.
	var car=g.owned["t_fit"]
	world.player.teleport(car.global_position+Vector3(1.5,0.3,0))
	await frames(5)
	g._enter(car)
	check(world.player.transit_mode and car.driving and world.camera.target==car,"C puts you in the driver's seat")
	var start=car.global_position
	car.heading=PI/2.0     # face west along the lot
	key(KEY_W,true)
	await frames(180)
	key(KEY_W,false)
	await frames(60)
	check(car.global_position.distance_to(start)>8.0,"The car drives (moved %.1f m)"%car.global_position.distance_to(start))
	g._exit()
	check(not world.player.transit_mode and world.player.visible,"C gets you out")
	# Call it across town with G.
	world.player.teleport(Vector3(394.37,world.Layout.height_at(394.37,313)+0.3,313))
	await frames(5)
	check(g.summon() and car.global_position.distance_to(world.player.global_position)<8.0,"G calls your car to you")
	# Rides like the metro.
	world.rides.set_process(false)
	for ride in ["cable_up","cable_down","zip","ferris"]:
		check(world.rides.start(ride),"Board "+ride)
		var mid=false
		var clearance=INF
		for i in range(60*70):
			world.rides._process(1.0/60.0)
			if world.rides.active.is_empty(): break
			if world.rides.active.t>3.0:
				mid=world.player.transit_mode
			if ride.begins_with("cable") and i>0:
				var pos: Vector3=world.player.global_position
				clearance=minf(clearance,pos.y-world.Layout.height_at(pos.x,pos.z))
		check(mid and not world.player.transit_mode,"Rode the whole "+ride+" and got off")
		if ride.begins_with("cable"):
			check(clearance>1.0,"%s stays above terrain (lowest clearance %.1f m)"%[ride,clearance])
	world.rides.set_process(true)
	check(world.rides.start("ferry"),"Board the ferry cruise")
	await frames(120)
	check(world.player.global_position.y>-2.0 and world.player.transit_mode,"On deck of the ferry")
	world.rides._finish(world.rides.active.end)
	await frames(20)
	check(world.player.is_on_floor() and absf(world.player.global_position.y-world.Layout.PROMENADE_Y)<0.4,"Ferry returns passengers to the pier deck")
	# Pilot the mecha on the training grounds.
	A._do("TRAINING FRAME",A.actions_for("TRAINING FRAME")[0])
	check(g.current!=null and g.current.kind=="mecha","Piloting the training frame")
	key(KEY_W,true)
	await frames(120)
	key(KEY_W,false)
	await frames(10)
	check(g.current.global_position.distance_to(world.hill.mecha_home)>2.0,"The frame walks")
	g._exit()
	# Use the same bay prompt and menu that the mobile Use button opens.
	check(world.hangar_bays.size()==4,"Four frames stand in the YUST mecha hangar")
	for bay in world.hangar_bays:
		var forward=13.0 if bay.name=="SERAPH" else 8.0
		world.player.teleport(bay.home+Vector3(0,0.3,forward))
		await frames(8)
		key(KEY_Q,true)
		await frames(2)
		key(KEY_Q,false)
		var opened=sys.panel.visible and sys.name_label.text==bay.interaction.title
		check(opened,"Use opens the correct boarding menu for "+str(bay.name))
		if not opened:
			sys._close_dialogue()
			continue
		var board_button=sys.options_box.get_child(0)
		check(board_button.text.ends_with("Climb in and pilot "+bay.name),"The boarding button names "+str(bay.name))
		board_button.pressed.emit()
		var fr=g.current
		check(fr!=null and fr.title==bay.name and world.player.transit_mode,"Climbed into "+str(bay.name))
		if fr==null: continue
		var st=fr.global_position
		key(KEY_W,true)
		await frames(150)
		key(KEY_W,false)
		await frames(20)
		check(fr.global_position.distance_to(st)>3.0,str(bay.name)+" walks out (%.1f m)"%fr.global_position.distance_to(st))
		g._exit()
	g.recall_frames()
	check(g.frames.is_empty(),"Frames return to their bays")
	var seraph: Dictionary=world.hangar_bays[1]
	world.player.teleport(seraph.home+Vector3(0,0.3,13))
	key(KEY_C,true)
	await frames(2)
	key(KEY_C,false)
	check(g.current!=null and g.current.title=="SERAPH","Board / Exit boards Seraph from outside the bay")
	await frames(2)
	key(KEY_C,true)
	await frames(2)
	key(KEY_C,false)
	check(g.current==null and not world.player.transit_mode,"Board / Exit climbs out of the frame")
	g.recall_frames()
	# Spots everywhere have actions.
	var bad=[]
	var kinds={}
	for sp in world.activity_spots:
		kinds[sp.title]=true
		if A.actions_for(sp.title).is_empty(): bad.append(sp.title)
	check(bad.is_empty(),"All %d activity spots have actions (%d kinds)"%[world.activity_spots.size(),kinds.size()])
	for t in ["BENCH","BEACH","HARBOUR CRANE","PIER END","FERRIS WHEEL","FERRY TERMINAL","TEST TRACK","MOTOR SERVICE GARAGE"]:
		check(kinds.has(t),"Usable: "+t)
	print("USE_CHECK ","PASS" if failures==0 else "FAIL"," failures=",failures)
	if DisplayServer.get_name()=="headless": quit(failures)
	else: await world._quit_cleanly()
