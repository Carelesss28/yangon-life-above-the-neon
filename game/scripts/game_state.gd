extends Node
## Global game state (autoload "Game"): clock, day/night colours, moving between the campus and
## rooms, input actions and the HUD.

const DAY_START := 6 * 60          # the waking day runs 06:00 ...
const DAY_END := 26 * 60           # ... to 02:00 the next morning (GameConcept.md)
const REAL_SECONDS_PER_DAY := 30.0 * 60.0
const GAME_MINUTES_PER_SECOND := float(DAY_END - DAY_START) / REAL_SECONDS_PER_DAY

const NIGHT := Color(0.33, 0.35, 0.55)
const DUSK := Color(0.95, 0.74, 0.70)

var day := 1
var minutes := 8.0 * 60.0
var time_scale := 1.0
var pieces := {}
var tiles := {}
var layout := {}

## Where the player appears in the next scene.
var next_room := ""
var room_spawn := Vector2(-1, -1)      # room pixels
var campus_spawn := Vector2(-1, -1)    # campus map units

var _hud: CanvasLayer
var _clock: Label
var _prompt: Label
var _title: Label
var _fade: ColorRect
var _busy := false


func _ready() -> void:
	_setup_input()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://game/data/pieces.json"))
	pieces = data["pieces"]
	tiles = data["tiles"]
	layout = JSON.parse_string(FileAccess.get_file_as_string("res://game/data/campus.json"))
	_build_hud()


func _process(delta: float) -> void:
	minutes += delta * GAME_MINUTES_PER_SECOND * time_scale
	if minutes >= DAY_END:
		# Out past 02:00: the player passes out and wakes the next morning.
		minutes = DAY_START
		day += 1
	_clock.text = clock_text()
	if Input.is_action_just_pressed("time_fast"):
		time_scale = 1.0 if time_scale > 1.0 else 60.0


func clock_text() -> String:
	var m := int(minutes) % (24 * 60)
	var fast := "  >>" if time_scale > 1.0 else ""
	return "Day %d   %02d:%02d%s" % [day, m / 60, m % 60, fast]


## 0 in full daylight, 1 at night.
func night_factor() -> float:
	var h := fmod(minutes / 60.0, 24.0)
	if h >= 6.0 and h < 17.0:
		return 0.0
	if h >= 17.0 and h < 19.5:
		return smoothstep(17.0, 19.5, h)
	if h >= 5.0 and h < 6.0:
		return 1.0 - smoothstep(5.0, 6.0, h)
	return 1.0


## Colour that multiplies the world: white by day, warm at dusk, blue at night.
func ambient() -> Color:
	var h := fmod(minutes / 60.0, 24.0)
	var n := night_factor()
	var c := Color.WHITE.lerp(NIGHT, n)
	var dusk := clampf(1.0 - absf(h - 18.0) / 1.5, 0.0, 1.0)
	return c * Color.WHITE.lerp(DUSK, dusk * 0.6)


func show_prompt(text: String) -> void:
	_prompt.text = text
	_prompt.visible = text != ""


func show_title(text: String) -> void:
	_title.text = text


func go_to_room(room: String, spawn := Vector2(-1, -1)) -> void:
	next_room = room
	room_spawn = spawn
	_change_scene("res://game/scenes/room.tscn")


func go_to_campus(spawn: Vector2) -> void:
	campus_spawn = spawn
	_change_scene("res://game/scenes/campus.tscn")


func _change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	show_prompt("")
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, 0.25)
	await t.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	var t2 := create_tween()
	t2.tween_property(_fade, "color:a", 0.0, 0.25)
	await t2.finished
	_busy = false


func _setup_input() -> void:
	var keys := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E, KEY_SPACE, KEY_ENTER], "time_fast": [KEY_T],
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)


func _build_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 10
	add_child(_hud)
	_clock = _label(Vector2(8, 6), HORIZONTAL_ALIGNMENT_LEFT)
	_title = _label(Vector2(8, 20), HORIZONTAL_ALIGNMENT_LEFT)
	_title.modulate = Color(1, 1, 1, 0.75)
	_prompt = _label(Vector2(0, 326), HORIZONTAL_ALIGNMENT_CENTER)
	_prompt.size = Vector2(640, 20)
	_prompt.visible = false
	var help := _label(Vector2(0, 344), HORIZONTAL_ALIGNMENT_CENTER)
	help.size = Vector2(640, 14)
	help.text = "WASD / arrows: walk    E: interact    T: fast time"
	help.modulate = Color(1, 1, 1, 0.45)
	help.add_theme_font_size_override("font_size", 8)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.size = Vector2(640, 360)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(_fade)


func _label(pos: Vector2, align: HorizontalAlignment) -> Label:
	var l := Label.new()
	l.position = pos
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	_hud.add_child(l)
	return l
