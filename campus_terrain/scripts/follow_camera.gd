extends Camera3D

const DEFAULT_OFFSET := Vector3(7,28,30.2)   # ~42 m away at ~42 degrees: facades read like a diorama
const MIN_PITCH := deg_to_rad(20.0)
const MAX_PITCH := deg_to_rad(82.0)
const DRAG_SENSITIVITY := 0.005
const KEY_STEP := deg_to_rad(7.5)
const MIN_ZOOM := 0.28
const MAX_ZOOM := 1.8

var target: Node3D
var overview: bool = false
var zoom: float = 1.0
var instant: bool = true
var masterplan: bool = false
var yaw := atan2(DEFAULT_OFFSET.x,DEFAULT_OFFSET.z)
var pitch := atan2(DEFAULT_OFFSET.y,Vector2(DEFAULT_OFFSET.x,DEFAULT_OFFSET.z).length())
var dragging := false
var obstruction_distance := INF
var obstruction_direction := Vector3.ZERO
var obstruction_focus := Vector3.INF
var follow_distance := DEFAULT_OFFSET.length()
var follow_focus := Vector3.INF

func _ready() -> void:
	current = true
	fov = 34.0
	near = 0.65
	far = 4200

func _orbit_direction() -> Vector3:
	var horizontal := cos(pitch)
	return Vector3(sin(yaw)*horizontal,sin(pitch),cos(yaw)*horizontal)

func _physics_process(_delta: float) -> void:
	if not is_processing() or not is_instance_valid(target) or masterplan or overview:
		obstruction_distance=INF
		return
	var target_focus := target.global_position+Vector3.UP*0.8
	var focus := target_focus if instant or not follow_focus.is_finite() else follow_focus
	var direction := _orbit_direction()
	# Shorten the boom when the camera would sit inside a building or hillside.
	var end := focus+direction*(DEFAULT_OFFSET.length()*zoom+0.75)
	var query := PhysicsRayQueryParameters3D.create(focus,end)
	if target is CollisionObject3D: query.exclude=[target.get_rid()]
	var obstruction := get_world_3d().direct_space_state.intersect_ray(query)
	obstruction_focus=focus
	obstruction_direction=direction
	obstruction_distance=INF if obstruction.is_empty() else maxf(0.85,focus.distance_to(obstruction.position)-0.7)

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	if masterplan:
		projection=Camera3D.PROJECTION_ORTHOGONAL
		size=1100
		near=5.0
		global_position=Vector3(500,1500,1180)
		look_at(Vector3(500,0,505),Vector3.UP)
		return
	projection=Camera3D.PROJECTION_PERSPECTIVE
	if overview:
		near=5.0
		global_position=Vector3(500,1250,1560)
		look_at(Vector3(500,0,560),Vector3.UP)
		return
	near=0.65
	var target_focus := target.global_position+Vector3.UP*0.8
	var direction := _orbit_direction()
	var desired_distance := DEFAULT_OFFSET.length()*zoom
	var limit := INF
	var blend := 1.0-exp(-10.0*delta)
	follow_focus=target_focus if instant or not follow_focus.is_finite() else follow_focus.lerp(target_focus,blend)
	if follow_focus.distance_squared_to(obstruction_focus)<4.0 and direction.dot(obstruction_direction)>0.998:
		limit=obstruction_distance
	var ideal_distance := minf(desired_distance,limit)
	follow_distance=ideal_distance if instant else minf(limit,lerpf(follow_distance,ideal_distance,blend))
	global_position=follow_focus+direction*follow_distance
	look_at(follow_focus,Vector3.UP)
	instant = false

func reset_orbit() -> void:
	yaw=atan2(DEFAULT_OFFSET.x,DEFAULT_OFFSET.z)
	pitch=atan2(DEFAULT_OFFSET.y,Vector2(DEFAULT_OFFSET.x,DEFAULT_OFFSET.z).length())
	zoom=1.0
	instant=true

func zoom_by(amount: float) -> void:
	zoom=clampf(zoom+amount,MIN_ZOOM,MAX_ZOOM)

func _adjust_orbit(yaw_delta: float,pitch_delta: float) -> void:
	yaw=wrapf(yaw+yaw_delta,-PI,PI)
	pitch=clampf(pitch+pitch_delta,MIN_PITCH,MAX_PITCH)

func _unhandled_input(event: InputEvent) -> void:
	if overview or masterplan:
		dragging=false
		return
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_RIGHT:
			dragging=event.pressed
		elif event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_UP:
			# Touchpads send small fractional wheel steps (factor); mice send 1.0.
			zoom_by(-0.12*(event.factor if event.factor>0.0 else 1.0))
		elif event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_DOWN:
			zoom_by(0.12*(event.factor if event.factor>0.0 else 1.0))
		else:
			return
		get_viewport().set_input_as_handled()
	# Touchpad: pinch to zoom, two-finger swipe up/down to zoom (where the OS sends gestures).
	if event is InputEventMagnifyGesture:
		zoom=clampf(zoom/maxf(event.factor,0.01),MIN_ZOOM,MAX_ZOOM)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventPanGesture:
		zoom_by(event.delta.y*0.04)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and dragging:
		if not (event.button_mask & MOUSE_BUTTON_MASK_RIGHT):
			dragging=false
			return
		_adjust_orbit(-event.screen_relative.x*DRAG_SENSITIVITY,event.screen_relative.y*DRAG_SENSITIVITY)
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed:
		match event.physical_keycode:
			KEY_J: _adjust_orbit(-KEY_STEP,0)
			KEY_L: _adjust_orbit(KEY_STEP,0)
			KEY_I: _adjust_orbit(0,KEY_STEP)
			KEY_K: _adjust_orbit(0,-KEY_STEP)
			KEY_HOME: reset_orbit()
			KEY_EQUAL,KEY_KP_ADD,KEY_PAGEUP: zoom_by(-0.15)
			KEY_MINUS,KEY_KP_SUBTRACT,KEY_PAGEDOWN: zoom_by(0.15)
			_: return
		get_viewport().set_input_as_handled()

