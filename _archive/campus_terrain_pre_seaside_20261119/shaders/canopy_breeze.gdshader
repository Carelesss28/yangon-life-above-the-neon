shader_type spatial;
#include "res://shaders/breeze.gdshaderinc"
// Instanced tree crowns: per-instance colour, shared town breeze, crown moves more than the base.
void vertex() {
	vec3 wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	vec3 origin=MODEL_MATRIX[3].xyz;
	float anchor=clamp((VERTEX.y+1.0)*0.5,0.0,1.0);
	float phase=fract(sin(dot(origin.xz,vec2(12.9898,78.233)))*43758.5453)*6.283;
	vec3 movement=town_breeze(wp.xz,TIME)*0.26*(0.35+0.65*anchor);
	movement.x+=sin(wp.x*1.7+wp.z*1.3+TIME*2.6+phase)*0.07*anchor;
	movement.z+=cos(wp.x*1.1-wp.z*1.9+TIME*2.1+phase)*0.05*anchor;
	VERTEX+=(inverse(MODEL_MATRIX)*vec4(movement,0.0)).xyz;
}
void fragment() {
	// Instance colours are authored in sRGB; convert so crowns are not washed out.
	ALBEDO=pow(COLOR.rgb,vec3(2.2));
	ROUGHNESS=0.88;
}
