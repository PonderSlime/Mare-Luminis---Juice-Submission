@tool

extends Node3D

@onready var env = $Env

func _process(delta: float) -> void:
	if PlayerCore.is_cam_underwater:
		env.environment.fog_enabled = true
		env.environment.fog_light_color = Color(0.255, 0.562, 0.883, 1)
		env.environment.volumetric_fog_enabled = true
		env.environment.volumetric_fog_albedo = Color(0.086, 0.663, 0.733, 1.0)
		var depth_darkness = PlayerCore.current_depth / PlayerCore.darkness_rate
		if PlayerCore.current_depth > 0 && depth_darkness > 1:
			env.environment.volumetric_fog_albedo = Color(0.086, 0.663, 0.733, 1.0) / (depth_darkness)
	else:
		env.environment.fog_enabled = false
		env.environment.volumetric_fog_enabled = false
