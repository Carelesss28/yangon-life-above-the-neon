shader_type spatial;
// Screen-space ink outlines from depth and normal discontinuities (anime render layer).
// Drawn on a camera-attached quad; lines fade with distance so the far town stays soft.
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled, shadows_disabled;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform sampler2D normal_tex : hint_normal_roughness_texture, filter_nearest;
uniform vec4 line_colour : source_color = vec4(0.10,0.08,0.16,1.0);
uniform float depth_threshold = 0.035;
uniform float normal_threshold = 0.42;
uniform float strength = 0.82;
uniform float fade_start = 120.0;
uniform float fade_end = 420.0;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float linear_depth(vec2 uv, mat4 inv_projection) {
	float d = texture(depth_tex, uv).r;
	vec4 view = inv_projection * vec4(uv * 2.0 - 1.0, d, 1.0);
	return -view.z / view.w;
}

vec3 view_normal(vec2 uv) {
	return normalize(texture(normal_tex, uv).xyz * 2.0 - 1.0);
}

void fragment() {
	vec2 px = 1.0 / VIEWPORT_SIZE;
	float centre = linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
	vec3 n = view_normal(SCREEN_UV);
	float depth_edge = 0.0;
	float normal_edge = 0.0;
	vec2 offsets[4] = vec2[](vec2(1.0, 0.0), vec2(-1.0, 0.0), vec2(0.0, 1.0), vec2(0.0, -1.0));
	for (int i = 0; i < 4; i++) {
		vec2 uv = SCREEN_UV + offsets[i] * px;
		float d = linear_depth(uv, INV_PROJECTION_MATRIX);
		depth_edge = max(depth_edge, (centre - d) / max(centre, 0.001));
		normal_edge = max(normal_edge, 1.0 - dot(n, view_normal(uv)));
	}
	float edge = max(step(depth_threshold, depth_edge), step(normal_threshold, normal_edge) * 0.75);
	edge *= 1.0 - smoothstep(fade_start, fade_end, centre);
	ALBEDO = line_colour.rgb;
	ALPHA = edge * strength;
}
