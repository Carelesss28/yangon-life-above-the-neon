extends SceneTree
## Every non-residential building has at least one activity; activities change money, time, stats.
var failures=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,msg: String) -> void:
	print(("PASS " if ok else "FAIL ")+msg)
	if not ok: failures+=1
func run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	for i in range(5): await physics_frame
	var sys=world.npcs
	var A=sys.activities
	var missing=[]
	var total=0
	var multi=0
	var residential=0
	for r in world.interiors.records:
		var acts=A.actions_for(r.title)
		if A.is_residential(r.title):
			residential+=1
			continue
		total+=1
		if acts.is_empty(): missing.append(r.title)
		if acts.size()>=2: multi+=1
	check(missing.is_empty(),"Every non-residential building has a function (%d buildings, missing: %s)"%[total,str(missing)])
	check(multi>=int(total*0.85),"Most offer two or more activities (%d of %d); %d residential"%[multi,total,residential])
	# Enter the tea house and do things.
	var idx=-1
	for i in range(world.interiors.records.size()):
		if world.interiors.records[i].title=="TEA HOUSE": idx=i
	world.interiors.enter(idx,false)
	for i in range(10): await physics_frame
	check(world.interiors.inside,"Entered the Tea House")
	var ev=InputEventKey.new(); ev.physical_keycode=KEY_Q; ev.pressed=true
	sys._input(ev)
	check(sys.panel.visible,"Q opens the activity menu inside")
	var k0=sys.kyat
	var m0=sys.minutes
	var acts=A.actions_for("TEA HOUSE")
	A._do("TEA HOUSE",acts[2])  # work a shift
	check(sys.kyat==k0+3000 and sys.minutes>=m0+59,"Working a shift pays and takes an hour")
	A._do("TEA HOUSE",acts[1])
	check(sys.inventory.get("tea_leaves",0)>=1,"Buying tea leaves adds a gift item")
	sys._close_dialogue()
	world.interiors.leave(false)
	for i in range(10): await physics_frame
	A._do("PILOT SCHOOL",A.actions_for("PILOT SCHOOL")[0])
	check(int(sys.stats.Piloting)>=3,"Class raises Piloting")
	var before_day=sys.day
	A._do("FAMILY HOME / ROOFTOP CAFE",A.actions_for("FAMILY HOME / ROOFTOP CAFE")[1])
	check(sys.day==before_day+1 and int(sys.minutes)==7*60 and sys.stats.Energy==100.0,"Sleeping at home skips to 07:00 next day")
	# Hill attractions: spots exist and the cable car / zipline carry the player.
	check(world.activity_spots.size()>=13,"Hill attractions have %d activity spots"%world.activity_spots.size())
	var titles=[]
	for sp in world.activity_spots:
		titles.append(sp.title)
		if A.actions_for(sp.title).is_empty(): check(false,"Spot without actions: "+sp.title)
	check(A.actions_for("CABLE CAR · LOWER STATION")[0].get("kind","")=="ride","Cable car is a real ride (see use_check)")
	check(A.actions_for("ZIPLINE TOWER")[0].get("kind","")=="ride","Zipline is a real ride (see use_check)")
	print("ACTIVITIES_CHECK ","PASS" if failures==0 else "FAIL"," failures=",failures)
	await world._quit_cleanly()
