extends Node
## Procedural motion for the auto-rigged mecha (tools/rig_character.py bones: hips, spine, chest, neck,
## head, upper_arm/forearm/hand, thigh/shin/foot .L/.R). Heavy, deliberate gait: long stride, bent knees on
## the swing, counter-swinging arms, torso twist, a forward lean when boosting, and a servo idle (slow
## breathing, the head scanning the area) when standing. Parked frames idle by themselves when the player
## is near; a piloted frame is driven by OwnedVehicle through animate().
var skel: Skeleton3D
var ids: Dictionary={}
var rest: Dictionary={}
var phase: float=0.0
var gait: float=0.0
var boost_w: float=0.0
var turn_w: float=0.0
var clock: float=0.0
var auto_idle: bool=false        # parked in the hangar: idle on its own
var world

const BONES=["hips","spine","chest","neck","head","upper_arm.L","upper_arm.R","forearm.L","forearm.R","thigh.L","thigh.R","shin.L","shin.R","foot.L","foot.R"]
const STRIDE=7.0                 # metres per full walk cycle at 10 m tall

static func attach(model: Node3D,owner_world,parked: bool) -> Node:
	var found=model.find_children("*","Skeleton3D",true,false)
	if found.is_empty(): return null
	var rig=load("res://scripts/mecha_rig.gd").new()
	rig.name="MechaRig"
	rig.world=owner_world
	rig.auto_idle=parked
	rig.skel=found[0]
	rig.clock=randf()*10.0
	model.add_child(rig)
	rig._bind()
	return rig

func _bind() -> void:
	for n in BONES:
		var i=skel.find_bone(n)
		if i<0: i=skel.find_bone(n.replace(".","_"))
		if i>=0:
			ids[n]=i
			rest[n]=skel.get_bone_rest(i).basis.get_rotation_quaternion()

func _rot(n: String,axis: Vector3,angle: float) -> void:
	if not ids.has(n): return
	skel.set_bone_pose_rotation(ids[n],rest[n]*Quaternion(axis,angle))

func _process(delta: float) -> void:
	if not auto_idle or skel==null: return
	# Parked frames only bother animating when someone could see them.
	if world and world.player and skel.global_position.distance_to(world.player.global_position)>80.0: return
	animate(delta,0.0,0.0,false)

func animate(delta: float,speed: float,steer: float,boosting: bool) -> void:
	if skel==null: return
	clock+=delta
	var moving=clampf(absf(speed)/2.5,0.0,1.0)
	gait=lerpf(gait,moving,1.0-exp(-5.0*delta))
	boost_w=lerpf(boost_w,1.0 if boosting and moving>0.3 else 0.0,1.0-exp(-4.0*delta))
	turn_w=lerpf(turn_w,steer,1.0-exp(-3.0*delta))
	var stride=STRIDE*(1.0+0.35*boost_w)
	phase=fposmod(phase+signf(speed)*absf(speed)*delta/stride*TAU,TAU)
	var s=sin(phase)
	var c=cos(phase)
	# Legs: long swing, knees bend on the forward swing (never backwards), feet stay roughly level.
	var leg=lerpf(0.34,0.5,boost_w)*gait
	_rot("thigh.L",Vector3.RIGHT,s*leg-0.06*gait)
	_rot("thigh.R",Vector3.RIGHT,-s*leg-0.06*gait)
	_rot("shin.L",Vector3.RIGHT,-maxf(0.0,-c)*leg*1.4-0.08*gait)
	_rot("shin.R",Vector3.RIGHT,-maxf(0.0,c)*leg*1.4-0.08*gait)
	_rot("foot.L",Vector3.RIGHT,-s*leg*0.4)
	_rot("foot.R",Vector3.RIGHT,s*leg*0.4)
	# Arms counter-swing, elbows slightly bent; heavier and slower than a person's.
	var arm=lerpf(0.22,0.32,boost_w)*gait
	var breathe=sin(clock*1.1)
	_rot("upper_arm.L",Vector3.RIGHT,-s*arm+0.03*breathe*(1.0-gait))
	_rot("upper_arm.R",Vector3.RIGHT,s*arm+0.03*breathe*(1.0-gait))
	_rot("forearm.L",Vector3.RIGHT,-0.18*gait-0.35*boost_w-0.05)
	_rot("forearm.R",Vector3.RIGHT,-0.18*gait-0.35*boost_w-0.05)
	# Hips sway with each step; chest twists against the legs and leads into turns.
	_rot("hips",Vector3.UP,s*0.07*gait)
	_rot("chest",Vector3.UP,-s*0.09*gait+turn_w*0.18)
	# Lean into a boost; slow servo breathing when standing.
	_rot("spine",Vector3.RIGHT,boost_w*0.22+gait*0.04+breathe*0.012*(1.0-gait))
	# Head: steady while walking, scans the area when idle.
	var scan=(sin(clock*0.35)*0.35+sin(clock*0.9)*0.06)*(1.0-gait)
	_rot("head",Vector3.UP,scan+turn_w*0.25)
	_rot("neck",Vector3.RIGHT,-boost_w*0.12)
