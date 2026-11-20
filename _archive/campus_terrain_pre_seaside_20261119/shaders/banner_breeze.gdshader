shader_type spatial;
render_mode cull_disabled;
#include "res://shaders/breeze.gdshaderinc"
varying vec3 cloth_world;
void vertex() {
	vec3 wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	float anchor=UV.y*UV.y;
	vec3 movement=town_breeze(wp.xz,TIME)*0.25*anchor;
	movement.z+=sin(UV.x*5.5-UV.y*3.0-TIME*2.2)*0.045*anchor;
	VERTEX+=(inverse(MODEL_MATRIX)*vec4(movement,0.0)).xyz;
	cloth_world=wp;
}
void fragment() {
	float trim=step(0.88,UV.y);
	ALBEDO=mix(vec3(0.045,0.17,0.20),vec3(0.36,0.27,0.13),trim);
	ROUGHNESS=0.87;
}
