extends SceneTree
const Layout=preload("res://scripts/terrain_layout.gd")
var failures=0

class FocusedHUD:
	extends Control
	func _gui_input(_event: InputEvent) -> void:
		accept_event()

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in range(count): await physics_frame

func check(ok: bool,message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if not ok: failures+=1

func press_e() -> void:
	var event=InputEventKey.new()
	event.keycode=KEY_E
	event.physical_keycode=KEY_E
	event.pressed=true
	Input.parse_input_event(event)
	await frames(40)
	var release=InputEventKey.new()
	release.keycode=KEY_E
	release.physical_keycode=KEY_E
	release.pressed=false
	Input.parse_input_event(release)
	await frames(1)

func run() -> void:
	var world=load("res://main.tscn").instantiate()
	root.add_child(world)
	await frames(5)
	var manager=world.interiors
	var player=world.player
	player.test_mode=true
	var hud=FocusedHUD.new()
	hud.focus_mode=Control.FOCUS_ALL
	hud.size=Vector2(20,20)
	root.add_child(hud)
	hud.grab_focus()
	check(manager.records.size()==manager.total_buildings,"All buildings have usable entrances")
	for index in range(manager.records.size()):
		var target: Vector3=manager.records[index].outside
		var start=target+Vector3(0,0,6)
		start.y=Layout.height_at(start.x,start.z)+0.15
		player.teleport(start)
		await frames(8)
		for tick in range(220):
			if manager.find_entrance()==index: break
			var delta=Vector2(target.x-player.position.x,target.z-player.position.z)
			player.test_direction=Vector3(delta.x,0,delta.y).normalized()
			await physics_frame
		player.test_direction=Vector3.ZERO
		await frames(3)
		check(manager.find_entrance()==index,"Approach from street: "+manager.records[index].title)
		await press_e()
		check(manager.inside and manager.active_index==index,"E enters despite HUD focus")
		if manager.inside:
			player.teleport(manager.exit_position)
			await press_e()
			check(not manager.inside,"E exits to the street")
	# Also exercise the visible on-screen entry action.
	player.teleport(manager.records[0].outside)
	await frames(3)
	check(manager.action_button.visible,"Visible Enter building button")
	manager.action_button.pressed.emit()
	await frames(40)
	check(manager.inside,"Clicking Enter works")
	if manager.inside: await manager.leave(false)
	print("ENTRANCE_APPROACH_CHECK ","PASS" if failures==0 else "FAIL"," buildings=",manager.records.size()," failures=",failures)
	await world._quit_cleanly()
