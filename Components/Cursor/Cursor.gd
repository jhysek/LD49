extends Sprite


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func tweenTo(pos):
	$Tween.stop_all()
	$Tween.interpolate_property(self, 'position', position, pos, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.start()
