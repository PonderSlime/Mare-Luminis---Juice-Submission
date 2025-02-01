extends Node3D

@export var max_bounce_distance = 20.
@export var light_color: Color = Color(1, 1, 0)
@export var beam_width = 0.1
@export var visible_beam_parent: Node3D
@export var active = false
@export var rotation_duration: float = 0.3

var normal
var point
var ray

var beam_mesh: MeshInstance3D
var raycast: RayCast3D

var incoming_direction
var normal_direction
var outgoing_direction

var hit_object = null

func _ready() -> void:
	#visible_beam_parent.global_position = global_position
	raycast = RayCast3D.new()
	raycast.target_position = Vector3.FORWARD * max_bounce_distance
	raycast.enabled = true
	raycast.top_level = true
	raycast.set_collision_mask_value(1, false)
	raycast.set_collision_mask_value(3, true)
	visible_beam_parent.add_child(raycast)
	
	beam_mesh = MeshInstance3D.new()
	beam_mesh.mesh = create_beam_mesh()
	raycast.add_child(beam_mesh)
	
func _process(delta: float) -> void:
	if active:
		bounce_light()
		raycast.enabled = active
		beam_mesh.visible = active
	else:
		raycast.enabled = active
		beam_mesh.visible = active
		
func update_bounce_vars(normal_update, point_update, ray_update, is_active):
	normal = normal_update
	point = point_update
	ray = ray_update
	active = is_active
	if active:
		incoming_direction = point - ray.global_transform.origin
		incoming_direction = incoming_direction.normalized() 
		normal_direction = incoming_direction.bounce(normal) * max_bounce_distance
		
		var angle_of_incidence = acos(incoming_direction.dot(normal)) 
		var angle_of_reflection = angle_of_incidence
		var reflected_direction = incoming_direction.rotated(Vector3.UP, -2 * angle_of_reflection) 
		reflected_direction *= max_bounce_distance 
		raycast.global_transform.origin = point
		raycast.target_position = normal_direction
## Reference light_bouncer_old.gd for how to fix the first two or three variables, I forget which!
func bounce_light():
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
	var end_pos = raycast.get_collision_point() if raycast.is_colliding() else point + normal_direction
	
	beam_mesh.global_transform.origin = (point + end_pos) / 2
	 
	var direction = (end_pos - point).normalized()

	var basis = Basis.looking_at(direction, Vector3.UP)

	beam_mesh.global_transform.basis = basis
	beam_mesh.rotation_degrees.x += 90 
	var beam_length = point.distance_to(end_pos)
	beam_mesh.scale.y = beam_length
	
func create_beam_mesh():
	var mesh = CylinderMesh.new()
	mesh.top_radius = beam_width
	mesh.bottom_radius = beam_width
	mesh.height = 1.0
	mesh.material = StandardMaterial3D.new()
	mesh.material.albedo_color = light_color
	return mesh

func interact():
	var tween = create_tween()
	tween.tween_property(self, "global_rotation_degrees:y", global_rotation_degrees.y + 10, rotation_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
