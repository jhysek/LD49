extends Sprite

const regions = [
	Vector2(0,0),
	Vector2(128,0),
	Vector2(256,0),
	Vector2(384,0),
	Vector2(0,118),
	Vector2(128,118),
	Vector2(256,118),
	Vector2(384,188)
]

const tile_size = Vector2(128, 118)

func set_tile(t):
	var region = regions[t]
	region_rect = Rect2(region, tile_size)

func fall():
	var new_position = Vector2(position.x, position.y + 1000)
	$Tween.interpolate_property(self, 'position', position, new_position, 2, Tween.TRANS_EXPO, Tween.EASE_IN)
	$Tween.interpolate_property(self, 'modulate', modulate, Color(1,1,1,0), 2, Tween.TRANS_EXPO, Tween.EASE_IN)
	$Tween.start()

func _on_Tween_tween_all_completed():
	queue_free()
