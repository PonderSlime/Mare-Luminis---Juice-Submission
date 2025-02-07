extends Control

@onready var slot_scene = preload("res://ui/inventory/slot.tscn")
@onready var grid_container = $BG/MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var item_scene = preload("res://ui/inventory/item.tscn")
@onready var scroll_container = $BG/MarginContainer/VBoxContainer/ScrollContainer
@export var blocked_grids_resource: String = ""
@export var col_count = 6
@export var grid_count = 100
var blocked_grids = []

var grid_array := []
var current_slot = null
var can_place := false
var icon_anchor : Vector2

func _ready() -> void:
	grid_container.columns = col_count
	load_blocked_grids(blocked_grids_resource)
		
	for i in range(grid_count):
		var y = i % col_count
		var x = i / col_count
		create_slot(i, x, y)
	load_inventory()
	for i in range(grid_array.size()):
		print("Grid Slot", i, "Position:", grid_array[i].global_position)

func _input(event: InputEvent) -> void:
	if PlayerCore.item_held:
		if Input.is_action_just_pressed("rotate_item"):
			rotate_item()
		if Input.is_action_just_pressed("left_click"):
			if scroll_container.get_global_rect().has_point(get_global_mouse_position()):
				place_item()
	else:
		if Input.is_action_just_pressed("left_click"):
			if scroll_container.get_global_rect().has_point(get_global_mouse_position()):
				pick_item()
				
