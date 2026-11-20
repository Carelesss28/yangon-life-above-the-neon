extends Node3D
## Original articulated low-poly student. Local forward is -Z.
const THIGH_LENGTH := 0.43
const SHIN_LENGTH := 0.43
const ANKLE_HEIGHT := 0.095
const WALK_STRIDE := 1.28
const RUN_STRIDE := 2.55

var torso: Node3D
var legs: Array[Dictionary] = []
var arms: Array[Node3D] = []
var elbows: Array[Node3D] = []
var gait_phase := 0.0
var gait_weight := 0.0
var run_weight := 0.0
var idle_time := 0.0

func _ready() -> void:
	var jacket := _material("387f87")
	var sleeve := _material("326973")
	var piping := _material("96dcd3")
	var trousers := _material("33465f")
	var shoe := _material("263447")
	var sole := _material("9cabb3")
	var skin := _material("be885e")
	var hair := _material("26242c")
	var pack := _material("3b4c64")
	torso = _joint(self, Vector3(0, 0.87, 0))
	_taper(torso, Vector3(0, 0.04, 0), 0.158, 0.171, 0.24, 0.74, trousers)
	_taper(torso, Vector3(0, 0.307, 0), 0.224, 0.161, 0.46, 0.57, jacket)
	_box(torso, Vector3(0.035, 0.347, -0.113), Vector3(0.025, 0.3, 0.021), piping)
	_taper(torso, Vector3(0, 0.573, 0), 0.066, 0.086, 0.115, 0.94, skin)
	_round_piece(torso, Vector3(0, 0.705, -0.017), Vector3(0.26, 0.31, 0.25), skin)
	_round_piece(torso, Vector3(0, 0.781, 0.003), Vector3(0.269, 0.19, 0.256), hair)
	_round_piece(torso, Vector3(-0.053, 0.757, -0.083), Vector3(0.16, 0.11, 0.13), hair)
	_box(torso, Vector3(0, 0.339, 0.166), Vector3(0.29, 0.33, 0.16), pack)
	_box(torso, Vector3(0, 0.399, 0.252), Vector3(0.235, 0.025, 0.015), piping)

	for side in [-1.0, 1.0]:
		_round_piece(torso, Vector3(side * 0.13, 0.697, -0.018), Vector3(0.046, 0.071, 0.043), skin)
		_box(torso, Vector3(side * 0.051, 0.706, -0.134), Vector3(0.023, 0.014, 0.016), hair)
		_box(torso, Vector3(side * 0.114, 0.376, -0.11), Vector3(0.035, 0.33, 0.025), pack)
		var shoulder := _joint(torso, Vector3(side * 0.212, 0.472, 0))
		shoulder.rotation.z = side * 0.105
		_taper(shoulder, Vector3(0, -0.137, 0), 0.084, 0.056, 0.295, 0.94, sleeve)
		var elbow := _joint(shoulder, Vector3(0, -0.274, 0))
		_taper(elbow, Vector3(0, -0.119, 0), 0.057, 0.047, 0.252, 0.94, sleeve)
		_round_piece(elbow, Vector3(0, -0.268, 0), Vector3(0.10, 0.137, 0.10), skin)
		arms.append(shoulder)
		elbows.append(elbow)

		var thigh := _taper(self, Vector3.ZERO, 0.101, 0.073, THIGH_LENGTH + 0.06, 1.0, trousers)
		var shin := _taper(self, Vector3.ZERO, 0.074, 0.053, SHIN_LENGTH + 0.055, 1.0, trousers)
		var foot := _joint(self, Vector3.ZERO)
		_box(foot, Vector3(0, -0.052, -0.047), Vector3(0.147, 0.075, 0.247), shoe)
		_box(foot, Vector3(0, -0.085, -0.05), Vector3(0.152, 0.02, 0.255), sole)
		legs.append({"thigh": thigh, "shin": shin, "foot": foot, "side": side})
	reset_pose()

func reset_pose() -> void:
	gait_phase = 0.0
	gait_weight = 0.0
	run_weight = 0.0
	_pose(false)

func animate(delta: float, distance: float, speed: float, jogging: bool, grounded: bool) -> void:
	idle_time += delta
	var moving := smoothstep(0.06, 1.5, speed) if grounded else 0.0
	gait_weight = move_toward(gait_weight, moving, delta * 7.5)
	run_weight = move_toward(run_weight, 1.0 if jogging and moving > 0.0 else 0.0, delta * 5.0)
	if grounded and moving > 0.0:
		# Accumulated ground travel keeps planted feet at the same world position
		# on straight paths, even as the player speeds up or slows down.
		var stride := lerpf(WALK_STRIDE, RUN_STRIDE, run_weight)
		gait_phase = fposmod(gait_phase + distance / stride, 1.0)
	_pose(grounded)

