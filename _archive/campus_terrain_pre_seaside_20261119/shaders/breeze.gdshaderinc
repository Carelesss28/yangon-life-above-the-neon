// Shared broad gusts. Grass, foliage, cloth and water use the same clock/direction.
vec3 town_breeze(vec2 p,float time) {
	float gust=0.68+0.23*sin(time*0.23)+0.09*sin(time*0.071+1.4);
	float sway=sin(dot(p,vec2(0.041,0.027))-time*0.95);
	float flutter=0.22*sin(dot(p,vec2(-0.13,0.17))-time*1.65);
	return vec3(0.91,0.0,0.41)*(sway+flutter)*gust;
}
