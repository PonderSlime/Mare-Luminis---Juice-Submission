extends Node

@export var player_depth_upgrade_lvl = 0

@export var max_safe_pressure = 12
@export var depth_damage_rate = 5.
@export var warning_depth = 80.
@export var warning_pressure = 9

var current_depth: float = 0.0
var pressure := 0.0
var taking_damage: bool = false
var warning: bool = false
var item_held = null

var is_in_menu: bool = false

var player: Node3D = null
var ocean: Node3D = null
var ocean_height: float = 0.0
var camera: Node3D = null

var is_cam_underwater: bool = false
var darkness_rate = 26

func _process(delta: float) -> void:
	check_depth_pressure(delta)
	
	if !is_in_menu:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif is_in_menu:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func _physics_process(delta: float) -> void:
	pressure = snapped(current_depth, 10.06) / 10.06
	ocean.position.x = player.position.x
	ocean.position.z = player.position.z
	
func check_depth_pressure(delta):
	if pressure >  max_safe_pressure:
		taking_damage = true
		apply_depth_damage(delta)
	elif pressure < max_safe_pressure:
		taking_damage = false
	elif pressure > warning_pressure:
		warning = true
	elif pressure < warning_pressure:
		warning = false

func apply_depth_damage(delta):
	var damage = (pressure - max_safe_pressure) * depth_damage_rate * delta
	print("Taking depth damage:", damage)

func enable_underwater_effects(value: bool):
	is_cam_underwater = value
