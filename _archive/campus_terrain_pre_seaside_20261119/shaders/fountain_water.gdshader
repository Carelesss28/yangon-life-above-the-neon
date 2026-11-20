shader_type spatial;
render_mode cull_disabled;

uniform bool stream = false;

void fragment() {
	vec3 turquoise = vec3(0.075, 0.43, 0.49);
	vec3 pale = vec3(0.57, 0.91, 0.94);
	if (stream) {
		float pulse = smoothstep(0.14, 0.85, sin(UV.x * 48.0 - TIME * 12.0 + UV.y * 6.28));
		ALBEDO = mix(turquoise, pale, 0.52 + 0.48 * pulse);
		EMISSION = pale * 0.10;
	} else {
		float distance_to_center = length(UV - vec2(0.5)) * 2.0;
		float ripple = smoothstep(0.81, 0.99, sin(distance_to_center * 33.0 - TIME * 3.5));
		float movement = sin(UV.x * 28.0 + UV.y * 21.0 + TIME) * 0.5 + 0.5;
		ALBEDO = mix(turquoise, pale, 0.1 * movement + 0.32 * ripple);
		EMISSION = turquoise * 0.09;
	}
	ROUGHNESS = 0.29;
	SPECULAR = 0.6;
}
