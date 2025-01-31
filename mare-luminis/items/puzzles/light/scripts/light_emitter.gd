extends Node3D

@export var max_distance = 10.
@export var light_color: Color = Color(1, 1, 0)
@export var beam_width = 0.1
@export var active = true

var raycast: RayCast3D
var beam_mesh: MeshInstance3D

var hit_object

func _ready() -> void:
	raycast = RayCast3D.new()
	raycast.target_position = Vector3.FORWARD * max_distance
	raycast.enabled = true
	raycast.set_collision_mask_value(1, false)
	raycast.set_collision_mask_value(3, true)
	add_child(raycast)
	
	beam_mesh = MeshInstance3D.new()
	beam_mesh.mesh = create_beam_mesh()
	add_child(beam_mesh)
	
func _process(delta: float) -> void:
	if active:
		cast_light()
		
func cast_light():
	raycast.force_raycast_update()

	if raycast.is_colliding():
		hit_object = raycast.get_collider()
		if hit_object.has_method("receive_light"):
			print("Light received by: ", hit_object.name)
			hit_object.receive_light(true)
		elif hit_object.has_method("update_bounce_vars"):
			var normal = raycast.get_collision_normal()
			var point = raycast.get_collision_point()
			hit_object.update_bounce_vars(normal, point, raycast, true)
	elif !raycast.is_colliding():
		if hit_object:
			if hit_object.has_method("receive_light"):
				hit_object.receive_light(false)
			elif hit_object.has_method("update_bounce_vars"):
				hit_object.update_bounce_vars(null, null, null, false)

		else:
			pass
	update_beam_visual()
	
func update_beam_visual():
	var end_pos = raycast.get_collision_point() if raycast.is_colliding() else global_transform.origin + global_transform.basis.z * max_distance
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
