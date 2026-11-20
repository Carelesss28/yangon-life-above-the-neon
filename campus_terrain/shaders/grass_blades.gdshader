shader_type spatial;
render_mode cull_disabled;
#include "res://shaders/breeze.gdshaderinc"
uniform vec3 observer=vec3(0.0);
varying vec3 blade_world;
varying float tint;
varying float blade_height;
void vertex() {
	vec3 wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	blade_height=UV.y;
	tint=INSTANCE_CUSTOM.r;
	vec3 breeze=town_breeze(wp.xz,TIME);
	VERTEX.x+=breeze.x*0.10*UV.y*UV.y;
	VERTEX.z+=breeze.z*0.10*UV.y*UV.y;
	blade_world=wp;
}
void fragment() {
	vec3 base=mix(vec3(0.07,0.12,0.065),vec3(0.10,0.16,0.07),tint);
	vec3 tip=mix(vec3(0.16,0.24,0.11),vec3(0.24,0.29,0.14),tint);
	ALBEDO=mix(base,tip,smoothstep(0.05,1.0,blade_height));
	NORMAL=normalize((VIEW_MATRIX*vec4(0.0,1.0,0.0,0.0)).xyz);
	ROUGHNESS=0.93;
}
