extends Node3D
## A small delivery/patrol drone circling above the streets with blinking navigation lights.
var centre: Vector3
var radius: float=20.0
var speed: float=0.25
var angle: float=0.0
var bob: float=0.0
var blink: MeshInstance3D
var rotors: Array=[]
var clock: float=0.0

func _process(delta: float) -> void:
	clock+=delta
	angle+=speed*delta
	var p=centre+Vector3(cos(angle)*radius,sin(clock*1.3+bob)*0.6,sin(angle)*radius*0.7)
	var ahead=centre+Vector3(cos(angle+0.05)*radius,0,sin(angle+0.05)*radius*0.7)
	position=p
	var direction=Vector3(ahead.x-p.x,0,ahead.z-p.z)
	if direction.length()>0.001: rotation.y=atan2(direction.x,direction.z)
	for rotor in rotors: rotor.rotation.y+=delta*40.0
	if blink: blink.visible=fmod(clock+bob,1.2)<0.18
