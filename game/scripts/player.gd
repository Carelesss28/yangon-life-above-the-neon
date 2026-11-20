extends CharacterBody2D
## The player on foot. Walks in screen space; diagonals follow the 2:1 isometric axes.

const SPEED := 72.0
const SHEET := "res://assets/placeholders/player.png"   # replaced by the real character art later

var sprite: Sprite2D
var camera: Camera2D
var _anim := 0.0


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	add_child(shape)

	sprite = Sprite2D.new()
	sprite.texture = load(SHEET)
	sprite.hframes = 5
	sprite.vframes = 2
	sprite.centered = false
	sprite.offset = Vector2(-16, -46)   # feet at the node position
	add_child(sprite)

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	add_child(camera)


func _draw() -> void:
	# soft ground shadow under the feet
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		pts.append(Vector2(cos(a) * 7.0, sin(a) * 3.0))
	draw_colored_polygon(pts, Color(0.1, 0.08, 0.2, 0.35))


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dir := input
	if absf(input.x) > 0.1 and absf(input.y) > 0.1:
		dir = Vector2(signf(input.x), signf(input.y) * 0.5).normalized()
	velocity = dir.normalized() * SPEED if dir.length() > 0.1 else Vector2.ZERO
	move_and_slide()

	if velocity.length() > 1.0:
		if absf(velocity.y) > 1.0:
			sprite.frame_coords.y = 1 if velocity.y < 0.0 else 0
		if absf(velocity.x) > 1.0:
			sprite.flip_h = velocity.x < 0.0
		_anim += delta * 8.0
		sprite.frame_coords.x = 1 + int(_anim) % 4
	else:
		_anim = 0.0
		sprite.frame_coords.x = 0


func set_camera_limits(r: Rect2) -> void:
	camera.limit_left = int(r.position.x)
	camera.limit_top = int(r.position.y)
	camera.limit_right = int(r.end.x)
	camera.limit_bottom = int(r.end.y)
