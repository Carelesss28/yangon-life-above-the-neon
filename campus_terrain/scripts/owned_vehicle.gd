extends CharacterBody3D
## A vehicle the player owns (or the training mecha). Arcade handling: W/S throttle and brake/reverse,
## A/D steer, Space/X climb/descend for the flying car. C gets in and out. Wheels roll over kerbs.
var kind: String="car"          # car, bike, bicycle, hover, mecha
var id: String=""
var title: String=""
var max_speed: float=16.0
var accel: float=6.0
var steer_rate: float=1.6
var speed: float=0.0
var heading: float=0.0
var driving: bool=false
var world
var bounds: Rect2=Rect2()      # optional area limit (training mecha stays on the training grounds)
var hover_height: float=0.0
var model: Node3D
var walk_phase: float=0.0

func setup(owner_world,vehicle_kind: String,vehicle_id: String,vehicle_title: String,visual: Node3D) -> void:
	world=owner_world
	kind=vehicle_kind
	id=vehicle_id
	title=vehicle_title
	model=visual
	add_child(visual)
	match kind:
		"bicycle": max_speed=7.0; accel=3.0; steer_rate=2.2
		"bike": max_speed=17.0; accel=7.0; steer_rate=2.0
		"hover": max_speed=22.0; accel=6.0; steer_rate=1.6
		"mecha": max_speed=4.5; accel=2.0; steer_rate=1.0
		_: max_speed=16.0; accel=5.5; steer_rate=1.5
	floor_snap_length=0.6
	add_collision_exception_with(world.player) if world.player else null
	floor_max_angle=deg_to_rad(40)
	var wheel=CollisionShape3D.new()
	var sphere=SphereShape3D.new()
	sphere.radius=0.45
	wheel.shape=sphere
	wheel.position=Vector3(0,0.45,0)
	add_child(wheel)
	var body=CollisionShape3D.new()
	var box=BoxShape3D.new()
	var size={"car":Vector3(1.8,1.0,4.4),"bike":Vector3(0.7,1.0,2.0),"bicycle":Vector3(0.6,0.9,1.7),"hover":Vector3(2.0,0.8,4.4),"mecha":Vector3(4.0,7.5,2.6)}.get(kind,Vector3(1.8,1.0,4.4))
	box.size=size
	body.shape=box
	body.position=Vector3(0,0.95+size.y*0.5,0)
	add_child(body)
	var tag=Label3D.new()
	tag.name="OwnedTag"
	tag.text=title+"  [C]"
	tag.font_size=32
	tag.pixel_size=0.01
	tag.position=Vector3(0,2.6 if kind!="mecha" else 11.0,0)
	tag.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate=Color("bff4ff")
	tag.outline_size=5
	tag.outline_modulate=Color("102030")
	tag.no_depth_test=true
	add_child(tag)

func _physics_process(delta: float) -> void:
	var throttle=0.0
	var steer=0.0
	var lift=0.0
	if driving and not world.player.paused:
		throttle=float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))-float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))
		steer=float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))-float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))
		lift=float(Input.is_physical_key_pressed(KEY_SPACE))-float(Input.is_physical_key_pressed(KEY_X))
	var top=max_speed
	if kind=="mecha" and driving and Input.is_physical_key_pressed(KEY_SPACE): top*=2.4   # boost dash
	var target=throttle*top*(1.0 if throttle>=0 else 0.4)
	var rate=accel if absf(target)>absf(speed) else accel*1.8
	speed=move_toward(speed,target,rate*delta)
	if throttle==0.0: speed=move_toward(speed,0.0,accel*0.6*delta)
	heading+=steer*steer_rate*delta*clampf(absf(speed)/3.0,0.0,1.0)*signf(speed if speed!=0 else 1.0)
	rotation.y=heading
	var forward=Vector3(-sin(heading),0,-cos(heading))
	velocity.x=forward.x*speed
	velocity.z=forward.z*speed
	if kind=="hover" and (hover_height>0.5 or lift>0.0):
		hover_height=clampf(hover_height+lift*6.0*delta,0.0,60.0)
		var ground=world.Layout.height_at(global_position.x,global_position.z) if world.Layout.in_world(global_position.x,global_position.z) else 0.0
		velocity.y=((maxf(ground,world.Layout.SEA_Y)+hover_height)-global_position.y)*4.0
	elif is_on_floor():
		velocity.y=-0.5
	else:
		velocity.y-=18.0*delta
	move_and_slide()
	if is_on_wall() and absf(speed)>3.0: speed*=0.5
	if bounds.size.x>0.0 and not bounds.has_point(Vector2(global_position.x,global_position.z)):
		var c=bounds.get_center()
		global_position+=Vector3(c.x-global_position.x,0,c.y-global_position.z).normalized()*0.6
		speed=0.0
	if kind=="mecha" and model:
		var rig=model.find_child("MechaRig",true,false)
		if rig:
			# Rigged frame: legs, arms and torso animate; the body dips at each footfall.
			rig.animate(delta,speed,steer if driving else 0.0,driving and Input.is_physical_key_pressed(KEY_SPACE))
			model.position.y=-absf(sin(rig.phase))*0.18*rig.gait
			model.rotation.z=sin(rig.phase)*0.015*rig.gait
		else:
			# Unrigged frame (training frame): heavy stride bob while walking.
			walk_phase+=absf(speed)*delta*1.2
			model.position.y=absf(sin(walk_phase))*0.25*clampf(absf(speed)/2.0,0,1)
			model.rotation.z=sin(walk_phase)*0.035*clampf(absf(speed)/2.0,0,1)
	if driving:
		world.player.global_position=global_position+Vector3.UP*0.2
		get_node("OwnedTag").visible=false
	else:
		get_node("OwnedTag").visible=global_position.distance_to(world.player.global_position)<14.0
