@tool

extends Node3D
var OceanTile = preload("res://environment/water/WaterPlane.tscn")
var spawnPoint = preload("res://environment/water/GridSpawnInfo.tres")
var tiles = []

# Creates tile grid for infinite ocean
func createOceanTiles():
	for i in 17: # Loop through 17 tiles
		
		# Get loction, subdivision, and scale of each tile and create instance
		var spawnLocation = spawnPoint.spawnPoints[i];
		var tileSubdivision = spawnPoint.subdivision[i];
		var tileScale = spawnPoint.scale[i];
		var instance = OceanTile.instantiate();
		
		add_child(instance);
		# Set tile position, subdivision, and scale
		instance.position = Vector3(spawnLocation.x,0.0,spawnLocation.y) * 10.05; # Multiply by mesh width 10.5m
		instance.mesh.set_subdivide_width(tileSubdivision);
		instance.mesh.set_subdivide_depth(tileSubdivision);
		instance.set_scale(Vector3(tileScale, 1.0, tileScale)); # Ignore Y value because of planes
		tiles.push_back(instance)

func _ready():
	PlayerCore.ocean = self
	print("hello, ",PlayerCore.ocean)
	createOceanTiles();
	print("ocean loaded")
	PlayerCore.ocean_height = tiles[0].get_surface_override_material(0).get("shader_parameter/height_scale")

func _process(delta):
	RenderingServer.global_shader_parameter_set("ocean_pos", self.position); # Update global shader parameter 'ocean_pos' to match the ocean node position
