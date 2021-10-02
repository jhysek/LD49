extends Node2D

var SoftNoise = preload("res://Scripts/SoftNoise.gd")
var map_size = Vector2(24, 24)
var traversing_graph

var FallingTile = preload("res://Components/FallingTile/FallingTile.tscn")
var tiles = []

onready var tilemap = $TileMap
var paused = false
	
func _ready():
	generate_terrain()
	generate_graph()
	correct_terrain()
	var player = $TileMap/Player
	player.place(random_accessible_place(Vector2(0,0)))
	$TileMap/Enemy.place(random_accessible_place(player.last_map_pos))
	#$TileMap/Enemy2.place(random_accessible_place(player.last_map_pos))
	#$TileMap/Enemy3.place(random_accessible_place(player.last_map_pos))
	Transition.openScene()
	
func win():
	paused = true
	print("YEAH!")
	restart_level()

func lose():
	paused = true
	print("OH NOOO")
	restart_level()
		
func restart_level():
	Transition.switchTo("res://Scenes/Game.tscn")
		
func crash_tile(mapPos):
	var tile = FallingTile.instance()
	tile.show_behind_parent = true
	tile.position = $TileMap.map_to_world(mapPos) + Vector2(0, 74)
	tilemap.add_child(tile)
	tilemap.set_cell(mapPos.x, mapPos.y, -1)
		
func create_tile(map_pos, number):
	var tile = FallingTile.instance()
	tile.position = tilemap.map_to_world(map_pos) + Vector2(0,59)
	tile.set_tile(number)
	tilemap.add_child(tile)
	tiles[map_pos.y * map_size.y + fmod(map_pos.x, map_size.x)] = number
	
func get_tile_at(map_pos):
	return tiles[map_pos.y * map_size.y + fmod(map_pos.x, map_size.x)]
	
func generate_terrain():
	randomize()
	var softnoise = SoftNoise.new(randi())
	for y in range(map_size.y):
		for x in range(map_size.x):
			var v = softnoise.openSimplex2D(x*0.2, y*0.2)
			if v < -0.4:
				print(x, "x", y, " => -1")
				tilemap.set_cell(x, y, -1)
			elif v < -0.1:
				create_tile(Vector2(x,y), 0)
				tilemap.set_cell(x, y, 1)
			elif v < 0.5:
				
				print(x, "x", y, " => 2")
				create_tile(Vector2(x,y), 1)
				tilemap.set_cell(x, y, 2)
			else:
				print("3")
				create_tile(Vector2(x,y), 6)
				tilemap.set_cell(x, y, 3)
				
	# Fix starting corners:
	for x in range(3):
		for y in range(3):
			var cell = tilemap.get_cell(x, y)
			if !accessible_cell(cell):
				tilemap.set_cell(x, y, 7)
				
			cell = tilemap.get_cell(map_size.x - x - 1, map_size.y - y - 1)
			if !accessible_cell(cell):
				tilemap.set_cell(map_size.x - x - 1, map_size.y - y - 1, 7)
			
func correct_terrain():
	var path = traversing_graph.get_point_path(get_cell_id(1,1), get_cell_id(map_size.x - 2, map_size.x - 2))
	if path.size() == 0:
		for x in range(1, floor(map_size.x / 2)):
			if !accessible_cell(tilemap.get_cell(x, 2)):
				tilemap.set_cell(x, 2, 7) 
			if !accessible_cell(tilemap.get_cell(x, 3)):
				tilemap.set_cell(x, 3, 7) 
			if !accessible_cell(tilemap.get_cell(map_size.x - x - 1, map_size.y - 3)):
				tilemap.set_cell(map_size.x - x - 1, map_size.y - 3, 7) 
			if !accessible_cell(tilemap.get_cell(map_size.x - x - 1, map_size.y - 4)):
				tilemap.set_cell(map_size.x - x - 1, map_size.y - 4, 7) 
			
		for y in range(1, map_size.y / 2):
			if !accessible_cell(tilemap.get_cell(floor(map_size.x / 2), y)):
				tilemap.set_cell(floor(map_size.x / 2), y, 7) 
			if !accessible_cell(tilemap.get_cell(floor(map_size.x / 2), map_size.y - y - 2)):
				tilemap.set_cell(floor(map_size.x / 2), map_size.y - y - 2, 7) 
		generate_graph()
	
func random_accessible_place(from):
	var rx = fmod(randi(), map_size.x)
	var ry = fmod(randi(), map_size.y)
	if get_nearest_path(from, Vector2(rx, ry)).size() > 5:
		return Vector2(rx, ry)
	else:
		return random_accessible_place(from)
	
func accessible_cell(cell):
	return cell > 0 and cell != 3

func get_cell_id(x, y):
	return x + map_size.y * y
	
func world_to_map(worldPos):
	return Vector2(
		floor(worldPos.y / 74 + worldPos.x / (2 * 128)), 
		floor(worldPos.y / 74 - worldPos.x / (2*128)))
	
func map_to_world(mapPos):
	var screenX = (mapPos.x - mapPos.y)*(128)
	var screenY = (mapPos.x + mapPos.y)*(37) + 37
	return Vector2(screenX, screenY)
				

func generate_graph():
	if !traversing_graph:
		traversing_graph = AStar.new()
	else:
		traversing_graph.clear()
	
	# Add nodes
	for x in range(0, map_size.x):
		for y in range(0, map_size.y):
			if accessible_cell(tilemap.get_cell(x, y)):
				traversing_graph.add_point(get_cell_id(x, y), Vector3(x, y, 0))  
	
	# Add connections
	for x in range(0, map_size.x):
		for y in range(0, map_size.y):
			var cell_id = get_cell_id(x, y)
			if traversing_graph.has_point(cell_id):
				# get neighbours
				if accessible_cell(tilemap.get_cell(x + 1, y)):
					traversing_graph.connect_points(cell_id, get_cell_id(x+1, y))
					
				if accessible_cell(tilemap.get_cell(x, y + 1)):
					traversing_graph.connect_points(cell_id, get_cell_id(x, y + 1))
					

func is_deadly_place(map_pos):
	return !accessible_cell(tilemap.get_cell(map_pos.x, map_pos.y))

func get_nearest_path(from, to):
	return traversing_graph.get_point_path(get_cell_id(from.x, from.y), get_cell_id(to.x, to.y))
