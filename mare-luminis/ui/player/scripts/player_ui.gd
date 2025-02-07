extends Control
@onready var compass = $Compass/CompassTexture
@onready var warning_elem = $Warning
@onready var warning_elem_mat = $Warning.material
@export var camera_boom: SpringArm3D

@export var normal_pulse_intensity = 0.2
@export var normal_pulse_speed = 0.5
@export var warning_pulse_intensity = 0.75
@export var warning_pulse_speed = 3.0
@export var damage_pulse_intensity = 2.0
@export var damage_pulse_speed = 4.0

@onready var inventory_ui = $InventoryUI

var pulse_intensity
var pulse_speed
var inventory_open: bool = false

func _ready() -> void:
	compass.pivot_offset = compass.size / 2
	
	pulse_intensity = normal_pulse_intensity
	pulse_speed = normal_pulse_speed
	warning_elem_mat.set_shader_parameter("pulse_intensity", pulse_intensity)
	warning_elem_mat.set_shader_parameter("pulse_speed", pulse_speed)
func _process(delta: float) -> void:
	update_compass()
	if PlayerCore.taking_damage == true:
		show_pressure_effects()
	else:
		hide_pressure_effects()
	if PlayerCore.warning == true:
		show_warning_effects()
		if PlayerCore.taking_damage == true:
			show_pressure_effects()
		else:
			hide_pressure_effects()
	else:
		hide_warning_effects()
		
	$Label.text = "Depth: " + str(PlayerCore.current_depth)
	
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("open_inventory"):
		toggle_inventory()
	if event is InputEventMouseButton and event.pressed:
		print("Mouse click detected at: ", event.position)
func _unhandled_input(event):
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		get_viewport().set_input_as_handled()

func toggle_inventory():
	if inventory_open && PlayerCore.is_in_menu:
		var tween = create_tween()
		tween.tween_property(inventory_ui, "anchor_left", 1, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		inventory_open = false
		PlayerCore.is_in_menu = true
		
	elif !inventory_open && !PlayerCore.is_in_menu:
		var tween = create_tween()
		tween.tween_property(inventory_ui, "anchor_left", 0.66, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		inventory_open = true
		PlayerCore.is_in_menu = true
		
func update_compass():
	if compass:
		compass.rotation_degrees = camera_boom.global_rotation_degrees.y + 180

func show_pressure_effects():
	pulse_intensity = lerp(pulse_intensity, damage_pulse_intensity, 0.5)
	pulse_speed = lerp(pulse_speed, damage_pulse_intensity, 0.5)
	warning_elem_mat.set_shader_parameter("pulse_intensity", pulse_intensity)
	warning_elem_mat.set_shader_parameter("pulse_speed", pulse_speed)
	
func hide_pressure_effects():
	pulse_intensity = lerp(pulse_intensity, normal_pulse_intensity, 0.5)
	pulse_speed = lerp(pulse_speed, normal_pulse_speed, 0.5)
	warning_elem_mat.set_shader_parameter("pulse_intensity", pulse_intensity)
	warning_elem_mat.set_shader_parameter("pulse_speed", pulse_speed)

func show_warning_effects():
	pulse_intensity = lerp(pulse_intensity, warning_pulse_intensity, 0.5)
	pulse_speed = lerp(pulse_speed, warning_pulse_speed, 0.5)
	warning_elem_mat.set_shader_parameter("pulse_intensity", pulse_intensity)
	warning_elem_mat.set_shader_parameter("pulse_speed", pulse_speed)
	
func hide_warning_effects():
	pulse_intensity = lerp(pulse_intensity, normal_pulse_intensity, 0.5)
	pulse_speed = lerp(pulse_speed, normal_pulse_speed, 0.5)
	warning_elem_mat.set_shader_parameter("pulse_intensity", pulse_intensity)
	warning_elem_mat.set_shader_parameter("pulse_speed", pulse_speed)
