shader_type spatial;
// Manicured campus lawn: mown stripes, dry and clover patches. Lit by the game, no baked light.
varying vec3 lawn_pos;
float hash21(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise2(vec2 p) {
	vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);
}
void vertex() { lawn_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 p=lawn_pos.xz;
	float stripe=smoothstep(0.35,0.65,0.5+0.5*sin((p.x*0.9+p.y*0.55)*0.62));
	vec3 base=mix(vec3(0.115,0.215,0.085),vec3(0.155,0.265,0.095),stripe);
	float patch=noise2(p*0.11)*0.6+noise2(p*0.4)*0.3+noise2(p*1.9)*0.1;
	base=mix(base,vec3(0.075,0.16,0.07),smoothstep(0.4,0.8,patch)*0.55);
	float dry=smoothstep(0.66,0.84,noise2(p*0.14+17.0));
	base=mix(base,vec3(0.25,0.235,0.115),dry*0.55);
	float clover=smoothstep(0.7,0.86,noise2(p*0.5+3.0));
	base=mix(base,vec3(0.11,0.28,0.14),clover*0.45);
	base*=0.9+noise2(p*8.0)*0.2;
	ALBEDO=base;
	ROUGHNESS=0.95;
}
