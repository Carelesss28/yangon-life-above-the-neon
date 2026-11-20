class_name Iso
## 2:1 isometric maths (framework section 1). Map units are tiles; 1 tile = 32 x 16 px.
## Map x runs down-right on screen, map y runs down-left.


static func to_screen(m: Vector2) -> Vector2:
	return Vector2((m.x - m.y) * 16.0, (m.x + m.y) * 8.0)


static func to_map(s: Vector2) -> Vector2:
	return Vector2(s.x / 32.0 + s.y / 16.0, s.y / 16.0 - s.x / 32.0)


## Screen-space corners of a map rectangle: back, right, front, left.
static func rect_corners(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		to_screen(r.position),
		to_screen(Vector2(r.end.x, r.position.y)),
		to_screen(r.end),
		to_screen(Vector2(r.position.x, r.end.y)),
	])


## True if footprint a is drawn behind footprint b (non-overlapping footprints).
## a is behind b when it lies wholly at smaller x or wholly at smaller y, except when it is at the
## same time wholly in front on the other axis: then they sit diagonally (one screen-left, one
## screen-right) and never overlap on screen.
static func behind(a: Rect2, b: Rect2) -> bool:
	var eps := 0.001
	var before_x := a.end.x <= b.position.x + eps and a.position.y < b.end.y - eps
	var before_y := a.end.y <= b.position.y + eps and a.position.x < b.end.x - eps
	return before_x or before_y
