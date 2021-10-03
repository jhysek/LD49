extends Node2D

const CELL_DEADLY = 4
const CELL_EXIT = 2

var SoftNoise = preload("res://Scripts/SoftNoise.gd")
var map_size = Vector2(24, 24)
var traversing_graph

var FallingTile = preload("res://Components/FallingTile/FallingTile.tscn")
var Enemy = preload("res://Components/Enemy/Enemy.tscn")
var tiles: Array = []

onready var tilemap = $TileMap
onready var player = $TileMap/Player
var paused = true
var exit_pos = Vector2(0,0)

func _ready():
	Transition.openScene()
	generate_empty_tiles(map_size.x, map_size.y)
	generate_terrain()
	generate_graph()
	correct_terrain()
	place_exit()
	draw_terrain()
	place_player()

	for _i in range(Settings.current_enemies()):
		var enemy = Enemy.instance()
		enemy.position = tilemap.map_to_world(Vector2(10,10))
		enemy.z_index = 1001
		$TileMap/Enemies.add_child(enemy)
		print("PLAYER POS: ", player.last_map_pos)
		enemy.place(random_accessible_place(player.last_map_pos))
	
	Settings.reset_stats()
	$CanvasLayer/Control/Objectives2.text = Settings.current_objectives()
	$CanvasLayer/Control/Objectives/Message.text = Settings.current_objectives()
	$CanvasLayer/Control/Objectives/No.text = str(Settings.current_level + 1)
func generate_empty_tiles(w, h):
	for _x in range(w):
		var col = []
		col.resize(h)
		tiles.append(col)
	
func start():
	$AnimationPlayer.play("Start")
	paused = false
	
func win():
	stop_enemies()
	var is_next = Settings.next_level()
	print("is next: ", str(is_next))
	if is_next:
		paused = true
		$RestartTimeout.start()
	else:
		Transition.switchTo("res://Scenes/Finished.tscn")

func lose():
	stop_enemies()
	if !paused:
		paused = true
		print("LOSED... restart timer starting")
		$RestartTimeout.start()
		
func stop_enemies():
	for enemy in $TileMap/Enemies.get_children():
		enemy.stop()
		
func restart_level():
	print("Restarting.. ")
	Transition.switchTo("res://Scenes/Game.tscn")
		
func crash_tile(map_pos, audio = false):
	var tile = get_tile_at(map_pos)
	if tile and tile.type != CELL_EXIT:
		tile.fall() 
		if audio:
			$Sfx/BrickFall.play()
	
func tile_destroyed(map_pos):
	tilemap.set_cell(map_pos.x, map_pos.y, -1)
	$TileMap/Player.evaluate_position(true)
	generate_graph()
	
func array_index(map_pos):
	return map_pos.y * map_size.y + fmod(map_pos.x, map_size.x)
	
func create_tile(map_pos, number):
	var tile = FallingTile.instance()
	tile.position = tilemap.map_to_world(map_pos) + Vector2(0,59)
	tile.set_tile(number, map_pos)
	tilemap.add_child(tile)
	tiles[map_pos.x][map_pos.y] = tile
	
func get_tile_at(map_pos):
	if map_pos.x < map_size.x && map_pos.y < map_size.y && map_pos.x >= 0 && map_pos.y >= 0:
		return tiles[map_pos.x][map_pos.y]
	else:
		return null
	
func draw_terrain():
	for y in range(map_size.y):
		for x in range(map_size.x):
			var cell = tilemap.get_cell(x, y)
			if cell >= 0:
				create_tile(Vector2(x,y), cell)
				
