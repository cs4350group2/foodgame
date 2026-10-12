extends Control
class_name CookingCrosshair

var _chopping_progress: float = 0.0


func set_chopping_progress(progress: float) -> void:
	var next_progress := clampf(progress, 0.0, 1.0)

	if is_equal_approx(next_progress, _chopping_progress):
		return

	_chopping_progress = next_progress
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, Color(0, 0, 0, 0.7))
	draw_circle(Vector2.ZERO, 2.5, Color.WHITE)

	if _chopping_progress <= 0.0:
		return

	# Centered horizontally, 20 pixels below the crosshair.
	var background := Rect2(-60.0, 20.0, 120.0, 10.0)
	draw_rect(background, Color(0.05, 0.05, 0.05, 0.85))

	var fill := Rect2(
		background.position + Vector2(1.0, 1.0),
		Vector2(118.0 * _chopping_progress, 8.0)
	)
	draw_rect(fill, Color(1.0, 0.85, 0.3))

	draw_rect(background, Color.WHITE, false, 1.0)
