class_name OceanService
extends Node

@export var base_height: float = -4.0
@export var enable_waves: bool = false
@export var wave_a_direction: Vector2 = Vector2(1.0, 0.35)
@export var wave_a_amplitude: float = 0.35
@export var wave_a_frequency: float = 0.08
@export var wave_a_speed: float = 0.7
@export var wave_b_direction: Vector2 = Vector2(-0.55, 1.0)
@export var wave_b_amplitude: float = 0.2
@export var wave_b_frequency: float = 0.13
@export var wave_b_speed: float = 1.05
@export var wave_c_direction: Vector2 = Vector2(0.8, -0.45)
@export var wave_c_amplitude: float = 0.12
@export var wave_c_frequency: float = 0.19
@export var wave_c_speed: float = 1.45

var wave_time: float = 0.0

func _process(delta: float) -> void:
	wave_time += delta

func get_surface_height(x: float, z: float) -> float:
	return base_height + _get_wave_displacement(x, z)

func get_water_height_at(position: Vector2) -> float:
	return get_surface_height(position.x, position.y)

func get_surface_height_at_world(position: Vector3) -> float:
	return get_surface_height(position.x, position.z)

func is_point_underwater(point: Vector3, margin: float = 0.0) -> bool:
	return point.y < get_surface_height(point.x, point.z) - margin

func get_shader_params() -> Dictionary:
	return {
		"base_height": base_height,
		"enable_waves": enable_waves,
		"wave_time": wave_time,
		"wave_a_direction": _get_normalized_direction(wave_a_direction),
		"wave_a_amplitude": wave_a_amplitude,
		"wave_a_frequency": wave_a_frequency,
		"wave_a_speed": wave_a_speed,
		"wave_b_direction": _get_normalized_direction(wave_b_direction),
		"wave_b_amplitude": wave_b_amplitude,
		"wave_b_frequency": wave_b_frequency,
		"wave_b_speed": wave_b_speed,
		"wave_c_direction": _get_normalized_direction(wave_c_direction),
		"wave_c_amplitude": wave_c_amplitude,
		"wave_c_frequency": wave_c_frequency,
		"wave_c_speed": wave_c_speed,
	}

func _get_wave_displacement(x: float, z: float) -> float:
	if not enable_waves:
		return 0.0

	var sample_position := Vector2(x, z)
	return (
		_get_wave_component(sample_position, _get_normalized_direction(wave_a_direction), wave_a_amplitude, wave_a_frequency, wave_a_speed)
		+ _get_wave_component(sample_position, _get_normalized_direction(wave_b_direction), wave_b_amplitude, wave_b_frequency, wave_b_speed)
		+ _get_wave_component(sample_position, _get_normalized_direction(wave_c_direction), wave_c_amplitude, wave_c_frequency, wave_c_speed)
	)

func _get_wave_component(sample_position: Vector2, direction: Vector2, amplitude: float, frequency: float, speed: float) -> float:
	if amplitude == 0.0 or frequency == 0.0:
		return 0.0

	var phase := sample_position.dot(direction) * frequency + wave_time * speed
	return sin(phase) * amplitude

func _get_normalized_direction(direction: Vector2) -> Vector2:
	if direction == Vector2.ZERO:
		return Vector2.RIGHT
	return direction.normalized()
