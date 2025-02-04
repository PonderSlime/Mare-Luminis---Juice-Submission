extends Control

@onready var slot_scene = preload("res://ui/inventory/slot.tscn")
@onready var grid_container = $BG/MarginContainer/VBoxContainer/ScrollContainer/GridContainer

var grid_array := []

func _ready() -> void:
	for i in range(64):
		create_slot()

func create_slot():
	var new_slot = slot_scene.instantiate()
	new_slot.slot_ID = grid_array.size()
	grid_container.add_child(new_slot)
	new_slot.slot_entered.connect(_on_slot_mouse_entered)
	new_slot.slot_exited.connect(_on_slot_mouse_exited)

func _on_slot_mouse_entered():
	pass

func _on_slot_mouse_exited():
	pass
