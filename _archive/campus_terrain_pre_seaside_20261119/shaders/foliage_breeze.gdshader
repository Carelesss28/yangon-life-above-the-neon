shader_type spatial;
render_mode cull_disabled;
#include "res://shaders/breeze.gdshaderinc"
uniform sampler2D base_texture : source_color, hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 base_colour : source_color=vec4(1.0);
uniform bool vertex_tint=false;
uniform float root_y=0.0;
uniform float plant_height=8.0;
uniform float sway_amount=0.18;
varying vec4 tint;
void vertex() {
	vec3 wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	float height=clamp((wp.y-root_y)/max(plant_height,0.1),0.0,1.0);
	float anchor=height*height;
	vec3 movement=town_breeze(wp.xz,TIME)*sway_amount*anchor;
	movement.x+=sin(wp.x*5.0+wp.z*3.0+TIME*2.8)*0.014*anchor;
	VERTEX+=(inverse(MODEL_MATRIX)*vec4(movement,0.0)).xyz;
	tint=COLOR;
}
void fragment() {
	vec4 colour=texture(base_texture,UV)*base_colour;
	if(vertex_tint) colour*=tint;
	ALBEDO=colour.rgb;
	ALPHA=colour.a;
	ALPHA_SCISSOR_THRESHOLD=0.42;
	ROUGHNESS=0.9;
}
