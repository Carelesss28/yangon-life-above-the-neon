shader_type spatial;
render_mode cull_disabled;

uniform vec4 shallow_color : source_color = vec4(0.20, 0.78, 0.84, 1.0);
uniform vec4 deep_color : source_color = vec4(0.09, 0.59, 0.73, 1.0);
uniform vec4 foam_color : source_color = vec4(0.80, 0.96, 0.98, 1.0);
uniform int water_kind = 0; // 1 river, 2 pool/lake, 3 stream
uniform bool channel_flow = false;
uniform vec2 flow_direction = vec2(1.0, 0.0);
uniform float flow_speed = 0.65;
uniform float wave_height = 0.03;
uniform float opacity = 1.0; // Legacy callers may still supply this; surface stays opaque.
uniform vec4 river_rocks[12]; // x, z, approximate visible radius, enabled
varying vec3 water_world;
varying vec3 water_normal;
varying float edge_anchor;

void vertex() {
	water_world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	water_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
	if (water_normal.y<0.0) water_normal=-water_normal;
	edge_anchor=COLOR.r;
	if (channel_flow || water_kind==3) edge_anchor=smoothstep(0.0,0.15,UV.x)*(1.0-smoothstep(0.85,1.0,UV.x));
	float ripple=sin(water_world.x*0.28+water_world.z*0.17-TIME*0.8)*0.65;
	ripple+=sin(water_world.x*-0.19+water_world.z*0.31-TIME*0.56)*0.35;
	VERTEX+=(inverse(MODEL_MATRIX)*vec4(0.0,ripple*wave_height*edge_anchor,0.0,0.0)).xyz;
}

void fragment() {
	vec2 direction=normalize(flow_direction+vec2(0.00001));
	vec2 side=vec2(-direction.y,direction.x);
	float along=dot(water_world.xz,direction)-TIME*flow_speed;
	float across=dot(water_world.xz,side);
	float shore=0.0;
	float stripes=0.0;
	float foam=0.0;
	if (water_kind==1) {
		shore=min(UV.y,1.0-UV.y);
	} else if (water_kind==2) {
		shore=(1.0-length((UV-0.5)*2.0))*0.35;
	} else if (channel_flow || water_kind==3) {
		shore=min(UV.x,1.0-UV.x);
		along=UV.y-TIME*flow_speed;
		across=UV.x*2.0;
	} else { shore=0.25; }
	float bend=across*0.57+sin(along*0.10)*0.65+sin(along*0.21+across*0.15)*0.28;
	float line=1.0-smoothstep(0.025,0.10,abs(sin(bend)));
	float segments=smoothstep(-0.10,0.60,sin(along*0.13+floor(across*0.18)*2.37));
	stripes=line*segments*0.48;
	if (water_kind==2) {
		float patch=smoothstep(0.10,0.65,sin(along*0.17+across*0.21));
		patch*=smoothstep(-0.10,0.70,sin(across*0.19-along*0.09));
		stripes=line*patch*0.16;
	}
	if (channel_flow || water_kind==3) {
		stripes=(1.0-smoothstep(0.025,0.13,abs(sin(UV.x*16.0+sin(along*0.7)*0.6))))*0.28;
	}
	float wandering=0.008+sin(along*0.4)*0.0025+sin(along*0.17-TIME*0.18)*0.002;
	foam=(1.0-smoothstep(0.004,0.016,abs(shore-wandering)))*0.74;
	foam*=smoothstep(-0.6,0.2,sin(along*0.23)+0.45);
	if (water_kind==1) {
		for(int i=0;i<12;i++) {
			vec4 rock=river_rocks[i];
			vec2 relative=water_world.xz-rock.xy-direction*0.5;
			float radius=length(relative/vec2(1.35,1.0))/max(rock.z,0.1);
			float ring=1.0-smoothstep(0.04,0.18,abs(radius-1.55-sin(TIME*0.6-radius*0.8)*0.05));
			ring*=smoothstep(-0.6,0.35,sin(atan(relative.y,relative.x)+0.5));
			foam=max(foam,ring*rock.w*0.62);
		}
	}
	float shallow=1.0-smoothstep(0.0,0.15,shore);
	float broad_variation=sin(along*0.055+across*0.14)*sin(across*0.2)*0.025;
	vec3 base=mix(deep_color.rgb,shallow_color.rgb,shallow*0.75+0.12);
	ALBEDO=mix(base+vec3(broad_variation*0.25,broad_variation,broad_variation),foam_color.rgb,max(stripes,foam));
	vec3 tilt=vec3(cos(water_world.x*0.28-TIME*0.8)*0.018,0.0,sin(water_world.z*0.31-TIME*0.56)*0.018);
	NORMAL=normalize((VIEW_MATRIX*vec4(normalize(water_normal+tilt),0.0)).xyz);
	ROUGHNESS=0.38;
	SPECULAR=0.40;
	METALLIC=0.0;
}
