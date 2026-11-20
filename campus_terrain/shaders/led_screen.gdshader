shader_type spatial;
// Animated LED advertising screen: coarse pixel grid with drifting colour blocks and a scrolling band.
uniform vec4 tint_a : source_color = vec4(1.0,0.24,0.6,1.0);
uniform vec4 tint_b : source_color = vec4(0.18,0.9,0.88,1.0);
uniform float strength = 1.0;
uniform float seed = 0.0;
uniform vec2 cells = vec2(32.0,18.0);
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7))+seed)*43758.5453); }
void fragment() {
	vec2 cell=floor(UV*cells);
	vec2 f=fract(UV*cells);
	float led=smoothstep(0.0,0.18,f.x)*smoothstep(1.0,0.82,f.x)*smoothstep(0.0,0.18,f.y)*smoothstep(1.0,0.82,f.y);
	float slot=floor(TIME*0.45+seed);
	float block=hash(floor(cell/vec2(6.0,4.0))+slot);
	vec3 colour=mix(tint_a.rgb,tint_b.rgb,block);
	float band=smoothstep(0.0,0.12,abs(fract(UV.x*0.5-TIME*0.12+seed)-0.5)-0.3);
	float wave=0.55+0.45*sin(cell.y*0.5+TIME*2.0+block*6.0);
	colour*=mix(wave,1.0,band);
	colour+=vec3(1.0)*step(0.985,hash(cell+floor(TIME*3.0)))*0.6;
	ALBEDO=vec3(0.02);
	EMISSION=colour*led*strength*2.4;
	ROUGHNESS=0.3;
}
