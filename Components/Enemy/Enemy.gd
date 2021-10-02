extends KinematicBody2D

onready var game = get_node("/root/Game")
onready var map  = get_node("/root/Game/TileMap")
onready var player = get_node("/root/Game/TileMap/Player")

var last_pos = Vector2(0,0)
var last_map_pos = Vector2(0,0)
var path = []
var target = Vector2(0,0)
var target_map = Vector2(0,0)

export var speed = 0.3

var cooldown = 0.5


func _ready():
	position = map.map_to_world(last_map_pos)

func place(map_pos):
	last_map_pos = map_pos
	position = map.map_to_world(map_pos)
	
func jump_to(map_pos, jump_speed):
	last_pos = position
	$Tween.stop_all()
	$Tween.interpolate_property(self, 'position', position, map.map_to_world(map_pos), jump_speed, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
	
func jump_to_world(world_pos, jump_speed):
	$Tween.stop_all()
	$Tween.interpolate_property(self, 'position', position, world_pos, jump_speed, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
	
func chase_player():
	if !player || game.paused:
		return
	
	path = game.get_nearest_path(last_map_pos, player.last_map_pos)
	
	if path.size() > 1:
		if path.size() == 2:
			if cooldown <= 0:
				cooldown = 0.5
				$Timer.start()
				jump_to_world(player.position - Vector2(0, 30), 0.1)
		else:
			jump_to(Vector2(path[1].x, path[1].y), 0.3)
			
		print("next target: ", target_map)
	else:
		$Timer.start()

func _on_Timer_timeout():
	cooldown = 0
	chase_player()

func _on_Tween_tween_completed(object, key):
	last_map_pos = map.world_to_map(position)
	chase_player()


func _on_Area2D_body_entered(body):
	if body.is_in_group("Player"):
		var impulse = (position - last_pos).normalized() * 200
		print(" >>>>> ", impulse)
		body.external_impulse = impulse

