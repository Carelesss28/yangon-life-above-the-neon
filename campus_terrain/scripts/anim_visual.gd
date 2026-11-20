extends "res://scripts/student_visual.gd"
## The player's animated character (Tripo export with its own skeleton and clips: walk, run,
## run_upstairs, swim, sit, heart_pose). Plays the clip that matches the movement, keeps clips in
## place (no root drift), and strikes the heart pose after standing still for a while.
const MODEL_PATH="res://models/characters/student_animated.glb"
const HEIGHT=1.65
var model: Node3D
var anim: AnimationPlayer
var current: String=""
var idle_clock=0.0
var posing=false

static func available() -> bool:
	return ResourceLoader.exists(MODEL_PATH)

func _ready() -> void:
	model=(load(MODEL_PATH) as PackedScene).instantiate() as Node3D
	add_child(model)
	# Normalise height, put the feet on the ground, and face the visual's forward (-Z).
	# Measured: this export faces 90 degrees off the other models (feet point sideways at PI),
	# so it needs PI + PI/2 to face the visual's forward (-Z). Rotate first, then centre.
	model.rotation.y=PI+PI/2
	var b: AABB=_bounds(model)
	var s=HEIGHT/maxf(b.size.y,0.01)
	model.scale=Vector3.ONE*s
	b=_bounds(model)
	model.position=Vector3(-b.get_center().x,-b.position.y,-b.get_center().z)
	var players=model.find_children("*","AnimationPlayer",true,false)
	if players.is_empty(): return
	anim=players[0]
	for name in anim.get_animation_list():
		var a: Animation=anim.get_animation(name).duplicate(true)
		if name in ["walk","run","swim","run_upstairs"]: a.loop_mode=Animation.LOOP_LINEAR
		_strip_root_motion(a)
		var lib: AnimationLibrary=anim.get_animation_library(anim.find_animation_library(anim.get_animation(name)))
		lib.add_animation(name,a)
	anim.playback_default_blend_time=0.2
	_play("walk",0.0)

func _bounds(node: Node3D) -> AABB:
	var out=AABB()
	var first=true
	for mi in node.find_children("*","MeshInstance3D",true,false):
		var box: AABB=mi.global_transform*mi.get_aabb() if mi.is_inside_tree() else (node.transform.affine_inverse()*_chain(mi))*mi.get_aabb()
		out=box if first else out.merge(box)
		first=false
	return out

func _chain(n: Node3D) -> Transform3D:
	var t=Transform3D()
	var cur: Node=n
	while cur and cur!=self:
		if cur is Node3D: t=cur.transform*t
		cur=cur.get_parent()
	return t

func _strip_root_motion(a: Animation) -> void:
	# The game moves the body; the hips keep their bob but lose forward / sideways travel.
	for t in range(a.get_track_count()):
		if a.track_get_type(t)!=Animation.TYPE_POSITION_3D: continue
		if not str(a.track_get_path(t)).ends_with("Hips"): continue
		if a.track_get_key_count(t)==0: continue
		var first: Vector3=a.track_get_key_value(t,0)
		for k in range(a.track_get_key_count(t)):
			var v: Vector3=a.track_get_key_value(t,k)
			a.track_set_key_value(t,k,Vector3(first.x,v.y,first.z))

func _play(name: String,speed: float) -> void:
	if anim==null or not anim.has_animation(name): return
	if current!=name:
		anim.play(name)
		current=name
	anim.speed_scale=speed

func reset_pose() -> void:
	gait_weight=0.0
	# Seated on rides and lifts.
	_play("sit",1.0)

func animate(delta: float, distance: float, speed: float, jogging: bool, grounded: bool) -> void:
	if anim==null: return
	var moving=speed>0.4 and grounded
	gait_weight=lerpf(gait_weight,1.0 if moving else 0.0,1.0-exp(-10.0*delta))
	if moving:
		idle_clock=0.0
		posing=false
		if jogging or speed>3.6:
			_play("run",clampf(speed/5.6,0.6,1.6))
		else:
			_play("walk",clampf(speed/2.15,0.5,1.6))
		return
	idle_clock+=delta
	if idle_clock>8.0 and not posing:
		posing=true
		_play("heart_pose",1.0)
	elif not posing:
		# Standing: hold the first frame of the walk (feet together).
		if current!="walk": _play("walk",0.0)
		anim.speed_scale=0.0
		anim.seek(0.0,true)
