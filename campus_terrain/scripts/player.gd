extends CharacterBody3D

const StudentVisual = preload("res://scripts/student_visual.gd")

var walk_speed: float = 2.15
var run_speed: float = 5.6
var test_mode: bool = false
var test_direction: Vector3 = Vector3.ZERO
var test_speed: float = 6.0
var paused: bool = false
var interior_mode: bool = false
var transit_mode: bool = false
## Click-to-move steering (set by click_move.gd); keyboard input always takes priority.
var auto_direction: Vector3 = Vector3.ZERO
var auto_run: bool = false
var camera: Camera3D
var visual: StudentVisual
var last_safe: Vector3 = Vector3(693.66,6.2,646)

func _ready() -> void:
	floor_snap_length = 0.5
	collision_mask = 1 | 2   # world and people
	floor_max_angle = deg_to_rad(48)
	floor_stop_on_slope = true
	floor_constant_speed = true
	var collider = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.7
	collider.shape = capsule
	collider.position.y = 0.85
	add_child(collider)
	# The user's character model when it is installed; the procedural student otherwise.
	var AnimVisual = load("res://scripts/anim_visual.gd")
	var ModelVisual = load("res://scripts/model_visual.gd")
	if AnimVisual.available(): visual = AnimVisual.new()
	elif ModelVisual.available(): visual = ModelVisual.new()
	else: visual = StudentVisual.new()
	visual.name = "StudentVisual"
	add_child(visual)

func _physics_process(delta: float) -> void:
	if paused:
		return
	if transit_mode:
		if visual.gait_weight > 0.0:
			visual.reset_pose()
		return
	var direction = test_direction if test_mode else _input_direction()
	var clicked := false
	if not test_mode and direction.length_squared() < 0.01 and auto_direction.length_squared() > 0.01:
		direction = auto_direction
		clicked = true
	var jogging := test_speed > walk_speed + 0.4 if test_mode else (Input.is_physical_key_pressed(KEY_SHIFT) or (clicked and auto_run))
	var speed := test_speed if test_mode else (run_speed if jogging else walk_speed)
	var acceleration := 36.0 if test_mode else (16.0 if direction.length_squared() > 0.01 else 24.0)
	var flat_velocity := Vector2(velocity.x, velocity.z).move_toward(Vector2(direction.x, direction.z) * speed, acceleration * delta)
	velocity.x = flat_velocity.x
	velocity.z = flat_velocity.y
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = -0.2
	move_and_slide()
	var travel := get_position_delta()
	var distance := Vector2(travel.x, travel.z).length()
	if distance > 0.003:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-travel.x, -travel.z), 1.0 - exp(-17.0 * delta))
	visual.animate(delta, distance, distance / maxf(delta, 0.0001), jogging, is_on_floor())
	if not interior_mode and (global_position.y < -25 or not preload("res://scripts/terrain_layout.gd").in_world(global_position.x,global_position.z)):
		teleport(last_safe)

func _input_direction() -> Vector3:
	var x = float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	var z = float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	if camera == null:
		return Vector3(x, 0, z).normalized()
	var right = camera.global_basis.x
	var back = camera.global_basis.z
	right.y = 0
	back.y = 0
	return (right.normalized() * x + back.normalized() * z).normalized()

func teleport(at: Vector3) -> void:
	global_position = at
	velocity = Vector3.ZERO
	last_safe = at
	if is_instance_valid(visual):
		visual.reset_pose()
