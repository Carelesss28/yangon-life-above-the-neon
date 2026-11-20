shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque;
void fragment() {
	float flow=UV.y*35.0-TIME*4.5;
	float streak=sin(flow+sin(UV.x*39.0))*0.5+0.5;
	float foam=smoothstep(0.25,0.85,streak)*0.28;
	ALBEDO=mix(vec3(0.12,0.28,0.32),vec3(0.7,0.84,0.84),foam+0.22);
	ROUGHNESS=0.25;
	SPECULAR=0.7;
	ALPHA=0.6+foam;
}
