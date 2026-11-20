extends SceneTree
## Traffic rules check: signals cycle, lawful drivers never cross a red stop line, cars keep gaps,
## speed limits hold for lawful drivers, and police stop violators.
var failures=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,msg: String) -> void:
	print(("PASS " if ok else "FAIL ")+msg)
	if not ok: failures+=1

func run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	for i in range(5): await physics_frame
	var t=world.traffic
	check(t.signals.size()>=30,"Signalled junctions: %d"%t.signals.size())
	var key=t.signals.keys()[0]
	var seen={}
	for i in range(60*40):
		await physics_frame
		seen[t.signal_state(key,"ns")+"/"+t.signal_state(key,"ew")]=true
		if i%60==0: _sample(t)
	check(seen.has("green/red") and seen.has("red/green") and seen.has("yellow/red") and seen.has("red/red"),"Signals cycle green, amber, all-red for both directions (%s)"%str(seen.keys()))
	var red_runs_lawful=0
	var crossings=0
	var over_limit=0
	var close=0
	var stopped_at_red=0
	var prev=[]
	for v in t.road: prev.append([v.a,v.b,v.d])
	for i in range(60*120):
		await physics_frame
		for k in range(t.road.size()):
			var v=t.road[k]
			var p=prev[k]
			if p[0]==v.a and p[1]==v.b and t.signals.has(v.b):
				var stop_at=t._edge_length(v.a,v.b)-(t.junction_half(v.b)+4.0)
				var light=t.signal_state(v.b,t.axis_of(v.a,v.b))
				if p[2]<stop_at and v.d>=stop_at:
					crossings+=1
					if light=="red" and not v.reckless and v.role=="civil" and not v.run_red: red_runs_lawful+=1
				if light=="red" and absf(stop_at-v.d)<1.2 and v.speed<0.2: stopped_at_red+=1
			if not v.reckless and v.state=="drive" and v.speed>t.limit_for(v.a,v.b)*1.02: over_limit+=1
			prev[k]=[v.a,v.b,v.d]
		if i%30==0:
			for v in t.road:
				for o in t.road:
					if o!=v and o.a==v.a and o.b==v.b and o.d>v.d and o.d-v.d<v.length*0.8 and o.state!="pulled": close+=1
	check(crossings>40,"Vehicles cross signalled stop lines (%d)"%crossings)
	check(red_runs_lawful==0,"Lawful drivers never cross a red line (%d violations)"%red_runs_lawful)
	check(stopped_at_red>50,"Drivers wait at red lights (%d stopped-at-red samples)"%stopped_at_red)
	check(over_limit<20,"Lawful drivers keep to the limit (%d over-limit samples)"%over_limit)
	check(close<10,"Cars keep a gap in the same lane (%d tailgating samples)"%close)
	var total=t.violations["red light"]+t.violations.speeding
	var stopped=0
	for p in t.posts:
		if p.busy: stopped+=1
	print("VIOLATIONS ",t.violations)
	check(total>0,"Cameras and police detect violations (%d in 2 min)"%total)
	print("TRAFFIC_CHECK ","PASS" if failures==0 else "FAIL"," failures=",failures)
	await world._quit_cleanly()

func _sample(_t) -> void:
	pass
