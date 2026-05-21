extends RigidBody3D

var velocity: Vector3 = Vector3.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_on_mouse_motion(event)

func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("forward"):
		velocity += Vector3.FORWARD
	if Input.is_action_pressed("back"):
		velocity += Vector3.BACK
	if Input.is_action_pressed("left"):
		velocity += Vector3.LEFT
	if Input.is_action_pressed("right"):
		velocity += Vector3.RIGHT
	if Input.is_action_pressed("ascend"):
		velocity += Vector3.DOWN
	if Input.is_action_pressed("descend"):
		velocity += Vector3.UP
	velocity = velocity.normalized() * 50.0
	# rotate the velocity vector to be relative to the player's current orientation
	velocity = transform.basis * -velocity
	apply_central_force(velocity)
	velocity = Vector3.ZERO
	# always try to stay upright. Apply a torque to counteract any rotation around the X and Z axes

func _ready() -> void:
	# capture mouse for camera control
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_mouse_motion(event: InputEventMouseMotion) -> void:
	# the camera is static, relative to the player, so we only rotate the player, not the camera
	var rotation_speed = 0.005
	print("Mouse motion: ", event.relative)
	apply_torque_impulse(Vector3.UP * -event.relative.x * rotation_speed)