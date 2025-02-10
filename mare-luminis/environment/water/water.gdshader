shader_type spatial;
render_mode cull_disabled;
global uniform vec3 ocean_pos; // Global shader value for the player position

uniform sampler2D DEPTH_TEXTURE: hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

uniform vec3 albedo : source_color = vec3(0.0,0.32,0.43);
uniform vec3 albedo2 : source_color = vec3(0.0,0.47,0.76);
uniform float metallic : hint_range(0.0, 1.0) = 0;
uniform float roughness : hint_range(0.0, 1.0) = 0.02;
uniform sampler2D wave; // Noise wave texture
uniform sampler2D wave_bump; // Normal bump map version of the noise wave texture
uniform sampler2D texture_normal; // Additional normal noise
uniform sampler2D texture_normal2; // Additional normal noise

uniform float texture_normal_strength : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float texture_normal2_strength : hint_range(0.0, 1.0, 0.01) = 0.25;

uniform vec2 wave_direction = vec2(0.5,-0.2); // Direction of wave 1
uniform vec2 wave_direction2 = vec2(-0.5,0.5); // Direction of wave 2
uniform float time_scale : hint_range(0.0, 0.2, 0.005) = 0.1; // Rate of movement multiplied by TIME

uniform float noise_scale = 20.0; // Scale of the wave noise texture
uniform float height_scale = 2.0; // Mulitply the normal height values

// Depth color
uniform vec3 color_deep : source_color = vec3(0.11,0.29,0.33); // Deep depth color
uniform vec3 color_shallow : source_color = vec3(0.0,0.47,0.76); // Shallow depth color
//uniform float beers_law = 2.0; // Beer's law application
uniform float depth_offset = 1.5; // Offset

// Edge detection
uniform float edge_scale = 0.3;
uniform float near = 1.0;
uniform float far = 100.0;
uniform vec3 edge_color : source_color = vec3(1.0,1.0,1.0);

// Varying variables
varying float height;
varying vec3 world_pos;
varying float vertex_distance;
varying float vertex_distance_clamped;
varying vec2 vertex_pos;

uniform float depth_distance : hint_range(0.0, 20.0, 0.1) = 4.0;
uniform float beers_law : hint_range(0.0, 20.0, 0.1) = 12.0;
uniform float water_transparency : hint_range(-0.5, 1.0, 0.1) = 0.0;

uniform float refraction_strength : hint_range(0.0, 8.0, 0.001) = 0.5;

