shader_type spatial;
render_mode blend_mix, cull_disabled, unshaded, world_vertex_coords;

uniform float base_height = -4.0;
uniform bool enable_waves = false;
uniform float wave_time = 0.0;
uniform vec2 wave_a_direction = vec2(1.0, 0.35);
uniform float wave_a_amplitude = 0.35;
uniform float wave_a_frequency = 0.08;
uniform float wave_a_speed = 0.7;
uniform vec2 wave_b_direction = vec2(-0.55, 1.0);
uniform float wave_b_amplitude = 0.2;
uniform float wave_b_frequency = 0.13;
uniform float wave_b_speed = 1.05;
uniform vec2 wave_c_direction = vec2(0.8, -0.45);
uniform float wave_c_amplitude = 0.12;
uniform float wave_c_frequency = 0.19;
uniform float wave_c_speed = 1.45;
uniform vec4 shallow_color : source_color = vec4(0.12, 0.48, 0.58, 0.7);
uniform vec4 deep_color : source_color = vec4(0.03, 0.16, 0.23, 0.82);
uniform vec4 underside_color : source_color = vec4(0.05, 0.23, 0.28, 0.9);
uniform bool camera_underwater = false;
uniform float camera_height = 0.0;

varying float wave_displacement;

float get_wave_component(vec2 sample_position, vec2 direction, float amplitude, float frequency, float speed) {
	if (amplitude == 0.0 || frequency == 0.0) {
		return 0.0;
	}

	float phase = dot(sample_position, normalize(direction)) * frequency + wave_time * speed;
	return sin(phase) * amplitude;
}

float get_wave_displacement_at(vec2 sample_position) {
	if (!enable_waves) {
		return 0.0;
	}

	return get_wave_component(sample_position, wave_a_direction, wave_a_amplitude, wave_a_frequency, wave_a_speed)
		+ get_wave_component(sample_position, wave_b_direction, wave_b_amplitude, wave_b_frequency, wave_b_speed)
		+ get_wave_component(sample_position, wave_c_direction, wave_c_amplitude, wave_c_frequency, wave_c_speed);
}

void vertex() {
	float displacement = get_wave_displacement_at(VERTEX.xz);
	wave_displacement = displacement;
	VERTEX.y = base_height + displacement;
}

void fragment() {
	float wave_blend = clamp(wave_displacement * 0.8 + 0.5, 0.0, 1.0);
	vec4 surface_color = mix(deep_color, shallow_color, wave_blend);

	if (!FRONT_FACING) {
		surface_color = mix(underside_color, shallow_color, 0.12);
	} else if (camera_underwater || camera_height < base_height) {
		surface_color = mix(surface_color, underside_color, 0.15);
	}

	ALBEDO = surface_color.rgb;
	ALPHA = surface_color.a;
	ROUGHNESS = 0.08;
	SPECULAR = 0.65;
}