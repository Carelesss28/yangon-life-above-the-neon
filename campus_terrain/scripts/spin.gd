extends Node3D
## Rotates continuously about a local axis (lighthouse beam, beacons, Ferris wheel).
var speed: float=1.0
var axis: Vector3=Vector3.UP

func _process(delta: float) -> void:
	rotate_object_local(axis.normalized(),speed*delta)