float fresnel(float amount, vec3 normal, vec3 view){
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

float edge(float depth){
	depth = 2.0 * depth - 1.0;
	return near * far / (far + depth * (near - far));
}

float waveheight(vec2 offset, int mode) {
	float h1 = 0.0; // Wave1 texture height
	float h2 = 0.0; // Wave2 texture height
	float hmix = 0.0; // Wave texture heights mixed
	switch (mode) {
		case 0: // For getting only the Wave1 height
			h1 = texture(wave, (world_pos.xz + offset) / noise_scale + (TIME * wave_direction) * time_scale).r;
			return h1;
		case 1: // For getting only the Wave2 height
			h2 = texture(wave, (world_pos.xz + offset) / noise_scale + (TIME * wave_direction2) * time_scale).r;
			return h2;
		case 2: // For getting both Wave1 and Wave2 heights and getting the average
			h1 = texture(wave, (world_pos.xz + offset) / noise_scale + (TIME * wave_direction) * time_scale).r;
			h2 = texture(wave, (world_pos.xz + offset) / noise_scale + (TIME * wave_direction2) * time_scale).r;
			hmix = mix(h1, h2, 0.5);
			return hmix;
	}
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vertex_distance = distance(world_pos,ocean_pos);
	vertex_distance = clamp(vertex_distance, 0.0, 85.0);
	vertex_distance_clamped = vertex_distance / 85.0;

	float prev_height_x = waveheight(vec2(-0.3,0.0),2);
	float next_height_x = waveheight(vec2(0.3,0.0),2);
	float prev_height_y = waveheight(vec2(0.0,-0.3),2);
	float next_height_y = waveheight(vec2(0.0,0.3),2);
	float height_mix = waveheight(vec2(0.0,0.0),2);

	VERTEX.y += height_mix * height_scale * (1.0 - vertex_distance_clamped);

	float fraction_x = fract(round(UV.x * 1000.0) / 10.0);
	float fraction_y = fract(round(UV.y * 1000.0) / 10.0);
	if (fraction_x != 0.0) {
		if (fract(UV.y) == 0.0) {
			VERTEX.y = ((prev_height_x + next_height_x) * height_scale * (1.0 - vertex_distance_clamped)) / 2.0;
		}
	}
	if (fraction_y != 0.0) {
		if (fract(UV.x) == 0.0) {
			VERTEX.y = ((prev_height_y + next_height_y) * height_scale * (1.0 - vertex_distance_clamped)) / 2.0;
		}
	}
}

void fragment() {
	// Time calculations for wave (normal map) movement
	vec2 time = (TIME * wave_direction) * time_scale; // Movement rate of first wave
	vec2 time2 = (TIME * wave_direction2) * time_scale; // Movement rate of second wave

	// Blend normal maps into one
	vec3 normal_blend = mix(texture(texture_normal, world_pos.xz / 10.0 + time / 10.0).rgb, texture(texture_normal2, world_pos.xz / 10.0 + time2 / 10.0).rgb, 0.5);

	vec3 normalmap = texture(texture_normal, world_pos.xz / 10.0 + time / 10.0).rgb * texture_normal_strength;
	normalmap += texture(texture_normal2, world_pos.xz / 10.0 + time2 / 10.0).rgb * texture_normal2_strength;

	vec3 ref_normalmap = normalmap * 2.0 - (texture_normal_strength + texture_normal2_strength);
	vec3 ref_normal = mix(NORMAL, TANGENT * ref_normalmap + BINORMAL * ref_normalmap + NORMAL * ref_normalmap, 1.0);
	vec2 ref_ofs = SCREEN_UV - ref_normal.xy * refraction_strength;

	float depth_clean = textureLod(DEPTH_TEXTURE, SCREEN_UV, 0.0).r;
	float depth = textureLod(DEPTH_TEXTURE, ref_ofs, 0.0).r;
	vec3 screen = textureLod(SCREEN_TEXTURE, ref_ofs, 0.0).rgb;

	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec3 ndc_clean = vec3(SCREEN_UV * 2.0 - 1.0, depth_clean);

	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z + VERTEX.z;

	vec4 world; // = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);

	if (linear_depth < 0.00001) {
		world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc_clean, 1.0);
	}
	else {
		world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	}

	float depth_texture_y = world.y / world.w;
	float vertex_y = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).y;

	float depth_blend = clamp((vertex_y - depth_texture_y) / depth_distance, 0.0, 1.0);
	depth_blend = exp(-depth_blend * beers_law);
	// Depth variables and calc
	//float depth_texture = texture(DEPTH_TEXTURE, SCREEN_UV).r * 2.0 - 1.0;
	//float depth = PROJECTION_MATRIX[3][2] / (depth_texture + PROJECTION_MATRIX[2][2]);
	//float depth_blend = exp((depth+VERTEX.z + depth_offset) * -beers_law);
	//depth_blend = clamp(1.0 - depth_blend, 0.0, 1.0);
	//float depth_blend_power = clamp(pow(depth_blend, 2.5), 0.0, 1.0);

	vec3 depth_color = mix(albedo, albedo2, depth_blend).rgb;

	// Retrieving depth color and applying the deep and shallow colors
	vec3 screen_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, depth_blend * 2.5).rgb;
	//vec3 depth_color = mix(color_shallow.rgb, color_deep.rgb, depth_blend_power);
	vec3 color = mix(screen_color * depth_color, depth_color * 0.25, depth_blend * 0.5);

	// Getting edge depth calc
	float z_depth = edge(texture(DEPTH_TEXTURE, SCREEN_UV).x);
	float z_pos = edge(FRAGCOORD.z);
	float z_dif = z_depth - z_pos;

	// Blend Wave1 and Wave2 maps
	vec3 wave_normal_blend = mix(texture(wave_bump, world_pos.xz / noise_scale + time).xyz,texture(wave_bump, world_pos.xz / noise_scale + time2).xyz,0.3);

	// Calculate Fresnel
	float fresnel = fresnel(5.0, NORMAL, VIEW);
	vec3 surface_color = mix(albedo, albedo2, fresnel); // Interpolate albedo values by frensel

	// Add Edge Color to Surface Color Albedo
	vec3 depth_color_adj = mix(edge_color, color, step(edge_scale, z_dif));
	vec3 main_color = clamp(surface_color + depth_color_adj,vec3(0.0),vec3(1.0));

	vec3 refraction_texture; //= textureLod(SCREEN_TEXTURE, ref_ofs, ROUGHNESS * 2.0).rgb;
	if (linear_depth < 0.00001) {
		refraction_texture = textureLod(SCREEN_TEXTURE, SCREEN_UV, ROUGHNESS * 2.0).rgb;
	}
	else {
		refraction_texture = textureLod(SCREEN_TEXTURE, ref_ofs, ROUGHNESS * 2.0).rgb;
	}

	vec3 final_color = mix(depth_color, refraction_texture, water_transparency * depth_blend);

	ALBEDO = mix(final_color, screen, depth_blend * (1.0 - fresnel));
	METALLIC = metallic;
	ROUGHNESS = roughness;
	NORMAL_MAP = mix(wave_normal_blend, normal_blend, 0.5);
	SPECULAR = wave_normal_blend.r;
}