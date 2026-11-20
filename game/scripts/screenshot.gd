extends Node
## Debug helper (autoload "Shot"). Example:
##   godot --path . -- --shot=out.png --frames=40 --at=60,50 --time=21:00 --room=classroom
## --at: campus map position; --time: clock HH:MM; --room: start inside a room.

var args := {}
var frames := 0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1] if kv.size() > 1 else ""
	if not args.has("shot"):
		set_process(false)
		return
	if args.has("time"):
		var hm: PackedStringArray = args["time"].split(":")
		var m := int(hm[0]) * 60 + int(hm[1])
		Game.minutes = m + 24 * 60 if m < Game.DAY_START else m
	if args.has("at"):
		var xy: PackedStringArray = args["at"].split(",")
		Game.campus_spawn = Vector2(float(xy[0]), float(xy[1]))
	if args.has("room"):
		Game.next_room = args["room"]
		get_tree().call_deferred("change_scene_to_file", "res://game/scenes/room.tscn")


func _process(_delta: float) -> void:
	frames += 1
	# --hold=move_left:10:70  holds an action from frame 10 to 70; --tap=interact:30 taps it once
	if args.has("hold"):
		var h: PackedStringArray = args["hold"].split(":")
		if frames == int(h[1]):
			Input.action_press(h[0])
		elif frames == int(h[2]):
			Input.action_release(h[0])
	if args.has("tap"):
		var t: PackedStringArray = args["tap"].split(":")
		if frames == int(t[1]):
			Input.action_press(t[0])
		elif frames == int(t[1]) + 2:
			Input.action_release(t[0])
	if args.has("log") and frames % 20 == 0:
		var p: Node2D = get_tree().current_scene.get("player")
		if p != null:
			print("frame %d scene %s pos %s map %s" % [frames, get_tree().current_scene.name, p.position, Iso.to_map(p.position)])
	if args.has("zoom") and frames == 2:
		var cam := get_viewport().get_camera_2d()
		if cam != null:
			cam.zoom = Vector2.ONE * float(args["zoom"])
			cam.limit_left = -100000
			cam.limit_top = -100000
			cam.limit_right = 100000
			cam.limit_bottom = 100000
	if frames == int(args.get("frames", "40")):
		get_viewport().get_texture().get_image().save_png(args["shot"])
		get_tree().quit()
