extends Node

@export var player_depth_upgrade_lvl = 0

@export var max_safe_depth = 100.
@export var depth_damage_rate = 5.
@export var warning_depth = 80.

var current_depth: float = 0.0
var taking_damage: bool = false
var warning: bool = false
var item_held = null

var is_in_menu: bool = false

func _process(delta: float) -> void:
	check_depth_pressure(delta)
	
	if !is_in_menu:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif is_in_menu:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func check_depth_pressure(delta):
	if current_depth > max_safe_depth:
		taking_damage = true
		apply_depth_damage(delta)
	elif current_depth < max_safe_depth:
		taking_damage = false
	elif current_depth > warning_depth:
		warning = true
	elif current_depth < warning_depth:
		warning = false

func apply_depth_damage(delta):
	var damage = depth_damage_rate * delta
	print("Taking depth damage:", damage)  # Replace with actual health system call
