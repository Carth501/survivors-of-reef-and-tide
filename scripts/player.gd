extends RigidBody3D

signal entered_water
signal exited_water

var velocity: Vector3 = Vector3.ZERO
var underwater: bool = false
@export var underwater_drag: float = 8.0
@export var overwater_drag: float = 1.0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_on_mouse_motion(event)

func _physics_process(_delta: float) -> void:
	handle_water_state()
	if underwater:
		if Input.is_action_pressed("forward"):
			velocity += Vector3.FORWARD
		if Input.is_action_pressed("back"):
			velocity += Vector3.BACK
		if Input.is_action_pressed("left"):
			velocity += Vector3.LEFT
		if Input.is_action_pressed("right"):
			velocity += Vector3.RIGHT
		if Input.is_action_pressed("ascend"):
			velocity += Vector3.UP
		if Input.is_action_pressed("descend"):
			velocity += Vector3.DOWN
	velocity = velocity.normalized() * 100.0
	# rotate the velocity vector to be relative to the player's current orientation
	velocity = transform.basis * velocity
	apply_central_force(velocity)
	velocity = Vector3.ZERO
	# always try to stay upright. Apply a torque to counteract any rotation around the X and Z axes

func _ready() -> void:
	# capture mouse for camera control
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	underwater = OceanServiceSingle.is_point_underwater(global_position, 0.5)

func _on_mouse_motion(event: InputEventMouseMotion) -> void:
	# the camera is static, relative to the player, so we only rotate the player, not the camera
	var rotation_speed = 0.01
	apply_torque_impulse(Vector3.UP * -event.relative.x * rotation_speed)

func handle_water_state() -> void:
	if OceanServiceSingle.is_point_underwater(global_position, 0.5):
		if !underwater:
			entered_water.emit()
			underwater = true
			toggle_underwater(true)
	else:
		if underwater:
			exited_water.emit()
			underwater = false
			toggle_underwater(false)

func toggle_underwater(is_underwater: bool) -> void:
	if is_underwater:
		gravity_scale = 0
		linear_damp = underwater_drag
	else:
		gravity_scale = 9.81
		linear_damp = overwater_drag