func _pose(grounded: bool) -> void:
	var cycle := gait_phase * TAU
	var contact := lerpf(0.60, 0.42, run_weight)
	var stride := lerpf(WALK_STRIDE, RUN_STRIDE, run_weight)
	var hip_height := 0.895 - gait_weight * (0.035 + run_weight * 0.081)
	hip_height += lerpf(sin(idle_time * 2.8) * 0.006, -cos(cycle * 2.0) * 0.017, gait_weight)
	var sway := sin(cycle) * 0.024 * gait_weight
	torso.position = Vector3(sway, hip_height, 0)
	torso.rotation = Vector3(-run_weight * 0.12 - gait_weight * 0.025,
		sin(cycle - 0.45) * gait_weight * 0.14, -sin(cycle) * gait_weight * 0.03)

	for i in range(legs.size()):
		var leg := legs[i]
		var side: float = leg.side
		var step := fposmod(gait_phase + i * 0.5, 1.0)
		var forward_travel := stride * contact * 0.5
		var swing_progress := clampf((step - contact) / (1.0 - contact), 0.0, 1.0)
		var offset := stride * (step - contact * 0.5)
		if step >= contact:
			offset = lerpf(forward_travel, -forward_travel, smoothstep(0.0, 1.0, swing_progress))
		var lift := sin(swing_progress * PI) * lerpf(0.135, 0.28, run_weight)
		var ankle := Vector3(side * 0.115, ANKLE_HEIGHT + lift * gait_weight, offset * gait_weight)
		if grounded and gait_weight > 0.05:
			ankle.y += _floor_offset(ankle, lift)
		var hip := Vector3(side * 0.105 + sway, hip_height + lerpf(0.05, -0.005, gait_weight), 0)
		_pose_leg(leg, hip, ankle)
		var foot: Node3D = leg.foot
		foot.rotation = Vector3(sin(swing_progress * TAU) * 0.28 * gait_weight, -side * 0.07, 0)
		var arm_swing := sin(cycle + PI * i - 0.85) * gait_weight
		arms[i].rotation.x = arm_swing * lerpf(0.38, 0.65, run_weight)
		elbows[i].rotation.x = -0.10 - run_weight * 1.0 - maxf(0.0, arm_swing) * 0.24

func _floor_offset(ankle: Vector3, lift: float) -> float:
	var sample := to_global(Vector3(ankle.x, 0, ankle.z))
	var query := PhysicsRayQueryParameters3D.create(sample + Vector3.UP * 0.35, sample - Vector3.UP * 0.5)
	var body := get_parent() as PhysicsBody3D
	query.collision_mask = body.collision_mask
	query.exclude = [body.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return 0.0
	return clampf(hit.position.y - sample.y, -0.24, 0.26) * (1.0 - lift * 0.6) * gait_weight

func _pose_leg(leg: Dictionary, hip: Vector3, ankle: Vector3) -> void:
	var line := ankle - hip
	var direction := line.normalized()
	var reach := clampf(line.length(), 0.08, THIGH_LENGTH + SHIN_LENGTH - 0.002)
	ankle = hip + direction * reach
	var along := (THIGH_LENGTH * THIGH_LENGTH - SHIN_LENGTH * SHIN_LENGTH + reach * reach) / (2.0 * reach)
	var bend := (Vector3.FORWARD - direction * direction.dot(Vector3.FORWARD)).normalized()
	var knee := hip + direction * along + bend * sqrt(maxf(0.0, THIGH_LENGTH * THIGH_LENGTH - along * along))
	_place_segment(leg.thigh, knee, hip)
	_place_segment(leg.shin, ankle, knee)
	leg.foot.position = ankle

func _place_segment(segment: MeshInstance3D, bottom: Vector3, top: Vector3) -> void:
	var up := (top - bottom).normalized()
	var right := (Vector3.RIGHT - up * up.dot(Vector3.RIGHT)).normalized()
	segment.transform = Transform3D(Basis(right, up, right.cross(up)), (bottom + top) * 0.5)

func _joint(parent: Node3D, at: Vector3) -> Node3D:
	var joint := Node3D.new()
	joint.position = at
	parent.add_child(joint)
	return joint

func _material(colour: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(colour)
	material.roughness = 0.85
	return material

func _box(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	_mesh(parent, at, mesh, material)

func _round_piece(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 10
	mesh.rings = 5
	_mesh(parent, at, mesh, material).scale = size

func _taper(parent: Node3D, at: Vector3, top: float, bottom: float, height: float,
		depth_scale: float, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 8
	mesh.rings = 1
	var piece := _mesh(parent, at, mesh, material)
	piece.scale.z = depth_scale
	return piece

func _mesh(parent: Node3D, at: Vector3, mesh: Mesh, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	instance.material_override = material
	parent.add_child(instance)
	return instance
