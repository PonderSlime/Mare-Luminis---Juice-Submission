extends Node3D

@export var max_bounce_distance = 2.5
@export var light_color: Color = Color(1, 1, 0)
@export var beam_width = 0.1
@export var visible_beam_parent: Node3D
@export var active = true

func bounce_light(normal, point, ray):
	var beam_mesh: MeshInstance3D
	var incoming_direction = point - ray.global_transform.origin
	var outgoing_direction = incoming_direction.bounce(normal) * max_bounce_distance
	
	var reflected_raycast = RayCast3D.new()
	reflected_raycast.target_position = outgoing_direction
	
	print(point)
	reflected_raycast.enabled = true
	add_child(reflected_raycast)
	
	reflected_raycast.force_raycast_update()
	_cast_reflected_ray(reflected_raycast)
	
	beam_mesh = MeshInstance3D.new()
	beam_mesh.mesh = create_beam_mesh()
	visible_beam_parent.add_child(beam_mesh)
	update_beam_visual(reflected_raycast, beam_mesh)
			
func _cast_reflected_ray(reflected_raycast):
	if reflected_raycast.is_colliding():
		var hit_object = reflected_raycast.get_collider()
		if hit_object.has_method("receive_light"):
			print("Light received by: ", hit_object.name)
			hit_object.receive_light()
		if hit_object.has_method("bounce_light"):
			hit_object.bounce_light()

func update_beam_visual(raycast, beam_mesh):
	var end_pos = raycast.get_collision_point() if raycast.is_colliding() else global_transform.origin + global_transform.basis.z * max_bounce_distance
	beam_mesh.global_transform.origin = raycast.global_transform.origin
	beam_mesh.rotation_degrees.x = 90
	beam_mesh.scale.y = global_transform.origin.distance_to(end_pos)
	beam_mesh.position.z = - beam_mesh.scale.y / 2

func create_beam_mesh():
	var mesh = CylinderMesh.new()
	mesh.top_radius = beam_width
	mesh.bottom_radius = beam_width
	mesh.height = 1.0
	mesh.material = StandardMaterial3D.new()
	mesh.material.albedo_color = light_color
	return mesh
