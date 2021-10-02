extends Node2D

func _ready():
	Transition.openScene()

func _on_StartBtn_pressed():
	Transition.switchTo("res://Scenes/Game.tscn")
