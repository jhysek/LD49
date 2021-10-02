extends RigidBody2D

const WALK_SPEED = 20000
var motion = Vector2(0,0)
var last_map_pos = Vector2(0,0)
var external_impulse = Vector2(0,0)
var dead = false
var started = false

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
			set_process_input(false)
	
func _physics_process(delta):
	if dead || game.paused:
		return
		
	motion = Vector2(0,0)
	
	if Input.is_action_pressed("ui_up"):
		motion.y -= 1
		
	if Input.is_action_pressed("ui_down"):
		motion.y += 1
		
	if Input.is_action_pressed("ui_left"):
		motion.x -= 1
		
	if Input.is_action_pressed("ui_right"):
		motion.x += 1
		
	if Input.is_action_just_pressed("ui_accept"):
		game.crash_tile(last_map_pos)
	
	if external_impulse != Vector2(0,0):
		print("EXTERNAL: ", external_impulse)
		external_impulse = lerp(external_impulse, Vector2(0,0), delta )
		if external_impulse.x < 1 and external_impulse.y < 1:
			external_impulse = Vector2(0,0)
	
	if started:
		position += motion * delta * 500#* WALK_SPEED
		#move_and_slide(motion * delta * WALK_SPEED + external_impulse)
		evaluate_position()
	
			
func die():
	print("dead...")
	dead = true
	hide()
	game.lose()
	
func evaluate_position():
	var map_pos = map.world_to_map(position)
	if map_pos != last_map_pos:
		last_map_pos = map_pos
		cursor.tweenTo(map.map_to_world(map_pos) + Vector2(0,37))
		if game.is_deadly_place(map_pos):
			die()
