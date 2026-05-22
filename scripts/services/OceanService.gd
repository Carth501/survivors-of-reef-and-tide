class_name OceanService extends Node

var temporary_water_level: float = 0.0

func get_water_height_at(position: Vector2) -> float:
	# For simplicity, we return a constant water height. In a real implementation, this could be based on a heightmap or procedural generation.
	return temporary_water_level