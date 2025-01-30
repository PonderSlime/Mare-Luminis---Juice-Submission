extends Control
@onready var compass = $Compass/CompassTexture
@export var camera_boom: SpringArm3D

func _ready() -> void:
	compass.pivot_offset = compass.size / 2

func _process(delta: float) -> void:
	update_compass()
	
func update_compass():
	if compass:
		compass.rotation_degrees = camera_boom.global_rotation_degrees.y + 180
