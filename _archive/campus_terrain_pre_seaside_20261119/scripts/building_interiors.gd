extends Node3D
## One furnished interior is loaded at a time; the outdoor world remains intact.
const Layout=preload("res://scripts/terrain_layout.gd")
const Rooms=preload("res://scripts/interior_rooms.gd")
var world
var records: Array=[]
var total_buildings=0
var inside=false
var busy=false
var active_room: Node3D
var active_index=-1
var exit_position=Vector3.ZERO
var saved={}
var prompt: Label
var shade: ColorRect
var nearest=-1
var action_button: Button
const ROOM_ORIGIN=Vector3(150,-180,150)

func _ready() -> void:
	name="BuildingInteriors"
	var buildings=world.get_node("PrototypeBuildings")
	total_buildings=buildings.get_child_count()
	for building in buildings.get_children():
		if not building.has_meta("entrance_local"): continue
		var title: String=building.get_meta("building_use")
		var local: Vector3=building.get_meta("entrance_local")
		var outside=building.global_position+local+Vector3(0,0,2.8)
		outside.y=Layout.height_at(outside.x,outside.z)+0.12
		var marker=Label3D.new()
		marker.name="EntranceHint"
		marker.text="ENTER [E]"
		marker.font_size=40
		marker.pixel_size=0.018
		marker.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		marker.position=building.to_local(outside)+Vector3.UP*2.8
		marker.modulate=Color("ffdc9f")
		marker.visible=false
		building.add_child(marker)
		var record={"id":str(building.name),"title":title,"outside":outside,"building":building,"marker":marker}
		records.append(record)
		building.set_meta("explorable",true)
		building.set_meta("interior_index",records.size()-1)
		var strip=MeshInstance3D.new()
		var mesh=BoxMesh.new()
		mesh.size=Vector3(0.14,2.5,0.12)
		strip.mesh=mesh
		strip.material_override=world.mats.cyan
		strip.name="ExplorableDoorMarker"
		strip.position=local+Vector3(1.2,1.3,0.25)
		building.add_child(strip)
	var layer=CanvasLayer.new()
	layer.layer=25
	add_child(layer)
	prompt=Label.new()
	prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	prompt.position=Vector2(24,-116)
	prompt.add_theme_font_size_override("font_size",20)
	prompt.add_theme_color_override("font_color",Color("ffdb9c"))
	prompt.add_theme_color_override("font_shadow_color",Color("12232e"))
	prompt.add_theme_constant_override("shadow_offset_x",2)
	prompt.add_theme_constant_override("shadow_offset_y",2)
	layer.add_child(prompt)
	action_button=Button.new()
	action_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	action_button.position=Vector2(24,-205)
	action_button.custom_minimum_size=Vector2(250,44)
	action_button.focus_mode=Control.FOCUS_NONE
	action_button.visible=false
	action_button.pressed.connect(interact)
	layer.add_child(action_button)
	var fade_layer=CanvasLayer.new()
	fade_layer.layer=100
	add_child(fade_layer)
	shade=ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color=Color("0b1721")
	shade.modulate.a=0
	shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(shade)
	print("EXPLORABLE_BUILDINGS_READY ",records.size(),"/",total_buildings)

func _process(_delta: float) -> void:
	action_button.visible=false
	for record in records: record.marker.visible=false
	if world.player.transit_mode: prompt.text=""; return
	if busy: prompt.text=""; return
	if inside:
		var can_exit=world.player.global_position.distance_to(exit_position)<3
		prompt.text="[E] Return outside" if can_exit else str(records[active_index].title)+"  /  Exit at the entrance"
		action_button.text="Exit building [E]"
		action_button.visible=can_exit
		return
	nearest=find_entrance()
	for record in records:
		record.marker.visible=world.player.global_position.distance_to(record.outside)<15
	prompt.text=("[E] Enter "+str(records[nearest].title)) if nearest>=0 else ("Cyan door strips: explorable buildings  /  %d of %d open" % [records.size(),total_buildings])
	action_button.text="Enter building [E]"
	action_button.visible=nearest>=0

func find_entrance() -> int:
	var selected=-1
	var closest=6.0
	for i in range(records.size()):
		var delta: Vector3=world.player.global_position-records[i].outside
		var distance=Vector2(delta.x,delta.z).length()
		if absf(delta.y)<3.5 and distance<closest: closest=distance; selected=i
	return selected

func _input(event: InputEvent) -> void:
	if world.player.transit_mode: return
	if not event is InputEventKey or not event.pressed or event.echo or event.physical_keycode!=KEY_E: return
	if interact(): get_viewport().set_input_as_handled()

func interact() -> bool:
	if busy or world.player.paused: return false
	if world.player.transit_mode: return false
	if inside:
		if world.player.global_position.distance_to(exit_position)<3:
			leave()
			return true
	else:
		nearest=find_entrance()
	if not inside and nearest>=0:
		enter(nearest)
		return true
	return false

func fade(alpha: float) -> void:
	var tween=create_tween()
	tween.tween_property(shade,"modulate:a",alpha,0.22)
	await tween.finished

func enter(index: int,animated=true) -> bool:
	if world.player.transit_mode: return false
	if busy or inside or index<0 or index>=records.size(): return false
	busy=true
	saved={"position":world.player.global_position,"zoom":world.camera.zoom,"overview":world.camera.overview,"masterplan":world.camera.masterplan,"paused":world.player.paused}
	world.player.paused=true
	if animated: await fade(1)
	active_room=Rooms.new().make(world,records[index].title,index)
	active_room.position=ROOM_ORIGIN
	add_child(active_room)
	active_index=index
	inside=true
	world.player.interior_mode=true
	outdoor_effects(false)
	var depth: float=active_room.get_meta("room_depth")
	exit_position=ROOM_ORIGIN+Vector3(0,0.1,depth/2-1.6)
	world.player.teleport(exit_position+Vector3(0,0,-1.2))
	world.camera.overview=false
	world.camera.masterplan=false
	world.camera.zoom=0.65 if depth<20 else 0.85
	world.camera.target=world.player
	world.camera.instant=true
	if animated: await fade(0)
	world.player.paused=saved.paused
	busy=false
	print("ENTERED_BUILDING ",records[index].id," ",records[index].title)
	return true

func leave(animated=true) -> bool:
	if busy or not inside: return false
	busy=true
	world.player.paused=true
	if animated: await fade(1)
	world.player.interior_mode=false
	outdoor_effects(true)
	world.player.teleport(saved.position)
	world.camera.zoom=saved.zoom
	world.camera.overview=saved.overview
	world.camera.masterplan=saved.masterplan
	world.camera.target=world.player
	world.camera.instant=true
	inside=false
	active_room.queue_free()
	active_room=null
	active_index=-1
	if animated: await fade(0)
	world.player.paused=saved.paused
	busy=false
	print("EXITED_BUILDING")
	return true

func outdoor_effects(enabled: bool) -> void:
	if world.wildlife: world.wildlife.visible=enabled
	if world.breeze:
		world.breeze.visible=enabled
		if world.breeze.sound: world.breeze.sound.stream_paused=not enabled
	if world.grass_system:
		world.grass_system.set_process(enabled)
		world.grass_system.visible=enabled
