extends RefCounted
## Emergency services: police station and fire & rescue station dressing (signs, beacons, parked
## patrol cars / police bikes / fire trucks, hose-drying tower, apparatus bay doors).
var world
var count=0

func setup(owner_world) -> void:
	world=owner_world
	for building in world.get_node("PrototypeBuildings").get_children():
		var title: String=str(building.get_meta("building_use",""))
		if not building.has_meta("entrance_local"): continue
		if "POLICE STATION" in title: _police(building)
		elif "FIRE STATION" in title: _fire(building)
	print("SERVICES_READY ",count)

func _box(parent: Node3D,at: Vector3,size: Vector3,mat: Material,solid=false) -> MeshInstance3D:
	var m=MeshInstance3D.new()
	var mesh=BoxMesh.new()
	mesh.size=size
	m.mesh=mesh
	m.material_override=mat
	m.position=at
	parent.add_child(m)
	if solid:
		var body=StaticBody3D.new()
		var shape=CollisionShape3D.new()
		var b=BoxShape3D.new()
		b.size=size
		shape.shape=b
		body.add_child(shape)
		m.add_child(body)
	return m

func _sign(parent: Node3D,at: Vector3,text: String,colour: String) -> void:
	_box(parent,at,Vector3(9.0,1.3,0.25),world._mat("15161c",0.6))
	_box(parent,at+Vector3(0,0.72,0.14),Vector3(8.8,0.1,0.06),world._mat(colour,0.3,4.0))
	_box(parent,at+Vector3(0,-0.72,0.14),Vector3(8.8,0.1,0.06),world._mat(colour,0.3,4.0))
	var label=Label3D.new()
	label.text=text
	label.font_size=64
	label.pixel_size=0.016
	label.position=at+Vector3(0,0,0.16)
	label.modulate=Color(colour).lightened(0.5)
	label.outline_size=8
	label.outline_modulate=Color("101018")
	label.shaded=false
	parent.add_child(label)

func _beacon(parent: Node3D,at: Vector3,colour: String) -> void:
	_box(parent,at,Vector3(0.5,0.5,0.5),world._mat(colour,0.3,5.0))
	var spin=Node3D.new()
	spin.set_script(load("res://scripts/spin.gd"))
	spin.speed=3.5
	spin.position=at
	parent.add_child(spin)
	var beam=SpotLight3D.new()
	beam.light_color=Color(colour)
	beam.spot_range=24.0
	beam.spot_angle=22.0
	beam.light_energy=0.0
	beam.set_meta("night_energy",2.5)
	beam.rotation_degrees=Vector3(-20,0,0)
	beam.shadow_enabled=false
	spin.add_child(beam)
	world.lamps.append(beam)

func _parked(parent: Node3D,at: Vector3,vehicle: Node3D) -> void:
	vehicle.position=at
	parent.add_child(vehicle)

func _police(b: Node3D) -> void:
	var door: Vector3=b.get_meta("entrance_local")
	_sign(b,door+Vector3(0,5.2,0.4),"POLICE  ·  ရဲစခန်း","4f8bff")
	for x in [-5.5,5.5]: _beacon(b,door+Vector3(x,6.2,0.4),"2a6bff" if x<0 else "ff2a2a")
	_box(b,door+Vector3(0,0.02,4.5),Vector3(10,0.04,6),world._mat("2a3a6a",0.8))   # marked forecourt
	var t=world.traffic
	if t:
		for x in [-2.3,2.3]:
			var car=Node3D.new()
			car.add_child(t.make_model("t_camry"))
			var bar=t.light_bar(car,Vector3(0,1.55,0),"2a6bff","ff2a2a")
			car.rotation.y=PI
			_parked(b,door+Vector3(x,0.05,6.5),car)
			var col=_box(car,Vector3(0,0.75,0),Vector3(1.8,1.5,4.8),world.mats.metal,true)
			col.visible=false
		if t.scenes.has("hdPolice"):
			var bike=Node3D.new()
			bike.add_child(t.make_model("hdPolice"))
			bike.rotation.y=PI/2
			_parked(b,door+Vector3(-4.5,0.05,2.6),bike)
	count+=1

func _fire(b: Node3D) -> void:
	var door: Vector3=b.get_meta("entrance_local")
	_sign(b,door+Vector3(0,5.2,0.4),"FIRE & RESCUE  ·  မီးသတ်","ff4a2a")
	for x in [-5.5,5.5]: _beacon(b,door+Vector3(x,6.2,0.4),"ff2a2a")
	# Red apparatus bay doors beside the entrance and a hose-drying tower.
	var red=world._mat("c8261c",0.5)
	var white=world._mat("f2f0e8",0.5)
	for x in [-7.5,7.5]:
		_box(b,door+Vector3(x,2.0,0.1),Vector3(4.2,4.0,0.2),red)
		for k in range(5): _box(b,door+Vector3(x,0.6+k*0.75,0.22),Vector3(4.2,0.06,0.04),white)
	var tower=_box(b,door+Vector3(-12.0,7.5,-4.0),Vector3(3.2,15.0,3.2),red,true)
	_box(b,door+Vector3(-12.0,15.2,-4.0),Vector3(3.8,0.4,3.8),white)
	for k in range(4): _box(b,door+Vector3(-12.0,3.0+k*3.2,-2.35),Vector3(1.6,1.2,0.08),world._mat("ffd6a0",0.3,1.5))
	_box(b,door+Vector3(0,0.02,4.5),Vector3(12,0.04,6),world._mat("7a2a24",0.8))
	var t=world.traffic
	if t:
		for x in [-2.6,2.6]:
			var truck=Node3D.new()
			truck.add_child(t.fire_truck())
			truck.rotation.y=PI
			_parked(b,door+Vector3(x,0.05,7.5),truck)
			var col=_box(truck,Vector3(0,1.5,0),Vector3(2.5,3.0,8.6),world.mats.metal,true)
			col.visible=false
	count+=1
