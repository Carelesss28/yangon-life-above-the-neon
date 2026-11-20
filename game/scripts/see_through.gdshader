shader_type canvas_item;
// Cuts a dithered see-through circle into a building when the player walks behind it.

uniform vec2 hole_center = vec2(-99999.0, -99999.0);
uniform float hole_radius = 0.0;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	vec2 d = (world_pos - hole_center) * vec2(1.0, 1.3);
	if (hole_radius > 0.5 && length(d) < hole_radius) {
		vec2 cell = floor(world_pos);
		// checkerboard dither keeps the pixel-art look
		if (mod(cell.x + cell.y, 2.0) < 1.0 || length(d) < hole_radius * 0.75) {
			c.a *= 0.18;
		}
	}
	COLOR = c;
}
