shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque;
#include "res://shaders/breeze.gdshaderinc"
uniform float wave_height=0.045;
uniform bool channel_flow=false;
uniform vec2 flow_direction=vec2(1.0,0.0);
uniform float flow_speed=0.14;
uniform float opacity=0.43;
varying vec3 water_world;
varying vec3 water_normal;
void vertex() {
	water_world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	water_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
	if(water_normal.y<0.0) water_normal=-water_normal;
	float anchor=COLOR.r;
	if(channel_flow) anchor=smoothstep(0.0,0.16,UV.x)*(1.0-smoothstep(0.84,1.0,UV.x));
	float strength=channel_flow ? 0.006 : wave_height;
	vec2 p=water_world.xz;
	float w=sin(dot(p,vec2(0.60,0.28))-TIME*0.75)*0.72+sin(dot(p,vec2(-0.38,0.64))-TIME*0.58)*0.28;
	float gust=0.88+0.12*length(town_breeze(p,TIME));
	VERTEX+=(inverse(MODEL_MATRIX)*vec4(0.0,w*strength*anchor*gust,0.0,0.0)).xyz;

}
void fragment() {
	vec2 p=water_world.xz-flow_direction*TIME*flow_speed;
	if(channel_flow) p=vec2(UV.x*1.2,UV.y-TIME*flow_speed);
	float a=sin(p.x*2.1+p.y*1.3);
	float b=sin(p.x*-1.1+p.y*3.4+1.7);
	float c=sin(p.x*4.3+p.y*-2.5+0.6);
	float swell_a=cos(dot(water_world.xz,vec2(0.60,0.28))-TIME*0.75);
	float swell_b=cos(dot(water_world.xz,vec2(-0.38,0.64))-TIME*0.58);
	float amplitude=channel_flow ? 0.006 : wave_height;
	vec3 tilt=vec3(a*0.012+c*0.004+swell_a*amplitude*0.60,0.0,b*0.012+c*0.004+swell_b*amplitude*0.64);
	vec3 n=normalize(water_normal+tilt);
	NORMAL=normalize((VIEW_MATRIX*vec4(n,0.0)).xyz);
	float fresnel=pow(1.0-clamp(dot(NORMAL,VIEW),0.0,1.0),4.0);
	float shimmer=(a+b+c)*0.003;
	ALBEDO=vec3(0.045,0.14,0.19)+vec3(shimmer);
	ROUGHNESS=0.20;
	METALLIC=0.0;
	SPECULAR=0.72;
	ALPHA=clamp(opacity+fresnel*0.16,0.0,0.75);
}
