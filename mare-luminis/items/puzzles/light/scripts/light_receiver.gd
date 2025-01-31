extends Node3D

signal light_recieved

@export var trigger_action: Callable

func receive_light():
	light_recieved.emit()
	if trigger_action.is_valid():
		trigger_action.call()