func generate_terrain():
	randomize()
	var softnoise = SoftNoise.new(randi())
	for y in range(map_size.y):
		for x in range(map_size.x):
			var v = softnoise.openSimplex2D(x*0.2, y*0.2)
			if v < -0.4:
				tilemap.set_cell(x, y, -1)
			elif v < -0.1:
				tilemap.set_cell(x, y, 3)
				
			elif v < 0.2:
				tilemap.set_cell(x, y, 0)
				
			elif v < 0.5:
				tilemap.set_cell(x, y, 1)
				
			else:
				tilemap.set_cell(x, y, CELL_DEADLY)
				
	# Fix starting corners:
	for x in range(8):
		for y in range(8):
			var cell = tilemap.get_cell(x, y)
			if !accessible_cell(cell):
				tilemap.set_cell(x, y, 1)
				
			cell = tilemap.get_cell(map_size.x - x - 1, map_size.y - y - 1)
			if !accessible_cell(cell):
				tilemap.set_cell(map_size.x - x - 1, map_size.y - y - 1, 1)
			
func correct_terrain():
	var path = traversing_graph.get_point_path(get_cell_id(1,1), get_cell_id(map_size.x - 2, map_size.x - 2))
	if path.size() == 0:
		for x in range(1, floor(map_size.x / 2)):
			if !accessible_cell(tilemap.get_cell(x, 2)):
				tilemap.set_cell(x, 2, 1) 
			if !accessible_cell(tilemap.get_cell(x, 3)):
				tilemap.set_cell(x, 3, 1) 
			if !accessible_cell(tilemap.get_cell(map_size.x - x - 1, map_size.y - 3)):
				tilemap.set_cell(map_size.x - x - 1, map_size.y - 3, 1) 
			if !accessible_cell(tilemap.get_cell(map_size.x - x - 1, map_size.y - 4)):
				tilemap.set_cell(map_size.x - x - 1, map_size.y - 4, 1) 
			
		for y in range(1, map_size.y / 2):
			if !accessible_cell(tilemap.get_cell(floor(map_size.x / 2), y)):
				tilemap.set_cell(floor(map_size.x / 2), y, 3) 
				
			if !accessible_cell(tilemap.get_cell(floor(map_size.x / 2), map_size.y - y - 2)):
				tilemap.set_cell(floor(map_size.x / 2), map_size.y - y - 2, 1) 
		generate_graph()
	
func random_accessible_place(from):
	var counter = 600
	while counter > 0:
		counter -= 1
		var rx = fmod(randi(), map_size.x - 10) + 10
		var ry = fmod(randi(), map_size.y - 10) + 10
		if accessible_cell(tilemap.get_cell(rx, ry)) and get_nearest_path(from, Vector2(rx, ry)).size() > 5:
			return Vector2(rx, ry)
	return false
	
func accessible_cell(cell):
	return cell >= 0 and cell != CELL_DEADLY

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

func deadly_cell(map_pos):
	var cell = tilemap.get_cell(map_pos.x, map_pos.y)
	if cell < 0:
		return 1
	if cell == CELL_DEADLY:
		return 2
	return 0
	
func get_nearest_path(from, to):
	return traversing_graph.get_point_path(get_cell_id(from.x, from.y), get_cell_id(to.x, to.y))

func get_random_starting_pos(corner):
	var x = randi() % 3 + 2
	var y = randi() % 3 + 2
	var map_pos = Vector2(x, y)
	if corner == "bottom":
		map_pos = map_size - Vector2(x + 1, y + 1)
	
	return map_pos
	
func place_exit():
	var map_pos = get_random_starting_pos("top")
	$TileMap/Exit.position = tilemap.map_to_world((map_pos))
	exit_pos = map_pos
	$TileMap.set_cell(map_pos.x, map_pos.y, CELL_EXIT)
	
		
func place_player():
	var map_pos = get_random_starting_pos("bottom")
	map_pos = get_random_starting_pos("bottom")
	player.place(map_pos)
	var cell = $TileMap.get_cellv(map_pos)
	if cell < 0:
		$TileMap.set_cellv(map_pos, 1)
	if cell == 3:
		$TileMap.set_cellv(map_pos, 2)

func _on_RestartTimeout_timeout():
	print("RESTART")
	paused = true
	restart_level()
