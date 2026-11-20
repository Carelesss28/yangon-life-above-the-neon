extends "res://scripts/student_visual.gd"
## The player's character model (user-supplied, auto-rigged by tools/rig_character.py), animated
## procedurally: leg and knee swing, arm swing, a little torso counter-rotation, idle breathing.
## Same interface as the procedural student (animate / reset_pose / gait_weight).
const MODEL_PATH="res://models/characters/pilot_rigged.glb"
var skel: Skeleton3D
var ids: Dictionary={}
var rest: Dictionary={}
var model: Node3D

static func available() -> bool:
	return ResourceLoader.exists(MODEL_PATH)

func _ready() -> void:
	model=(load(MODEL_PATH) as PackedScene).instantiate() as Node3D
	model.rotation.y=PI      # the model faces +Z; the visual's forward is -Z
	add_child(model)
	var found=model.find_children("*","Skeleton3D",true,false)
	if found.is_empty(): return
	skel=found[0]
	for n in ["hips","spine","chest","neck","head","upper_arm.L","upper_arm.R","forearm.L","forearm.R","thigh.L","thigh.R","shin.L","shin.R","foot.L","foot.R"]:
		var i=skel.find_bone(n)
		if i<0: i=skel.find_bone(n.replace(".","_"))
		if i>=0:
			ids[n]=i
			rest[n]=skel.get_bone_rest(i).basis.get_rotation_quaternion()
	reset_pose()

func reset_pose() -> void:
	gait_weight=0.0
	run_weight=0.0
	if skel==null: return
	for n in ids: skel.set_bone_pose_rotation(ids[n],rest[n])

func _rot(n: String,axis: Vector3,angle: float) -> void:
	if not ids.has(n): return
	skel.set_bone_pose_rotation(ids[n],rest[n]*Quaternion(axis,angle))

func animate(delta: float, distance: float, speed: float, jogging: bool, grounded: bool) -> void:
	if skel==null: return
	var moving=clampf(speed/2.0,0.0,1.0) if grounded else 0.0
	gait_weight=lerpf(gait_weight,moving,1.0-exp(-10.0*delta))
	run_weight=lerpf(run_weight,1.0 if jogging and moving>0.5 else 0.0,1.0-exp(-6.0*delta))
	var stride=lerpf(WALK_STRIDE,RUN_STRIDE,run_weight)
	gait_phase=fposmod(gait_phase+distance/stride*TAU,TAU)
	idle_time+=delta
	var s=sin(gait_phase)
	var amp=lerpf(0.5,0.85,run_weight)*gait_weight
	_rot("thigh.L",Vector3.RIGHT,s*amp)
	_rot("thigh.R",Vector3.RIGHT,-s*amp)
	# Knees bend on the swing-through, never backwards.
	_rot("shin.L",Vector3.RIGHT,-maxf(0.0,-cos(gait_phase))*amp*1.3)
	_rot("shin.R",Vector3.RIGHT,-maxf(0.0,cos(gait_phase))*amp*1.3)
	var arm=lerpf(0.35,0.7,run_weight)*gait_weight
	_rot("upper_arm.L",Vector3.RIGHT,-s*arm)
	_rot("upper_arm.R",Vector3.RIGHT,s*arm)
	_rot("forearm.L",Vector3.RIGHT,-0.25*gait_weight-run_weight*0.6)
	_rot("forearm.R",Vector3.RIGHT,-0.25*gait_weight-run_weight*0.6)
	_rot("chest",Vector3.UP,s*0.08*gait_weight)
	# Idle breathing when standing still.
	_rot("spine",Vector3.RIGHT,sin(idle_time*1.6)*0.015*(1.0-gait_weight)+run_weight*0.12)
	model.position.y=absf(sin(gait_phase))*0.03*gait_weight
