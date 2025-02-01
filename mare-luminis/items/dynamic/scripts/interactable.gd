extends Area3D

@export var interaction_prompt: String = "[F]"
@export var interaction_range: float = 3.0
@export var popup_offset: float = 2.0
@export var popup_duration: float = 0.3

signal interacted

var player_in_range = false
@onready var ui_prompt = $UI_Prompt
@onready var tween := get_tree().create_tween()

func _ready():
	ui_prompt.visible = false
	ui_prompt.text = interaction_prompt
func _process(delta):
	if ui_prompt and get_viewport().get_camera_3d():
		ui_prompt.look_at(get_viewport().get_camera_3d().global_transform.origin, Vector3.UP)
		ui_prompt.rotation_degrees.y += 180
		ui_prompt.rotation_degrees.x = 0
	$CollisionShape3D.shape.radius = interaction_range

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		show_popup()

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		hide_popup()

func show_popup():
	ui_prompt.visible = true
	ui_prompt.position = position
	
	tween.stop()
	tween = get_tree().create_tween()
	tween.tween_property(ui_prompt, "global_position", global_position + Vector3(0, popup_offset, 0), popup_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
func hide_popup():
	tween.stop()
	tween = get_tree().create_tween()
	tween.tween_property(ui_prompt, "global_position", global_position, popup_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).set_delay(0.1)
	tween.tween_callback(func(): ui_prompt.visible = false)

func interact():
	if player_in_range:
		interacted.emit()
		print("Player interacted with", name)
