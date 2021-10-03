extends Area2D

onready var game = get_node("/root/Game")

func _on_Exit_body_entered(body):
	if body.is_in_group("Player"):
		$Sfx/Teleport.play()
		body.teleport()
		Settings.teleported()
		if Settings.objectives_met():
			game.win()
		else:
			game.lose()
		
	if body.is_in_group("Enemy"):
		$Sfx/Teleport.play()
		body.teleport()
		Settings.robobul_teleported()
		if Settings.objectives_met():
			game.win()
