extends Node2D

@onready var IconRect_path = $Icon

var item_ID : int
var item_grids := []
var selected = false
var grid_anchor = null

func _process(delta: float) -> void:
	if selected:
		global_position = lerp(global_position, get_global_mouse_position(), 25 * delta)
	if PlayerCore.item_held == self:
		global_position = get_global_mouse_position()
		if Input.is_action_just_pressed("rotate_item"):
			rotate_item()

func load_item(what_item_ID : int) -> void:
	var Icon_path = "res://ui/inventory/assets/items/" + DataHandler.item_data[str(what_item_ID)]["Name"] + ".png"
	IconRect_path.texture = load(Icon_path)
	for grid in DataHandler.item_grid_data[str(what_item_ID)]:
		var converter_array := []
		for i in grid:
			converter_array.push_back(int(i))
		item_grids.push_back(converter_array)

func rotate_item():
	for grid in item_grids:
		var temp_x = grid[1]
		grid[1] = grid[0]
		grid[0] = -temp_x
		var tween = create_tween()
		tween.tween_property(self, "rotation_degrees", rotation_degrees + 90, 0.1).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		print(rotation_degrees)
		if rotation_degrees >= 360:
			rotation_degrees = 0
	

func _snap_to(destination: Vector2):
	var tween = create_tween()
	if int(rotation_degrees) % 100 == 0:
		destination += IconRect_path.size / 2
	else:
		var temp_xy_switch = Vector2(IconRect_path.size.y, IconRect_path.size.x)
		destination += temp_xy_switch / 2
	
	tween.tween_property(self, "global_position", destination, 0.15).set_trans(Tween.TRANS_SINE)
	selected = false
