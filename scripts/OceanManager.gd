extends Node3D

@export var follow_camera: bool = true
@export_range(64.0, 1024.0, 16.0) var surface_extent: float = 256.0
@export_range(0.01, 2.0, 0.01) var transition_hysteresis: float = 0.2
@export var underwater_background_color: Color = Color(0.015, 0.11, 0.145, 1.0)
@export var underwater_fog_color: Color = Color(0.04, 0.21, 0.25, 1.0)
@export_range(0.0, 0.2, 0.001) var underwater_fog_density: float = 0.045
@export_range(0.1, 2.0, 0.01) var underwater_saturation: float = 0.72
@export_range(0.1, 2.0, 0.01) var underwater_contrast: float = 1.06

@onready var water_surface: MeshInstance3D = $WaterSurface
@onready var water_area_shape: CollisionShape3D = $WaterArea/CollisionShape3D

var _ocean_service: OceanService
var _world_environment: WorldEnvironment
var _surface_mesh: PlaneMesh
var _surface_material: ShaderMaterial
var _above_environment: Environment
var _underwater_environment: Environment
var _is_underwater: bool = false

func _ready() -> void:
	_ocean_service = get_node_or_null("/root/OceanService") as OceanService
	_world_environment = get_parent().get_node_or_null("WorldEnvironment") as WorldEnvironment
	_surface_mesh = water_surface.mesh as PlaneMesh
	_surface_material = water_surface.material_override as ShaderMaterial

	if _ocean_service == null:
		push_warning("OceanService autoload is missing. Add it in Project Settings > Autoload.")
	if _world_environment == null:
		push_warning("WorldEnvironment node is missing from the world scene.")

	_configure_surface()
	_build_environment_variants()
	_sync_runtime_state()

func _process(_delta: float) -> void:
	_sync_runtime_state()

func _configure_surface() -> void:
	if _surface_mesh != null:
		_surface_mesh.size = Vector2.ONE * surface_extent

	var water_shape := water_area_shape.shape as BoxShape3D
	if water_shape != null:
		water_shape.size = Vector3(surface_extent, 256.0, surface_extent)

	var shape_transform := water_area_shape.transform
	shape_transform.origin.y = -128.0
	water_area_shape.transform = shape_transform

func _sync_runtime_state() -> void:
	if _ocean_service == null:
		return

	if _world_environment == null:
		_world_environment = get_parent().get_node_or_null("WorldEnvironment") as WorldEnvironment
		_build_environment_variants()

	var active_camera := get_viewport().get_camera_3d()
	if active_camera == null:
		return

	var manager_position := global_position
	if follow_camera:
		manager_position.x = active_camera.global_position.x
		manager_position.z = active_camera.global_position.z
	manager_position.y = _ocean_service.base_height
	global_position = manager_position

	_update_surface_shader(active_camera)
	_update_underwater_state(active_camera)

func _build_environment_variants() -> void:
	if _world_environment == null:
		return
	if _above_environment != null and _underwater_environment != null:
		return

	var source_environment := _world_environment.environment
	if source_environment == null:
		source_environment = Environment.new()

	_above_environment = source_environment.duplicate(true) as Environment
	_above_environment.fog_enabled = false
	_above_environment.adjustment_enabled = false

	_underwater_environment = _above_environment.duplicate(true) as Environment
	_underwater_environment.background_mode = Environment.BG_COLOR
	_underwater_environment.background_color = underwater_background_color
	_underwater_environment.fog_enabled = true
	_underwater_environment.fog_light_color = underwater_fog_color
	_underwater_environment.fog_density = underwater_fog_density
	_underwater_environment.adjustment_enabled = true
	_underwater_environment.adjustment_brightness = 0.88
	_underwater_environment.adjustment_saturation = underwater_saturation
	_underwater_environment.adjustment_contrast = underwater_contrast

	_apply_environment_state(_is_underwater)

func _update_surface_shader(active_camera: Camera3D) -> void:
	if _surface_material == null:
		return

	var shader_params := _ocean_service.get_shader_params()
	for parameter_name in shader_params.keys():
		_surface_material.set_shader_parameter(parameter_name, shader_params[parameter_name])

	_surface_material.set_shader_parameter("camera_height", active_camera.global_position.y)
	_surface_material.set_shader_parameter("camera_underwater", _is_underwater)

func _update_underwater_state(active_camera: Camera3D) -> void:
	var surface_height := _ocean_service.get_surface_height(active_camera.global_position.x, active_camera.global_position.z)
	var next_underwater := _is_underwater

	if _is_underwater:
		next_underwater = active_camera.global_position.y <= surface_height + transition_hysteresis
	else:
		next_underwater = active_camera.global_position.y < surface_height - transition_hysteresis

	if next_underwater == _is_underwater:
		return

	_is_underwater = next_underwater
	_apply_environment_state(_is_underwater)

func _apply_environment_state(use_underwater_environment: bool) -> void:
	if _world_environment == null:
		return

	if use_underwater_environment and _underwater_environment != null:
		_world_environment.environment = _underwater_environment
	elif _above_environment != null:
		_world_environment.environment = _above_environment