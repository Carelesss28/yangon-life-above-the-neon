shader_type spatial;
varying vec3 ground_pos;
varying vec3 ground_normal;
float hash21(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise2(vec2 p) {
	vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);
}
void vertex() {
	ground_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	ground_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
	// Visual recesses expose the imported stair geometry. Collision stays unchanged.
	bool campus=(abs(ground_pos.x-50.0)<4.0 || abs(ground_pos.x-150.0)<4.0 || abs(ground_pos.x-250.0)<4.0) && (abs(ground_pos.z-80.0)<=4.0 || abs(ground_pos.z-210.0)<=4.0);
	bool waterfront=(abs(ground_pos.x+30.0)<3.5 || abs(ground_pos.x-150.0)<3.5 || abs(ground_pos.x-520.0)<3.5) && ground_pos.z>=624.0 && ground_pos.z<=650.0;
	if(campus || waterfront) VERTEX.y-=2.0;

}
void fragment() {
	vec2 p=ground_pos.xz;
	float patch=noise2(p*0.075)*0.60+noise2(p*0.23)*0.28+noise2(p*0.85)*0.12;
	float grain=noise2(p*9.0);
	vec3 damp=vec3(0.085,0.135,0.092);
	vec3 meadow=vec3(0.16,0.215,0.105);
	vec3 grass=mix(damp,meadow,smoothstep(0.18,0.85,patch));
	grass*=0.84+grain*0.30;
	// Worn, dry and clover patches break up the lawn.
	float dry=smoothstep(0.62,0.82,noise2(p*0.12+31.0));
	grass=mix(grass,vec3(0.22,0.21,0.11),dry*0.55);
	float clover=smoothstep(0.7,0.85,noise2(p*0.45+5.0));
	grass=mix(grass,vec3(0.12,0.26,0.13),clover*0.4);
	float mow=0.5+0.5*sin((p.x+p.y*0.35)*0.9);
	grass*=0.96+mow*0.08;
	float slope=1.0-smoothstep(0.55,0.88,ground_normal.y);
	vec3 earth=mix(vec3(0.09,0.083,0.065),vec3(0.16,0.145,0.105),noise2(p*0.4));
	ALBEDO=mix(grass,earth,slope*0.88);
	float riverbank=685.0+7.0*sin(p.x*0.012)+3.0*sin(p.x*0.032);
	float riverwidth=65.0+7.0*sin(p.x*0.016+1.0);
	bool riverbed=p.y>riverbank-1.0 && p.y<riverbank+riverwidth+5.0 && ground_pos.y< -1.0;
	bool lakebed=length((p-vec2(550.0,548.0))/vec2(46.0,43.0))<1.15 && ground_pos.y< -2.0;
	if(riverbed || lakebed) ALBEDO=mix(vec3(0.22,0.245,0.26),vec3(0.245,0.265,0.28),noise2(p*1.4));
	ROUGHNESS=0.97;
}
