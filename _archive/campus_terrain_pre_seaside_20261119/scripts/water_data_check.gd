extends SceneTree
const Layout=preload("res://scripts/terrain_layout.gd")
func _initialize() -> void:
	var failures=0
	for route in Layout.WATER_ROUTES:
		for i in range(1,route.points.size()):
			if route.points[i].y>route.points[i-1].y:
				push_error("Uphill water route: "+route.name)
				failures+=1
	var market_end: Vector3=Layout.WATER_ROUTES[3].points[-1]
	var tech_join: Vector3=Layout.WATER_ROUTES[2].points[5]
	if not market_end.is_equal_approx(tech_join): failures+=1
	var home_end: Vector3=Layout.WATER_ROUTES[1].points[-1]
	var main_join: Vector3=Layout.WATER_ROUTES[0].points[9]
	if not home_end.is_equal_approx(main_join): failures+=1
	print("WATER_DATA_CHECK_COMPLETE failures=",failures)
	quit(1 if failures else 0)
