extends Node2D

func _ready():
	Transition.openScene()

func _on_StartBtn_pressed():
	Settings.current_level = 0
	Transition.switchTo("res://Scenes/Game.tscn")
