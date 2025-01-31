extends Node3D

signal light_recieved

@export var trigger_action: Callable
@export var lit_color: Color = Color(1, 0, 0)
@export var dark_color: Color = Color(0.5, 0.5, 0.5)
@onready var material: Material = $MeshInstance3D.get_active_material(0)

func _ready() -> void:
	material.albedo_color = dark_color
	material.emission = dark_color
func receive_light(on):
	light_recieved.emit()
	if trigger_action.is_valid():
		trigger_action.call()
		
	if on == true:
		material.albedo_color = lit_color
		material.emission = lit_color
	else:
		material.albedo_color = dark_color
		material.emission = dark_color
