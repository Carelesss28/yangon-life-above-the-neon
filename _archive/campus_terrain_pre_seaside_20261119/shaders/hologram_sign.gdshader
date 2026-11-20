shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec4 holo_colour : source_color = vec4(0.2,0.9,0.9,1.0);
uniform float strength = 1.0;
void fragment() {
	vec2 uv=UV;
	float scan=0.55+0.45*step(0.5,fract(uv.y*38.0-TIME*0.6));
	float edge=smoothstep(0.0,0.06,uv.x)*smoothstep(1.0,0.94,uv.x)*smoothstep(0.0,0.08,uv.y)*smoothstep(1.0,0.92,uv.y);
	float frame=1.0-edge;
	float flicker=0.92+0.08*sin(TIME*23.0)+0.04*sin(TIME*7.3);
	float a=(0.16*scan*edge+0.85*frame)*flicker;
	ALBEDO=holo_colour.rgb*strength*a*2.2;
	ALPHA=1.0;
}