func load_blocked_grids(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		var json = JSON.parse_string(json_text)
		file.close()
		if json and "blocked_positions" in json:
			for pos in json["blocked_positions"]:
				blocked_grids.append(Vector2i(pos[0], pos[1]))
func create_slot(index: int, x: int, y: int) -> void:
	var new_slot = slot_scene.instantiate()
	new_slot.slot_ID = grid_array.size()

	var grid_position = Vector2i(x, y)
	
	if blocked_grids.has(grid_position):
		new_slot.texture = preload("res://ui/inventory/assets/slot_blank.png")  
	grid_array.push_back(new_slot)
	grid_container.add_child(new_slot)
	new_slot.slot_entered.connect(_on_slot_mouse_entered)
	new_slot.slot_exited.connect(_on_slot_mouse_exited)

func _on_slot_mouse_entered(what_slot):
	icon_anchor  = Vector2(10000,10000)
	current_slot = what_slot
	if PlayerCore.item_held:
		check_slot_availability(current_slot)
		set_grids.call_deferred(current_slot)

func _on_slot_mouse_exited(what_slot):
	current_slot = null
	clear_grid()

func _on_spawner_button_pressed() -> void:
	var new_item = item_scene.instantiate()
	get_tree().root.add_child(new_item)
	PlayerCore.item_held = new_item
	PlayerCore.item_held.load_item(0)
	PlayerCore.item_held.selected = true

func check_slot_availability(slot) -> void:
	for grid in PlayerCore.item_held.item_grids:
		var grid_to_check = slot.slot_ID + grid[0] + grid[1] * col_count
		var line_switch_check = slot.slot_ID % col_count + grid[0]
		
		if line_switch_check < 0 or line_switch_check >= col_count:
			can_place = false
			return
		
		if grid_to_check < 0 or grid_to_check >= grid_array.size():
			can_place = false
			return
		
		var grid_position = Vector2i(slot.slot_ID % col_count + grid[0], slot.slot_ID / col_count + grid[1])
		if blocked_grids.has(grid_position):
			can_place = false
			return
		
		if grid_array[grid_to_check].state == grid_array[grid_to_check].States.TAKEN:
			can_place = false
			return
	can_place = true

func set_grids(slot) -> void:
	if not PlayerCore.item_held:
		return
	for grid in PlayerCore.item_held.item_grids:
		var grid_to_check = slot.slot_ID + grid[0] + grid[1] * col_count
		var line_switch_check = slot.slot_ID % col_count + grid[0]
		
		if line_switch_check < 0 or line_switch_check >= col_count:
			continue
		
		var grid_position = Vector2i(slot.slot_ID % col_count + grid[0], slot.slot_ID / col_count + grid[1])
		if blocked_grids.has(grid_position):
			grid_array[grid_to_check].set_color(grid_array[grid_to_check].States.TAKEN)
			
		elif grid_to_check < 0 or grid_to_check >= grid_array.size():
			continue
			
		if can_place:
			grid_array[grid_to_check].set_color(grid_array[grid_to_check].States.FREE)
			
			if grid[1] < icon_anchor.x: icon_anchor.x = grid[1]
			if grid[0] < icon_anchor.y: icon_anchor.y = grid[0]
		else:
			grid_array[grid_to_check].set_color(grid_array[grid_to_check].States.TAKEN)

func clear_grid():
	for grid in grid_array:
		grid.set_color(grid.States.DEFAULT)
func rotate_item():
	await get_tree().create_timer(0.01).timeout
	clear_grid()
	if current_slot:
		_on_slot_mouse_entered(current_slot)
	
func place_item():
	if not can_place or not current_slot:
		return
	
	var calculated_grid_id = current_slot.slot_ID + icon_anchor.x * col_count + icon_anchor.y
	PlayerCore.item_held._snap_to(grid_array[calculated_grid_id].global_position)
	print("Snapping to ", grid_array[calculated_grid_id].global_position)
	PlayerCore.item_held.get_parent().remove_child(PlayerCore.item_held)
	grid_container.add_child(PlayerCore.item_held)
	PlayerCore.item_held.global_position = get_global_mouse_position()
	
	PlayerCore.item_held.grid_anchor = current_slot
	for grid in PlayerCore.item_held.item_grids:
		var grid_to_check = current_slot.slot_ID + grid[0] + grid[1] * col_count
		grid_array[grid_to_check].state = grid_array[grid_to_check].States.TAKEN
		grid_array[grid_to_check].item_stored = PlayerCore.item_held
		
	PlayerCore.item_held = null
	
	clear_grid()
	save_inventory()

func pick_item():
	if not current_slot or not current_slot.item_stored:
		return
	
	PlayerCore.item_held = current_slot.item_stored
	PlayerCore.item_held.selected = true
	
	PlayerCore.item_held.get_parent().remove_child(PlayerCore.item_held)
	get_tree().root.add_child(PlayerCore.item_held)
	
	for grid in PlayerCore.item_held.item_grids:
		var grid_to_check = PlayerCore.item_held.grid_anchor.slot_ID + grid[0] + grid[1] * col_count
		grid_array[grid_to_check].state = grid_array[grid_to_check].States.FREE
		grid_array[grid_to_check].item_stored = null
	check_slot_availability(current_slot)
	set_grids.call_deferred(current_slot)
	save_inventory()

func save_inventory():
	var save_data = {
		"items": []
	}
	
	for slot in grid_array:
		if slot.item_stored:
			var item_data = {
				"item_ID": slot.item_stored.item_ID,
				"position": [slot.slot_ID % col_count, slot.slot_ID / col_count],
				"rotation": slot.item_stored.rotation_degrees,
				"grids": slot.item_stored.item_grids
			}
			save_data["items"].append(item_data)
	
	var file = FileAccess.open("user://inventory_save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	print("Inventory saved.")

func load_inventory():
	var file = FileAccess.open("user://inventory_save.json", FileAccess.READ)
	if not file:
		print("No save file found.")
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.parse_string(json_text)
	if not json or not "items" in json:
		print("Invalid save file.")
		return
	
	for item_data in json["items"]:
		var new_item = item_scene.instantiate()
		grid_container.add_child(new_item)
		new_item.position = Vector2.ZERO
		
		new_item.load_item(item_data["item_ID"])
		new_item.rotation_degrees = item_data["rotation"]
		new_item.item_grids = item_data["grids"]
		
		var saved_x = item_data["position"][0]
		var saved_y = item_data["position"][1]
		var slot_index = int(saved_x) * col_count + int(saved_y)
		
		if slot_index < 0 or slot_index >= grid_array.size():
			print("Invalid slot index, skipping item.")
			continue
		print("Target Slot Position:", grid_array[slot_index].global_position)
		print("Saved X:", saved_x, "Saved Y:", saved_y)
		print("Column Count:", col_count)
		print("Calculated Slot Index:", saved_x * col_count + saved_y)
		var target_slot = grid_array[slot_index]
		new_item.grid_anchor = target_slot
		print(slot_index)
		
		new_item.global_position = target_slot.global_position

		if new_item.item_grids.size() > 1:
			var first_grid_offset = new_item.item_grids[0]
			new_item.global_position += Vector2(first_grid_offset[0] * grid_count, first_grid_offset[1] * grid_count)
		
		new_item._snap_to(grid_array[slot_index].global_position)
		print("Snapping to ", grid_array[slot_index].global_position)
		print("position?? : ", new_item.global_position)
		
		for grid in new_item.item_grids:
			var grid_x = saved_x + grid[0]
			var grid_y = saved_y + grid[1]
			var grid_index = grid_y * col_count + grid_x
			
			if grid_index >= 0 and grid_index < grid_array.size():
				grid_array[grid_index].state = grid_array[grid_index].States.TAKEN
				grid_array[grid_index].item_stored = new_item
		
		PlayerCore.item_held = null
	
		clear_grid()
	print("Inventory loaded successfully.")
