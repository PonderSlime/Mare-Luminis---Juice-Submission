extends CharacterBody3D

@export var speed = 2.
@export var acceleration = 5.
@export var rotation_speed = 20
@export var buoyancy_force = 5.
@export var bobbing_amplitude = 1.5
@export var bobbing_speed = 1.0
@export var water_drag = 0.1
@export var rotation_smoothness = 10.
@export var camera_boom_origin: Node3D

var velocity_vector: Vector3 = Vector3.ZERO
var rotation_target: Vector3 = Vector3.ZERO

var base_height = 0.
var time_elapsed = 0.

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	PlayerCore.player = self
func _process(delta: float) -> void:
	
	handle_movement(delta)
	handle_rotation(delta)
	apply_buoyancy(delta)
	
func _physics_process(delta: float) -> void:
	PlayerCore.current_depth = snapped(-global_transform.origin.y, 0.1)
	

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		var interactables = get_tree().get_nodes_in_group("interactables")
		for obj in interactables:
			if obj.player_in_range:
				obj.interact()

func handle_movement(delta):
	var input_dir = Vector3.ZERO
	
	if Input.is_action_pressed("move_forward"):
		input_dir += transform.basis.z
	if Input.is_action_pressed("move_backward"):
		input_dir -= transform.basis.z
	if Input.is_action_pressed("move_up"):
		input_dir += transform.basis.y
	if Input.is_action_pressed("move_down"):
		input_dir -= transform.basis.y

	if input_dir != Vector3.ZERO:
		velocity_vector = velocity_vector.lerp(input_dir.normalized() * speed, acceleration * delta)
		camera_boom_origin.update_fov(77)
	else:
		velocity_vector = velocity_vector.lerp(Vector3.ZERO, acceleration * delta)
		camera_boom_origin.update_fov(75)
		
	velocity = velocity_vector
	move_and_slide()
	global_position.y = clamp(global_position.y, -INF, PlayerCore.ocean_height - 0.3)
func handle_rotation(delta):
	var rot_x = 0.0
	var rot_y = 0.0
	
	if Input.is_action_pressed("turn_left"):
		rot_y += 2
	if Input.is_action_pressed("turn_right"):
		rot_y -= 2
		
	if rot_y != 0:
		rotation_target.y += rot_y * rotation_speed * delta
		
	rotation.y = lerp_angle(rotation.y, deg_to_rad(rotation_target.y), delta * rotation_smoothness)
	if rot_y == 0:
		rotation_target.y = rad_to_deg(rotation.y)
	
func apply_buoyancy(delta):
	time_elapsed += delta
	
	var bobbing_offset = sin(time_elapsed + bobbing_speed) * bobbing_amplitude
	
	var target_y = base_height + bobbing_offset
	var buoyancy = (base_height + bobbing_offset) - global_transform.origin.y
	
	velocity.y += bobbing_offset * delta * buoyancy_force
	
	move_and_slide() 
