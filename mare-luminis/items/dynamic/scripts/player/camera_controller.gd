extends Node3D

@onready var spring_arm: SpringArm3D = $BoomOrigin/CameraBoom
@onready var boom_origin: Node3D = $BoomOrigin
@onready var camera: Camera3D = $BoomOrigin/CameraBoom/Camera3D
@export var player: CharacterBody3D
@export var camera_sensitivity = 0.05
@export var zoom_speed = 2.0
@export var min_zoom = 2.0
@export var max_zoom = 6.0
@export var zoom_smoothing = 250.0
@export var camera_lag_strength = 6.
@export var camera_tilt_strength = 5.
@export var camera_reset_time = 3.
@export var camera_reset_smoothness = 2.

var camera_free_look = false
var time_since_last_camera_move = 0.0

var camera_angle = Vector2.ZERO
var target_spring_length = 4.


func update_fov(new_fov):
	var tween = create_tween()
	tween.tween_property(camera, "fov", new_fov, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
func _process(delta: float) -> void:
	update_spring_arm(delta)
	update_camera_lag(delta)
	
	if camera_free_look:
		time_since_last_camera_move += delta
		if time_since_last_camera_move >= camera_reset_time:
			reset_camera_to_back(delta)

func _input(event):
	if event is InputEventMouseMotion:
		handle_camera(event.relative)
		camera_free_look = true
		time_since_last_camera_move = 0.0

func handle_camera(mouse_delta: Vector2):
	camera_angle.y = rad_to_deg(spring_arm.rotation.y)
	camera_angle.x = rad_to_deg(spring_arm.rotation.x)
		
	camera_angle.x = clamp(camera_angle.x - mouse_delta.y * camera_sensitivity, -65, 45)
	camera_angle.y -= mouse_delta.x * camera_sensitivity
	
	spring_arm.rotation_degrees.x = camera_angle.x
	spring_arm.rotation_degrees.y = camera_angle.y

	time_since_last_camera_move = 0.0
	
	update_target_zoom()

func update_target_zoom():
	var normalized_angle = (camera_angle.x + 45.0) / 90
	target_spring_length = lerp(max_zoom, min_zoom, normalized_angle)
	
func update_spring_arm(delta):
	spring_arm.spring_length = lerp(spring_arm.spring_length, target_spring_length, delta * zoom_smoothing)

func update_camera_lag(delta):
	global_position = global_position.lerp(player.global_position, delta * (camera_lag_strength * 4))
	global_rotation.x = lerp_angle(global_rotation.x, player.global_rotation.x, delta)
	global_rotation.y = lerp_angle(global_rotation.y, player.global_rotation.y, delta)
	global_rotation.z = lerp_angle(global_rotation.z, player.global_rotation.z, delta)
	
func reset_camera_to_back(delta):
	var target_camera_angle = deg_to_rad(boom_origin.rotation_degrees.y + 180)
	var normalized_angle = fmod(spring_arm.rotation.y, 2 * PI)
	
	if normalized_angle >= 2 * PI:
		normalized_angle = 0.0
	
	spring_arm.rotation.y = lerp_angle_shortest(normalized_angle, target_camera_angle, delta * camera_reset_smoothness)

func lerp_angle_shortest(from, to, weight):
	return from + short_angle_dist(from, to) * weight

func short_angle_dist(from, to):
	var max_angle = PI * 2
	var difference = fmod(to - from, max_angle)
	return fmod(2 * difference, max_angle) - difference
