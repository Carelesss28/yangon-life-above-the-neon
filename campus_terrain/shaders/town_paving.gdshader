shader_type spatial;
render_mode diffuse_toon, specular_toon;
// Warm pale paving: per-tile tone, joints, light wear and the occasional rain puddle. No baked light.
varying vec3 world_pos;
float hash21(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise2(vec2 p) {
	vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);
}
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = world_pos.xz;
	vec2 tile = floor(p / 1.5);
	vec2 f = fract(p / 1.5);
	float joint = step(0.955, f.x) + step(0.955, f.y);
	float tone = 0.92 + hash21(tile) * 0.14;
	float wear = noise2(p * 0.2) * 0.6 + noise2(p * 1.1) * 0.4;
	vec3 base = mix(vec3(0.55,0.53,0.49), vec3(0.5,0.49,0.47), smoothstep(0.35,0.8,wear)) * tone;
	vec3 colour = mix(base, base*0.72, clamp(joint,0.0,1.0));
	float puddle = smoothstep(0.76, 0.81, noise2(p * 0.3 + 11.0));
	colour *= 1.0 - puddle * 0.08;
	ALBEDO = colour;
	ROUGHNESS = mix(0.8, 0.08, puddle);
	SPECULAR = mix(0.4, 0.9, puddle);
}
