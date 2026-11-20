shader_type spatial;
render_mode diffuse_toon, specular_toon;
// Ground: lush toy-town grass on flat land, earth on steep faces, sand at the beach, seabed and
// reservoir beds below water. Matches the shore formula in terrain_layout.gd. No baked light.
varying vec3 ground_pos;
varying vec3 ground_normal;
float hash21(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise2(vec2 p) {
	vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);
}
float shore(float x) { return 185.0+14.0*sin(x*0.009)+8.0*sin(x*0.023+1.0); }
void vertex() {
	ground_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	ground_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
void fragment() {
	vec2 p=ground_pos.xz;
	float patch=noise2(p*0.075)*0.6+noise2(p*0.23)*0.28+noise2(p*0.85)*0.12;
	float grain=noise2(p*9.0);
	vec3 deep=vec3(0.16,0.33,0.13);
	vec3 bright=vec3(0.30,0.48,0.17);
	vec3 grass=mix(deep,bright,smoothstep(0.2,0.85,patch));
	grass*=0.88+grain*0.24;
	float dry=smoothstep(0.64,0.84,noise2(p*0.12+31.0));
	grass=mix(grass,vec3(0.42,0.43,0.2),dry*0.4);
	float clover=smoothstep(0.7,0.86,noise2(p*0.45+5.0));
	grass=mix(grass,vec3(0.2,0.42,0.2),clover*0.35);
	// Higher ground turns to cooler hill meadow.
	grass=mix(grass,vec3(0.2,0.36,0.2),smoothstep(14.0,34.0,ground_pos.y)*0.5);
	float slope=1.0-smoothstep(0.55,0.88,ground_normal.y);
	vec3 earth=mix(vec3(0.33,0.26,0.18),vec3(0.45,0.36,0.24),noise2(p*0.4));
	vec3 colour=mix(grass,earth,slope*0.85);
	float s=shore(p.x);
	if(p.y<s+0.6) {
		vec3 sand=mix(vec3(0.86,0.78,0.58),vec3(0.78,0.69,0.5),noise2(p*0.6));
		vec3 wet_sand=vec3(0.6,0.55,0.42);
		colour=mix(sand,wet_sand,smoothstep(0.4,-0.6,ground_pos.y));
		colour=mix(colour,vec3(0.32,0.42,0.42),smoothstep(-1.2,-3.0,ground_pos.y));
	}
	float res=length((p-vec2(210.0,700.0))/vec2(55.0,40.0));
	float pond=length((p-vec2(1050.0,760.0))/vec2(30.0,22.0));
	if((res<1.05 && ground_pos.y<17.0) || (pond<1.05 && ground_pos.y<5.0))
		colour=mix(vec3(0.4,0.42,0.36),vec3(0.46,0.47,0.4),noise2(p*1.4));
	ALBEDO=colour;
	ROUGHNESS=0.95;
}
