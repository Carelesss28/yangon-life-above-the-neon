extends RefCounted
## Building functions: every non-residential building offers at least one activity (most offer 2-3):
## work shifts, shopping for gift items, eating, studying, classes, training, rest, play, outfits.
## Used while inside a building: press Q. Actions cost kyat and/or game time and change stats.
const Data=preload("res://scripts/npc_data.gd")
const RESIDENTIAL=["APARTMENT","DORM","HOSTEL","FAMILY HOME"]
var sys
var outfits=["387f87","c0505a","2f6f9a","6aa060","8a6fb5","e2574c","2a2a30","f2c94c"]

# Each rule: [keywords, [actions...]]; the first rule whose keyword matches the title wins.
# Action: {"t": label, "k": kyat (negative = cost), "m": game minutes, "e": energy change,
#          "s": {stat: +n}, "item": gift id, "kind": optional special}
const RULES=[
 [["MECHA HANGAR"],[{"t":"Inspect the four frames","k":0,"m":30,"s":{"Engineering":1,"Study":1}},{"t":"Maintenance shift on the gantries (2 h)","k":3000,"m":120,"e":-16,"s":{"Engineering":3}},{"t":"Cockpit sync test (1 h)","k":0,"m":60,"e":-12,"s":{"Piloting":3}},{"t":"Return all frames to their bays","k":0,"m":5,"kind":"recall"}]],
 [["TRAINING FRAME"],[{"t":"Pilot the training frame (C to climb out)","k":0,"m":5,"kind":"pilot"}]],
 [["CABLE CAR · LOWER"],[{"t":"Ride the cable car up to the resort","k":-800,"kind":"ride","ride":"cable_up"},{"t":"Look at the view","k":0,"m":10,"s":{"Charm":1}}]],
 [["CABLE CAR · UPPER"],[{"t":"Ride the cable car down to the village","k":-800,"kind":"ride","ride":"cable_down"},{"t":"Look at the view","k":0,"m":10,"s":{"Charm":1}}]],
 [["ZIPLINE"],[{"t":"Ride the zipline over the reservoir","k":-1500,"e":-3,"kind":"ride","ride":"zip"}]],
 [["FERRIS WHEEL"],[{"t":"Ride the Ferris wheel","k":-1200,"kind":"ride","ride":"ferris","s":{"Charm":1}}]],
 [["FERRY TERMINAL"],[{"t":"Harbour ferry cruise","k":-1500,"kind":"ride","ride":"ferry","s":{"Charm":1}}]],
 [["BENCH"],[{"t":"Sit and rest a while","k":0,"m":20,"e":12},{"t":"Watch the world go by","k":0,"m":30,"e":8,"s":{"Charm":1}}]],
 [["BEACH"],[{"t":"Swim in the sea","k":0,"m":45,"e":-10,"s":{"Fitness":2}},{"t":"Sunbathe","k":0,"m":40,"e":20},{"t":"Collect sea shells","k":0,"m":30,"item":"shell"}]],
 [["HARBOUR CRANE"],[{"t":"Crane operator shift (2 h)","k":4000,"m":120,"e":-14,"s":{"Engineering":2}}]],
 [["PIER END"],[{"t":"Fish off the pier (1 h)","k":0,"m":60,"e":-4,"item":"fish"},{"t":"Watch the lighthouse sweep","k":0,"m":20,"e":6,"s":{"Charm":1}}]],
 [["MOTOR SERVICE GARAGE"],[{"t":"Mechanic shift (2 h)","k":3500,"m":120,"e":-15,"s":{"Engineering":2}},{"t":"Wash and charge your vehicle","k":-500,"m":20}]],
 [["TEST TRACK"],[{"t":"Rent a kart for ten laps","k":-2000,"m":30,"e":-6,"s":{"Fitness":1,"Piloting":1}}]],
 [["FIELD TRAINING"],[{"t":"Obstacle course (1 h)","k":0,"m":60,"e":-18,"s":{"Fitness":3,"Piloting":1}},{"t":"Frame walking drill (2 h)","k":0,"m":120,"e":-20,"s":{"Piloting":4}},{"t":"Target practice","k":0,"m":45,"e":-10,"s":{"Piloting":2}}]],
 [["SKY TERRACE RESORT"],[{"t":"Swim in the infinity pool","k":-3000,"m":60,"e":30,"s":{"Fitness":1}},{"t":"Sunset dinner on the terrace","k":-6000,"m":90,"e":40,"s":{"Charm":2}},{"t":"Stay the night","k":-12000,"kind":"sleep"}]],
 [["HOT SPRING"],[{"t":"Soak in the hot spring","k":-2500,"m":60,"e":60}]],
 [["CABLE CAR · LOWER"],[{"t":"Ride up to the resort","k":-800,"m":6,"kind":"travel","to":Vector3(105.63,0,912)},{"t":"Look at the view","k":0,"m":10,"s":{"Charm":1}}]],
 [["CABLE CAR · UPPER"],[{"t":"Ride down to the hill village","k":-800,"m":6,"kind":"travel","to":Vector3(80.99,0,652)},{"t":"Look at the view","k":0,"m":10,"s":{"Charm":1}}]],
 [["MEDITATION GARDEN"],[{"t":"Meditate (1 h)","k":0,"m":60,"e":25,"s":{"Charm":1}},{"t":"Light a lantern","k":-300,"m":10,"s":{"Charm":1}}]],
 [["HILL TEA PLANTATION"],[{"t":"Pick tea leaves (2 h)","k":2500,"m":120,"e":-15,"s":{"Fitness":1},"item":"tea_leaves"},{"t":"Learn tea processing","k":0,"m":60,"s":{"Study":1}}]],
 [["GOAT FARM"],[{"t":"Feed the goats","k":0,"m":30,"e":5,"s":{"Charm":1}},{"t":"Farm chores (1 h)","k":1800,"m":60,"e":-12,"s":{"Fitness":2}}]],
 [["HILLTOP CAMPGROUND"],[{"t":"Camp overnight","k":-1500,"kind":"sleep"},{"t":"Campfire with snacks","k":-800,"m":60,"e":20,"s":{"Charm":1}}]],
 [["STARGAZING"],[{"t":"Stargaze (1 h)","k":0,"m":60,"e":10,"s":{"Study":1,"Charm":1}}]],
 [["ZIPLINE"],[{"t":"Ride the zipline over the reservoir","k":-1500,"m":3,"e":-3,"kind":"travel","to":Vector3(98.59,0,709)}]],
 [["CIVIC DEFENCE"],[{"t":"Volunteer sensor watch (2 h)","k":2500,"m":120,"e":-12,"s":{"Piloting":1,"Study":1}},{"t":"Shelter drill","k":0,"m":30,"e":-5,"s":{"Fitness":1}}]],
 [["FAMILY HOME"],[{"t":"Help in the rooftop café (1 h)","k":2500,"m":60,"e":-10,"s":{"Charm":1}},{"t":"Sleep until morning","kind":"sleep"},{"t":"Family dinner","k":0,"m":45,"e":35,"s":{"Charm":1}}]],
 [["TEA"],[{"t":"Milk tea and fritters","k":-800,"m":20,"e":20},{"t":"Buy tea leaves to give","k":-1200,"m":5,"item":"tea_leaves"},{"t":"Work a tea-shop shift (1 h)","k":3000,"m":60,"e":-12,"s":{"Charm":1}}]],
 [["NOODLE","FOOD","SEAFOOD","BAKERY","COMMONS","STREET FOOD","UNION"],[{"t":"Eat a meal","k":-1500,"m":30,"e":35},{"t":"Buy a coconut to give","k":-900,"m":5,"item":"coconut"},{"t":"Kitchen shift (1 h)","k":2800,"m":60,"e":-14,"s":{"Fitness":1}}]],
 [["DATA CAFE","VR NET","SIM ARENA","SIMULATOR","ARCADE"],[{"t":"Mecha sim run","k":-1000,"m":45,"e":-6,"s":{"Piloting":2}},{"t":"Arcade games","k":-600,"m":30,"e":-4,"s":{"Charm":1}},{"t":"Buy a battery cell to give","k":-1500,"m":5,"item":"battery"}]],
 [["PILOT SCHOOL"],[{"t":"Attend piloting class (2 h)","k":0,"m":120,"e":-15,"s":{"Piloting":3,"Study":1}},{"t":"Sync drills (1 h)","k":0,"m":60,"e":-12,"s":{"Piloting":2,"Fitness":1}}]],
 [["CLASSROOM","RESEARCH","SCHOOL","CLUBS","ADMIN"],[{"t":"Attend class (2 h)","k":0,"m":120,"e":-12,"s":{"Study":3}},{"t":"Study group (1 h)","k":0,"m":60,"e":-8,"s":{"Study":1,"Charm":1}},{"t":"Collect weekly allowance","kind":"allowance"}]],
 [["LIBRARY","BOOKSHOP"],[{"t":"Study in the reading room (2 h)","k":0,"m":120,"e":-10,"s":{"Study":3}},{"t":"Borrow a frame manual","k":0,"m":30,"s":{"Engineering":1,"Study":1}},{"t":"Buy a book to give","k":-2000,"m":5,"item":"book"}]],
 [["HOSPITAL","CLINIC","CYBERNETICS","PHARMACY"],[{"t":"Health check-up","k":-1000,"m":40,"e":40},{"t":"Volunteer shift (2 h)","k":1500,"m":120,"e":-15,"s":{"Charm":2}}]],
 [["ENGINEERING","HANGAR","REPAIR","WORKSHOP","SHIPYARD","MARINE","MECHA","ROBOT","TECH / ROBOT"],[{"t":"Help with repairs (2 h)","k":3500,"m":120,"e":-18,"s":{"Engineering":3}},{"t":"Buy a spare servo to give","k":-2500,"m":5,"item":"servo"},{"t":"Buy copper wire to give","k":-900,"m":5,"item":"copper"}]],
 [["POLICE"],[{"t":"Volunteer community patrol (2 h)","k":2000,"m":120,"e":-14,"s":{"Fitness":2,"Charm":1}},{"t":"Report a lost item","k":0,"m":15,"s":{"Charm":1}}]],
 [["FIRE"],[{"t":"Fire-safety drill (1 h)","k":0,"m":60,"e":-16,"s":{"Fitness":3}},{"t":"Help wash the trucks (1 h)","k":2000,"m":60,"e":-12,"s":{"Fitness":1}}]],
 [["CITY HALL","OFFICE","BANK","CUSTOMS","DATA CENTRE","DATA TOWER","MEDIA","HARBOUR TOWER","TRADE","SKY TOWER","SHIPPING"],[{"t":"Part-time office job (3 h)","k":4500,"m":180,"e":-15,"s":{"Study":1}},{"t":"Register for the civic-defence cadet list","k":0,"m":20,"s":{"Piloting":1}}]],
 [["POST","DELIVERY","DRONE PORT","WAREHOUSE","DEPOT","COLD STORAGE","WHOLESALE"],[{"t":"Delivery job (2 h)","k":3500,"m":120,"e":-18,"s":{"Fitness":2}},{"t":"Send a parcel home","k":-500,"m":10}]],
 [["CHARGING","BATTERY"],[{"t":"Buy a battery cell to give","k":-1500,"m":5,"item":"battery"},{"t":"Charge your phone and rest","k":-200,"m":30,"e":15}]],
 [["HOTEL","CAPSULE"],[{"t":"Rent a capsule and nap","k":-3000,"m":120,"e":60},{"t":"Hotel café break","k":-1200,"m":30,"e":20}]],
 [["CINEMA","KARAOKE","HOLO","MUSIC","SYNTH"],[{"t":"Watch a film (2 h)","k":-2000,"m":120,"e":10,"s":{"Charm":1}},{"t":"Karaoke with friends (1 h)","k":-1500,"m":60,"e":-5,"s":{"Charm":2}}]],
 [["CLOTHING","TEXTILES","TAILOR","AUGMENT","DEPARTMENT","FASHION"],[{"t":"Buy a new jacket colour","k":-6000,"m":20,"kind":"outfit"},{"t":"Buy a gift scarf of jasmine print","k":-1500,"m":5,"item":"jasmine"}]],
 [["LAUNDRY"],[{"t":"Wash your uniform","k":-600,"m":45,"s":{"Charm":1}},{"t":"Fold laundry for tips (1 h)","k":1800,"m":60,"e":-8}]],
 [["FISH MARKET"],[{"t":"Buy fresh fish to give","k":-1200,"m":5,"item":"fish"},{"t":"Help unload the catch (1 h)","k":2500,"m":60,"e":-15,"s":{"Fitness":2}}]],
 [["SPICE"],[{"t":"Buy a spice parcel to give","k":-1000,"m":5,"item":"spices"},{"t":"Help grind spices (1 h)","k":2000,"m":60,"e":-10}]],
 [["GROCERY","CONVENIENCE","CORNER","SHOP","MART","MARKET","VENDING","CHANDLERY","PRODUCE"],[{"t":"Buy jasmine flowers to give","k":-700,"m":5,"item":"jasmine"},{"t":"Buy a young coconut to give","k":-900,"m":5,"item":"coconut"},{"t":"Snack and a drink","k":-600,"m":10,"e":12}]],
 [["COMMUNITY"],[{"t":"Community class (1 h)","k":0,"m":60,"s":{"Charm":1,"Study":1}},{"t":"Help at the event (1 h)","k":1500,"m":60,"e":-8,"s":{"Charm":2}}]],
]

