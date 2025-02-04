shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float abberation: hint_range(0.0, 1.5, 0.001) = 0.5;
uniform float strength: hint_range(0.0, 0.1, 0.001) = 0.05;
uniform float pulse_speed = 5.0;
uniform float pulse_intensity = 0.5;

void fragment() {
	vec2 suv = SCREEN_UV;
	float aspect_ratio = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 scaled_suv = (suv - vec2(0.0, 0.5)) / vec2(1.0, aspect_ratio) + vec2(0, 0.5);
	vec2 offset = normalize(scaled_suv) * strength;

	float time_factor = mod(TIME * pulse_speed, 2.0);
	float heartbeat = exp(-pow(time_factor - 0.3, 2.0) * 10.0) + exp(-pow(time_factor - 1.0, 2.0) * 10.0);
	float pulse = heartbeat * pulse_intensity;

	vec2 abberation_vec = offset * abberation * (strength + pulse);

	vec4 red = texture(screen_tex, suv - abberation_vec);
	vec4 green = texture(screen_tex, suv);
	vec4 blue = texture(screen_tex, suv + abberation_vec);


	COLOR = vec4(red.r, green.g, blue.b, 1.0);

}