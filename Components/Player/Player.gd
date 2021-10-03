extends RigidBody2D

const WALK_SPEED = 300
var motion = Vector2(0,0)
var last_map_pos = Vector2(0,0)
var external_impulse = Vector2(0,0)
var dead = false
var started = false
var air_time = 0
var nofall = false

onready var game = get_node("/root/Game")
onready var map  = get_node("/root/Game/TileMap")
onready var cursor = get_node("/root/Game/TileMap/Cursor")

func _ready():
	set_process_input(true)
	set_physics_process(true)
	
func place(map_pos):
	last_map_pos = map_pos
	position = map.map_to_world(map_pos)
	
func _input(event):
	if Input.is_action_just_pressed("ui_up") || \
		Input.is_action_just_pressed("ui_down") || \
		Input.is_action_just_pressed("ui_left") || \
		Input.is_action_just_pressed("ui_right"):
			started = true
			game.start()
			set_process_input(false)
	
func _physics_process(delta):	
	if dead:
		if !nofall:
			position.y += 2 * delta * WALK_SPEED
		else:
			print("NOFALLING...")
		return
		
	if game.paused:
		return
	
	motion = Vector2(0,0)
	
	if Input.is_action_pressed("ui_up"):
		motion.y -= 1
		$Visual/Front.hide()
		$Visual/Back.show()
		#motion.y -= 0.6
		#motion.x += 1
		
	if Input.is_action_pressed("ui_down"):
		motion.y += 1
		$Visual/Front.show()
		$Visual/Back.hide()
		#motion.y += 0.6
		#motion.x -= 1
		
	if Input.is_action_pressed("ui_left"):
		motion.x -= 1
		#motion.y -= 0.6
		#motion.x -= 1
		
	if Input.is_action_pressed("ui_right"):
		motion.x += 1
		

		#motion.y += 0.6
		#motion.x += 1
		
	#motion.x = min(1, motion.x)
	#otion.y = min(1, motion.y)
	
		
	if Input.is_action_just_pressed("ui_accept"):
		$AnimationPlayer.play("jump")
		air_time = 0.7
	
	if external_impulse != Vector2(0,0):
		print("EXTERNAL: ", external_impulse)
		external_impulse = lerp(external_impulse, Vector2(0,0), delta )
		if external_impulse.x < 1 and external_impulse.y < 1:
			external_impulse = Vector2(0,0)
	
	if started:
		position += motion * delta * WALK_SPEED
		if air_time <= 0:
			evaluate_position()
		else: 
			air_time -= delta
			
func die(hide = false):
	dead = true
	if hide:
		$AnimationPlayer.play("Die")
		nofall = true
		game.lose()
		return
		
	var map_pos = map.world_to_map(position)
	var tile = game.get_tile_at(map_pos) 
	if tile:
		z_index = tile.z_index
	else:
		z_index = 0
	game.lose()
	
func evaluate_position(force = false):
	var map_pos = map.world_to_map(position)
	if map_pos != last_map_pos or force:
		#game.crash_tile(last_map_pos)
		last_map_pos = map_pos
		cursor.tweenTo(map.map_to_world(map_pos) + Vector2(0,37))
		var deadly = game.deadly_cell(map_pos)
		if deadly == 1:
			die()
		if deadly == 2:
			die(true)


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "jump":
		var map_pos = map.world_to_map(position)
		game.crash_tile(map_pos)
