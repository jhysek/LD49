extends Sprite


const regions = [
	Vector2(0,0),
	Vector2(128,0),
	Vector2(256,0),
	Vector2(384,0),
	Vector2(512,0)
]

const tile_size = Vector2(128, 118)

var type = 0
var disabled = false
var map_pos = Vector2(0,0)

func set_tile(t, map_position):
	type = t
	map_pos = map_position
	var region = regions[t]
	region_rect = Rect2(region, tile_size)
	
	if t == 4:
		light_mask = 1
	
func fall():
	if !disabled:
		disabled = true
		position.y += 10
		var new_position = Vector2(position.x, position.y + 1000)
		$Tween.interpolate_property(self, 'position', position, new_position, 2, Tween.TRANS_EXPO, Tween.EASE_IN)
		$Tween.interpolate_property(self, 'modulate', modulate, Color(1,1,1,0), 2, Tween.TRANS_EXPO, Tween.EASE_IN)
		$Tween.start()
		$Timer.start()

func _on_Tween_tween_all_completed():
	hide()


func _on_Timer_timeout():
	get_node("/root/Game").tile_destroyed(map_pos)
