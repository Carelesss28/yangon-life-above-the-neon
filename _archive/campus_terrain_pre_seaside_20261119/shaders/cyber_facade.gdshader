shader_type spatial;
// Procedural facade for infill buildings: composite panels, glazing grid, per-window lighting.
// Window light is emission controlled by the day/night switch; no light or shadow is painted in.
uniform vec3 wall_colour : source_color = vec3(0.3,0.33,0.36);
uniform vec3 size = vec3(10.0,12.0,10.0);
uniform float night = 1.0;
uniform float seed = 0.0;
uniform float lit_ratio = 0.55;
varying vec3 local_pos;
varying vec3 local_normal;
float hash(vec3 p) { return fract(sin(dot(p,vec3(12.9898,78.233,37.719)))*43758.5453); }
void vertex() {
	local_pos=VERTEX;
	local_normal=NORMAL;
}
void fragment() {
	vec3 n=abs(local_normal);
	vec3 colour=wall_colour;
	vec3 emit=vec3(0.0);
	float metal=0.0;
	if(n.y<0.5) {
		bool side=n.x>n.z;
		float u=side?local_pos.z+size.z*0.5:local_pos.x+size.x*0.5;
		float h=local_pos.y+size.y*0.5;
		float face=side?sign(local_normal.x):2.0*sign(local_normal.z);
		float bay=2.4;
		float storey=3.1;
		vec2 cell=vec2(floor(u/bay),floor(h/storey));
		vec2 f=vec2(fract(u/bay),fract(h/storey));
		float win=step(0.14,f.x)*step(f.x,0.86)*step(0.26,f.y)*step(f.y,0.84);
		// Leave a solid band at the very top under the parapet.
		win*=step(h,size.y-1.0);
		float r=hash(vec3(cell,face+seed));
		float lit=step(1.0-lit_ratio,r);
		float pick=hash(vec3(cell+3.1,face-seed));
		vec3 warm=mix(vec3(1.0,0.6,0.28),vec3(1.0,0.8,0.52),hash(vec3(cell.yx,seed)));
		vec3 cool=vec3(0.42,0.82,1.0);
		vec3 pink=vec3(1.0,0.32,0.68);
		vec3 window_colour=pick<0.62?warm:(pick<0.87?cool:pink);
		vec3 glass=vec3(0.06,0.09,0.12);
		colour=mix(colour,glass,win);
		metal=win*0.3;
		// Panel seams per storey and a vertical seam per bay.
		float seam=max(step(0.965,f.y),step(0.975,f.x));
		colour*=1.0-seam*(1.0-win)*0.35;
		// Slight weathering streaks below each window.
		float streak=(1.0-win)*step(0.3,f.x)*step(f.x,0.7)*step(f.y,0.26)*hash(vec3(cell,9.0))*0.25;
		colour*=1.0-streak;
		emit=window_colour*win*lit*night*0.9;
	} else {
		colour*=0.62;
	}
	ALBEDO=colour;
	EMISSION=emit;
	METALLIC=metal;
	ROUGHNESS=mix(0.75,0.25,metal);
}
