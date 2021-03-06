extends KinematicBody2D

onready var game = get_node("/root/Game")
onready var map  = get_node("/root/Game/TileMap")
onready var player = get_node("/root/Game/TileMap/Player")

var last_pos = Vector2(0,0)
var last_map_pos = Vector2(0,0)
var path = []
var target = Vector2(0,0)
var target_map = Vector2(0,0)

export var speed = 0.2
var cooldown = 0.5
var inactive = false

func _ready():
	position = map.map_to_world(last_map_pos)
	
func teleport():
	inactive = true
	$Sfx/Run.stop()
	$Sfx/StonesLoop.stop()
	$AnimationPlayer.play("teleport")
	
func stop():
	$Tween.stop_all()
	inactive = true
	$Timer.stop()

func place(map_pos):
	if map_pos:
		last_map_pos = map_pos
		position = map.map_to_world(map_pos)
	
func fall():
	z_index=0
	$Sfx/Run.stop()
	$Tween.stop_all()
	var new_position = Vector2(position.x, position.y + 1000)
	$Tween.interpolate_property(self, 'position', position, new_position, 2, Tween.TRANS_EXPO, Tween.EASE_IN)
	$Tween.interpolate_property(self, 'modulate', modulate, Color(1,1,1,0), 2, Tween.TRANS_EXPO, Tween.EASE_IN)
	$Tween.start()
	
	
func jump_to(map_pos, jump_speed):
	var new_pos = map.map_to_world(map_pos)
	
	if new_pos.x > position.x:
		$Visual.scale.x = -0.6
	elif new_pos.x < position.x:
		$Visual.scale.x = 0.6
	last_pos = position
	$Tween.stop_all()
	$Tween.interpolate_property(self, 'position', position, new_pos, jump_speed, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
	
func jump_to_world(world_pos, jump_speed):
	if world_pos.x > position.x:
		$Visual.scale.x = -0.6
	elif world_pos.x < position.x:
		$Visual.scale.x = 0.6
	$Tween.stop_all()
	$Tween.interpolate_property(self, 'position', position, world_pos, jump_speed, Tween.TRANS_LINEAR)
	$Tween.start()
	
func chase_player():
	if !player || game.paused || inactive:
		return
	
	path = game.get_nearest_path(last_map_pos, player.last_map_pos)
	
	if path.size() > 1:
		if path.size() == 2:
			if cooldown <= 0:
				cooldown = 0.5
				$Timer.start()
				$Sfx/Attack.play()
				jump_to_world(player.position - Vector2(0, 30), 0.1)
		else:
			jump_to(Vector2(path[1].x, path[1].y), 0.3)
			
		print("next target: ", target_map)
	else:
		$Timer.start()

func _on_Timer_timeout():
	if !game.paused:
		cooldown = 0
		if !inactive and $AnimationPlayer.current_animation != "Run":
			$AnimationPlayer.play("Run")
			$Sfx/Run.play()
			$Sfx/StonesLoop.play()
		chase_player()
	else:
		$Timer.start()
		
func _on_Tween_tween_completed(object, key):
	if inactive:
		return
	game.crash_tile(last_map_pos)
	last_map_pos = map.world_to_map(position)
	
	var deadly = game.deadly_cell(last_map_pos)
	if deadly == 1:
		$Timer.stop()
		fall()
		return
	chase_player()

func _on_Area2D_body_entered(body):
	if body.is_in_group("Player"):
		var impulse = (position - last_pos).normalized() * 200
		body.external_impulse = impulse

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "teleport":
		queue_free()