func _init(owner) -> void:
	sys=owner

static func is_residential(title: String) -> bool:
	if "FAMILY HOME" in title: return false
	for k in RESIDENTIAL:
		if k in title: return true
	return false

func actions_for(title: String) -> Array:
	var g=sys.world.garage
	if g and ("SHOWROOM" in title):
		var shop="BIKE" if "BIKE" in title else "CAR"
		var out=[]
		for c in g.CATALOG:
			if c.shop!=shop: continue
			if g.owned.has(c.id): out.append({"t":"Call your %s to the lot" % c.name,"k":0,"m":2,"kind":"summon_lot","vid":c.id})
			else: out.append({"t":"Buy %s" % c.name,"k":-int(c.price),"m":20,"kind":"buy","vid":c.id})
		return out
	if title.begins_with("BAY 0"):
		var bay=int(title.substr(4,2))-1
		var nm=title.get_slice(" · ",1)
		return [{"t":"Climb in and pilot %s" % nm,"k":0,"m":2,"kind":"pilot_bay","bay":bay},{"t":"Check its systems","k":0,"m":20,"s":{"Engineering":1}}]
	return rule_actions(title)

static func rule_actions(title: String) -> Array:
	for rule in RULES:
		for k in rule[0]:
			if k in title: return rule[1]
	if is_residential(title):
		return [{"t":"Rest a while","k":0,"m":60,"e":30}]
	return []

