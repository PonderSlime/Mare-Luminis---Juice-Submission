extends TextureRect

signal slot_entered(slot)
signal slot_exited(slot)

@onready var filter = $StatusFilter

var slot_ID
var is_hovering := false
enum States {DEFAULT, TAKEN, FREE}
var state := States.DEFAULT
var item_stored = null

func set_color(what_state = States.DEFAULT) -> void:
	match what_state:
		States.DEFAULT:
			filter.color = Color(1.0, 1.0, 1.0, 0.0)
		States.TAKEN:
			filter.color = Color(1.0, 0.0, 0.0, 0.2)
		States.FREE:
			filter.color = Color(0.0, 1.0, 0.0, 0.2)

func _process(delta: float) -> void:
	if get_global_rect().has_point(get_global_mouse_position()):
		if not is_hovering:
			is_hovering = true
			emit_signal("slot_entered", self)
	else:
		if is_hovering:
			is_hovering = false
			emit_signal("slot_exited", self)
