extends Node3D
const Layout=preload("res://scripts/terrain_layout.gd")
var world
var creatures: Array=[]
var models={}
var random=RandomNumberGenerator.new()
var clock=0.0
var counts={"cat":0,"bird":0,"duck":0,"butterfly":0}

func _ready() -> void:
	name="AmbientWildlife"
	random.seed=18112026
	for kind in counts: models[kind]=load("res://models/wildlife/%s.glb" % kind)
	for at in [Vector2(139,174),Vector2(140,465),Vector2(420,200),Vector2(280,-400),Vector2(210,672)]: _spawn("cat",at,1.0)
	for at in [Vector2(92,165),Vector2(60,490),Vector2(105,-390),Vector2(485,500)]:
		for i in range(3): _spawn("bird",at+Vector2(random.randf_range(-3,3),random.randf_range(-3,3)),1.0)
	for i in range(6): _spawn("duck",Vector2(550+random.randf_range(-12,12),548+random.randf_range(-10,10)),0.65 if i>1 else 1.0)
	for at in [Vector2(110,175),Vector2(142,252),Vector2(165,-40),Vector2(143,470)]:
		for i in range(4): _spawn("butterfly",at+Vector2(random.randf_range(-3,3),random.randf_range(-3,3)),1.0)
	print("WILDLIFE_READY ",counts)

func _spawn(kind: String,at: Vector2,size: float) -> void:
	var model=models[kind].instantiate() as Node3D
	model.name="Ambient_%s_%d" % [kind,counts[kind]]
	model.scale=Vector3.ONE*size
	add_child(model)
	var c={"kind":kind,"model":model,"home":at,"point":at,"goal":at,"timer":random.randf_range(1,6),"phase":random.randf()*TAU,"moving":false,"height":0.0,"wings":[],"legs":[]}
	for pattern in ["WingLeft","WingRight"]:
		var part=model.find_child(pattern,true,false)
		if part: c.wings.append(part)
	for part in model.find_children("Leg_*","Node3D",true,false): c.legs.append(part)
	c.tail=model.find_child("Tail",true,false)
	c.head=model.find_child("Head",true,false)
	creatures.append(c)
	counts[kind]+=1
	_position(c,0)

func _safe(at: Vector2,previous: Vector2) -> bool:
	if not Layout.in_world(at.x,at.y) or not Layout.Roads.sample(at.x,at.y).is_empty(): return false
	if Layout.wet(at.x,at.y) or not Layout.channel_sample(at.x,at.y).is_empty(): return false
	if at.y>=614 and at.y>Layout.river_north_bank(at.x)-2: return false
	return absf(Layout.base_height_at(at.x,at.y)-Layout.base_height_at(previous.x,previous.y))<0.2

func _process(delta: float) -> void:
	clock+=delta
	for c in creatures:
		if world.player and Vector2(world.player.position.x,world.player.position.z).distance_to(c.point)>160:
			c.model.visible=false
			continue
		c.model.visible=not (world.night and c.kind=="butterfly")
		if world.night and c.kind in ["bird","butterfly"]:
			c.goal=c.point
			c.height=move_toward(c.height,0,delta*1.4)
			c.moving=false
			_position(c,delta)
			continue
		c.timer-=delta
		var scared=c.kind=="bird" and c.height<0.1 and world.player and Vector2(world.player.position.x,world.player.position.z).distance_to(c.point)<3.5
		if c.timer<=0 or scared:
			var angle=random.randf()*TAU
			var radius=random.randf_range(1,4) if c.kind!="duck" else random.randf_range(2,12)
			var next=c.home+Vector2(cos(angle),sin(angle))*radius
			if c.kind in ["duck","butterfly"] or _safe(next,c.point): c.goal=next
			c.timer=random.randf_range(4,10)
			if scared: c.height=2.5;c.timer=3.0
		var speed={"cat":0.55,"bird":0.40,"duck":0.34,"butterfly":0.55}[c.kind]
		if c.kind=="bird" and c.height>0.1: speed=1.8
		var direction=c.goal-c.point
		c.moving=direction.length()>0.15
		if c.moving:
			var next=c.point.move_toward(c.goal,speed*delta)
			if c.kind in ["duck","butterfly"] or _safe(next,c.point): c.point=next
			else: c.goal=c.point
			c.model.rotation.y=lerp_angle(c.model.rotation.y,atan2(direction.x,direction.y),delta*5)
		_position(c,delta)

func _position(c: Dictionary,delta: float) -> void:
	var y=Layout.base_height_at(c.point.x,c.point.y)
	if c.kind=="duck": y=-2.39+0.025*sin(clock*1.5+c.phase)
	elif c.kind=="butterfly": y+=0.75+0.35*sin(clock*1.3+c.phase)
	elif c.kind=="bird":
		if c.timer<1.5: c.height=move_toward(c.height,0,delta*1.4)
		y+=c.height+(absf(sin(clock*7+c.phase))*0.07 if c.moving and c.height<0.1 else 0)
	c.model.position=Vector3(c.point.x,y+0.03,c.point.y)
	var flap=sin(clock*(18 if c.kind=="butterfly" else 12)+c.phase)
	for i in range(c.wings.size()):
		c.wings[i].rotation.z=(1 if i==0 else -1)*flap*(0.8 if c.kind=="butterfly" else (0.65 if c.height>0.1 else 0.03))
	for i in range(c.legs.size()): c.legs[i].rotation.x=sin(clock*7+[0.0,PI,PI,0.0][i%4])*0.35 if c.moving else 0
	if c.tail: c.tail.rotation.y=sin(clock*1.1+c.phase)*0.3
	if c.head: c.head.rotation.y=sin(clock*0.65+c.phase)*0.12