func open(title: String) -> void:
	var acts=actions_for(title)
	sys.talking={"stopped":false,"activity":true,"data":{"id":"_building"}}
	sys.world.player.paused=true
	sys.panel.visible=true
	sys.name_label.text=title
	sys.level_label.text=_stats_line()
	sys.text_label.text="Pick something to do. %s K   ·   Energy %d" % [sys._commas(sys.kyat),int(sys.stats.Energy)]
	_options(title,acts)

func _options(title: String,acts: Array) -> void:
	for child in sys.options_box.get_children(): child.queue_free()
	for a in acts:
		var label: String=a.t
		var cost=int(a.get("k",0))
		if cost<0: label+="  (%s K)" % sys._commas(-cost)
		elif cost>0: label+="  (+%s K)" % sys._commas(cost)
		sys._option(label,_do.bind(title,a))
	sys._option("Leave",sys._close_dialogue)

func _do(title: String,a: Dictionary) -> void:
	var cost=int(a.get("k",0))
	var energy=float(a.get("e",0))
	if cost<0 and sys.kyat<-cost:
		sys.text_label.text="Not enough kyat for that."
		return
	if energy<0 and sys.stats.Energy+energy<0:
		sys.text_label.text="You're too tired. Eat something or rest first."
		return
	var kind=str(a.get("kind",""))
	if kind=="sleep":
		var to_morning=fposmod(7*60-sys.minutes,24*60)
		sys.minutes+=to_morning
		if sys.minutes>=24*60:
			sys.minutes-=24*60
			sys.day+=1
			sys._spawn_pickups()
		sys.stats.Energy=100.0
		for npc in sys.npcs: sys._settle(npc)
		sys.text_label.text="You sleep well. Good morning! Day %d, 07:00." % sys.day
		sys.dirty=true
		return
	if kind=="allowance":
		if int(sys.stats.get("allowance_week",0))==int((sys.day-1)/7)+1:
			sys.text_label.text="You already collected this week's allowance."
			return
		var amount=5000+int(sys.stats.Study)*150
		sys.kyat+=amount
		sys.stats.allowance_week=int((sys.day-1)/7)+1
		sys.text_label.text="Weekly allowance: +%s K (grows with your Study)." % sys._commas(amount)
		sys.dirty=true
		return
	if kind=="buy":
		if sys.kyat<-cost:
			sys.text_label.text="Not enough kyat. %s costs %s K; you have %s K." % [sys.world.garage.info(a.vid).name,sys._commas(-cost),sys._commas(sys.kyat)]
			return
		sys.kyat+=cost
		sys.world.garage.buy(a.vid)
		sys._close_dialogue()
		sys.show_toast("You bought a %s! It's on the delivery lot. Press C next to it to ride, G to call it anywhere." % sys.world.garage.info(a.vid).name)
		sys.dirty=true
		return
	if kind=="summon_lot":
		var v=sys.world.garage.owned[a.vid]
		var lot=sys.world.garage.LOT
		v.global_position=Vector3(lot.x,sys.Layout.height_at(lot.x,lot.y)+0.4,lot.y)
		sys.world.garage.last_used=a.vid
		sys.text_label.text="Your %s is waiting on the delivery lot." % sys.world.garage.info(a.vid).name
		return
	if kind=="pilot_bay":
		sys._close_dialogue()
		sys.world.garage.pilot_bay(int(a.bay))
		sys.stats.Piloting=int(sys.stats.Piloting)+1
		return
	if kind=="recall":
		sys.world.garage.recall_frames()
		sys.text_label.text="All frames are back in their bays."
		return
	if kind=="pilot":
		sys._close_dialogue()
		var hm=sys.world.hill
		sys.world.garage.pilot_mecha(hm.mecha_home,hm.training_bounds)
		sys.stats.Piloting=int(sys.stats.Piloting)+1
		return
	if kind=="ride":
		if sys.kyat<-cost:
			sys.text_label.text="Not enough kyat for the ride."
			return
		sys._close_dialogue()
		if sys.world.rides.start(a.ride):
			sys.kyat+=cost
			for st in a.get("s",{}): sys.stats[st]=int(sys.stats.get(st,0))+int(a.s[st])
			sys.dirty=true
		return
	if kind=="travel":
		var to: Vector3=a.to
		sys.kyat+=cost
		sys.minutes+=float(a.get("m",0))
		sys.stats.Energy=clampf(sys.stats.Energy+energy,0,100)
		sys._close_dialogue()
		var y=sys.Layout.height_at(to.x,to.z)+0.3
		sys.world.player.teleport(Vector3(to.x,y,to.z))
		sys.world.camera.instant=true
		sys.show_toast("Whee! %s" % a.t)
		sys.dirty=true
		return
	if kind=="outfit":
		sys.stats.outfit=(int(sys.stats.get("outfit",0))+1)%outfits.size()
		apply_outfit()
	sys.kyat+=cost
	sys.minutes+=float(a.get("m",0))
	if sys.minutes>=24*60:
		sys.minutes-=24*60
		sys.day+=1
		sys._spawn_pickups()
	sys.stats.Energy=clampf(sys.stats.Energy+energy,0,100)
	var gains=[]
	for st in a.get("s",{}):
		sys.stats[st]=int(sys.stats.get(st,0))+int(a.s[st])
		gains.append("%s +%d" % [st,int(a.s[st])])
	if a.has("item"):
		sys._give(a.item)
		gains.append("got "+Data.ITEMS[a.item])
	var money="" if cost==0 else ("  %+d K" % cost)
	sys.text_label.text="Done: %s.%s   %s\n%s K   ·   Energy %d" % [a.t,money,"  ".join(gains),sys._commas(sys.kyat),int(sys.stats.Energy)]
	sys.level_label.text=_stats_line()
	sys.dirty=true

func _stats_line() -> String:
	return "Study %d  ·  Piloting %d  ·  Engineering %d  ·  Fitness %d  ·  Charm %d" % [int(sys.stats.Study),int(sys.stats.Piloting),int(sys.stats.Engineering),int(sys.stats.Fitness),int(sys.stats.Charm)]

func apply_outfit() -> void:
	var p=sys.world.player
	if p==null or p.visual==null: return
	if p.visual.has_method("available"):
		# Rigged character model: a new jacket colour tints the outfit instead of swapping meshes.
		var tint=StandardMaterial3D.new()
		tint.albedo_color=Color(outfits[int(sys.stats.get("outfit",0))%outfits.size()],0.18)
		tint.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		tint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		for mi in p.visual.find_children("*","MeshInstance3D",true,false): mi.material_overlay=tint
		return
	var colour=outfits[int(sys.stats.get("outfit",0))%outfits.size()]
	var old=p.visual
	var fresh=preload("res://scripts/student_visual.gd").new()
	fresh.palette={"jacket":colour,"sleeve":Color(colour).darkened(0.12).to_html(false)}
	fresh.name="StudentVisual"
	p.add_child(fresh)
	fresh.rotation=old.rotation
	p.visual=fresh
	old.queue_free()
