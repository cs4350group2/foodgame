extends Control

var _state: int = 0
var _color := Color.WHITE

func set_state(state: int, color: Color) -> void:
	if state == _state and color == _color:
		return
	_state = state
	_color = color
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	if _state == 1:
		draw_polyline(PackedVector2Array([
			center + Vector2(-5, 0), center + Vector2(-1, 4), center + Vector2(6, -4)
		]), _color, 2.0)
	elif _state == 2:
		draw_line(center + Vector2(-4, -4), center + Vector2(4, 4), _color, 2.0)
		draw_line(center + Vector2(-4, 4), center + Vector2(4, -4), _color, 2.0)
	else:
		draw_circle(center, 3.0, _color)
