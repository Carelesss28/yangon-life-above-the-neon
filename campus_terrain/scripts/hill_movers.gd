extends Node
## Animates hill attraction movers: cable-car cabins, the zipline seat and the campfire flicker.
var items: Array=[]
var clock=0.0

func _process(delta: float) -> void:
	clock+=delta
	for m in items:
		match m.kind:
			"cable":
				m.t+=m.speed*delta*m.dir
				if m.t>1.0 or m.t<0.0:
					m.dir=-m.dir
					m.t=clampf(m.t,0.0,1.0)
				m.node.position=m.curve.sample_baked(m.curve.get_baked_length()*m.t)+m.offset
			"zip":
				m.t=fposmod(m.t+delta*0.05,1.3)
				var u=clampf(m.t,0.0,1.0)
				var p: Vector3=m.a.lerp(m.b,u*u)
				p.y-=sin(u*PI)*2.5
				m.node.position=p
				m.node.visible=m.t<1.0
			"flicker":
				if m.node.light_energy>0.0:
					m.node.light_energy=2.4+0.6*sin(clock*13.0)+0.3*sin(clock*31.0)
