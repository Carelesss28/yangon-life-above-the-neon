extends Node
## Rides like the metro: the player boards and travels the whole way (camera follows):
## cable car up/down, zipline, Ferris wheel loop, ferry cruise. Rides block other input until arrival.
const Layout=preload("res://scripts/terrain_layout.gd")
const Hill=preload("res://scripts/hill_attractions.gd")
var world
var active: Dictionary={}
var cabin: Node3D

func _ready() -> void:
	name="Rides"

func start(kind: String) -> bool:
	if not active.is_empty() or world.player.transit_mode: return false
	var path: Array=[]
	var duration=30.0
	var hang=0.0
	var end: Vector3
	match kind:
		"cable_up","cable_down":
			duration=40.0
			hang=-Hill.CABLE_HANG
			var station=Hill.CABLE_UPPER if kind=="cable_up" else Hill.CABLE_LOWER
			end=Vector3(station.x,0,station.y-4.0)
			_show_cable_cabins(false)
			_cabin("ff3d9a")
		"zip":
			var a=Vector3(198.59,Layout.height_at(198.59,712)+10.5,712)
			var b=Vector3(98.59,Layout.height_at(98.59,705)+3.0,705)
			for i in range(31):
				var t=float(i)/30.0
				var p=a.lerp(b,t)
				p.y-=sin(t*PI)*2.5
				path.append(p)
			duration=13.0
			hang=-1.9
			end=Vector3(98.59,0,709)
		"ferris":
			var x=535.21
			var c=Vector3(x,Layout.PROMENADE_Y+15.0,Layout.shore(x)+16.0)
			for i in range(61):
				var a=-PI/2+TAU*float(i)/60.0
				path.append(c+Vector3(cos(a)*13.0,sin(a)*13.0,0))
			duration=55.0
			hang=-1.9
			end=Vector3(x+4,0,Layout.shore(x)+21.0)
			_cabin("f2c94c")
		"ferry":
			var ship=null
			if world.traffic:
				for s in world.traffic.ships:
					if s.ferry: ship=s
			if ship==null: return false
			for spot in world.activity_spots:
				if spot.title=="FERRY TERMINAL":
					end=spot.pos
					break
			active={"kind":kind,"ship":ship,"t":0.0,"left":false,"end":end}
			world.player.transit_mode=true
			world.camera.target=world.player
			world.npcs.show_toast("All aboard the harbour ferry!")
			return true
	active={"kind":kind,"path":path,"t":0.0,"duration":duration,"hang":hang,"end":end}
	world.player.transit_mode=true
	world.camera.target=world.player
	world.camera.instant=true
	return true

func _cabin(colour: String) -> void:
	cabin=Node3D.new()
	world.add_child(cabin)
	var body=MeshInstance3D.new()
	var mesh=BoxMesh.new()
	mesh.size=Vector3(2.2,2.0,2.6)
	body.mesh=mesh
	var m=world._mat(colour,0.4)
	m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color.a=0.45
	body.material_override=m
	body.position=Vector3(0,1.0,0)
	cabin.add_child(body)

func _process(delta: float) -> void:
	if active.is_empty(): return
	if active.kind=="ferry":
		var s=active.ship
		active.t+=delta
		world.player.global_position=s.node.global_position+Vector3(0,3.2,2.0)
		if s.pause<=0.0: active.left=true
		if active.left and s.pause>0.0 and active.t>20.0: _finish(active.end)
		return
	active.t+=delta
	var u=clampf(active.t/active.duration,0.0,1.0)
	var pos: Vector3
	if active.kind in ["cable_up","cable_down"]:
		var curve: Curve3D=world.hill.cable_curve
		var progress=u if active.kind=="cable_up" else 1.0-u
		pos=curve.sample_baked(progress*curve.get_baked_length())+Vector3.RIGHT*1.6
	else:
		var path: Array=active.path
		var f=u*(path.size()-1)
		var i=mini(int(f),path.size()-2)
		pos=path[i].lerp(path[i+1],f-i)
	var at=pos+Vector3(0,active.hang,0)
	world.player.global_position=at
	if cabin: cabin.global_position=at+Vector3(0,-0.15,0)
	if u>=1.0: _finish(active.end)

func _finish(end: Vector3) -> void:
	if active.get("kind","") in ["cable_up","cable_down"]: _show_cable_cabins(true)
	if cabin:
		cabin.queue_free()
		cabin=null
	active={}
	world.player.transit_mode=false
	var landing_y=end.y if end.y!=0.0 else Layout.height_at(end.x,end.z)
	world.player.teleport(Vector3(end.x,landing_y+0.3,end.z))
	world.camera.instant=true
	if world.npcs: world.npcs.show_toast("You have arrived.")

func _show_cable_cabins(visible_on_rope: bool) -> void:
	for mover in world.hill.movers:
		if mover.kind=="cable" and mover.offset.x>0:
			mover.node.visible=visible_on_rope
