extends Control
class_name WashingUI

const GUIDE_RADIUS: float = 90.0
const MIN_RADIUS: float = 30.0
const MAX_RADIUS: float = 150.0

const ACTIVE_PROMPT := \
	"Move the cursor in circles to wash\n" \
	+ "Move or jump to cancel • [F / RMB] Close"

const COMPLETE_PROMPT := \
	"Clean!\n" \
	+ "[E / LMB] Take ingredient • [F / RMB] Close\n" \
	+ "Move or jump to leave"

var _cursor := Vector2(GUIDE_RADIUS, 0.0)
var _progress: float = 0.0
var _complete: bool = false
var _prompt: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_prompt = Label.new()
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	add_child(_prompt)

	_prompt.set_anchors_and_offsets_preset(
		Control.PRESET_CENTER
	)
	_prompt.offset_left = -360.0
	_prompt.offset_right = 360.0
	_prompt.offset_top = 185.0
	_prompt.offset_bottom = 315.0

	hide()


func configure_from_tooltip(source: Label) -> void:
	_prompt.theme = source.theme
	_prompt.add_theme_font_override(
		"font",
		source.get_theme_font("font")
	)
	_prompt.add_theme_font_size_override(
		"font_size",
		source.get_theme_font_size("font_size")
	)
	_prompt.add_theme_color_override(
		"font_color",
		source.get_theme_color("font_color")
	)
	_prompt.add_theme_color_override(
		"font_shadow_color",
		Color.BLACK
	)
	_prompt.add_theme_constant_override("shadow_offset_x", 2)
	_prompt.add_theme_constant_override("shadow_offset_y", 2)


func begin(progress: float) -> void:
	_cursor = Vector2(GUIDE_RADIUS, 0.0)
	_complete = false
	set_progress(progress)
	show()
	queue_redraw()


func set_progress(progress: float) -> void:
	_progress = clampf(progress, 0.0, 1.0)
	_prompt.text = ACTIVE_PROMPT + "\n%d%%" % int(_progress * 100.0)
	queue_redraw()


func show_complete() -> void:
	_complete = true
	_progress = 1.0
	_prompt.text = COMPLETE_PROMPT
	queue_redraw()


# Moves the visible virtual cursor and returns valid signed rotation.
func move_cursor(motion: Vector2) -> float:
	if _complete:
		return 0.0

	var previous := _cursor
	var next := (previous + motion).limit_length(MAX_RADIUS)
	_cursor = next
	queue_redraw()

	if previous.length() < MIN_RADIUS or next.length() < MIN_RADIUS:
		return 0.0

	var segment := next - previous
	var length_squared := segment.length_squared()

	if length_squared <= 0.0:
		return 0.0

	# Crossing through the center should not count as circular motion.
	var closest_fraction := clampf(
		-previous.dot(segment) / length_squared,
		0.0,
		1.0
	)
	var closest_point := previous + segment * closest_fraction

	if closest_point.length() < MIN_RADIUS:
		return 0.0

	var angle_change := previous.angle_to(next)

	if absf(angle_change) > PI / 2.0:
		return 0.0

	return angle_change


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var accent := Color(0.35, 1.0, 0.55) if _complete \
		else Color(1.0, 0.85, 0.3)

	draw_arc(
		center, GUIDE_RADIUS, 0.0, TAU,
		96, Color(1.0, 1.0, 1.0, 0.35), 3.0, true
	)

	draw_arc(
		center, MAX_RADIUS, 0.0, TAU,
		96, Color(1.0, 1.0, 1.0, 0.15), 1.0, true
	)

	if _progress > 0.0:
		draw_arc(
			center,
			GUIDE_RADIUS,
			-PI / 2.0,
			-PI / 2.0 + TAU * _progress,
			96,
			accent,
			6.0,
			true
		)

	draw_circle(center, 4.0, accent)

	var cursor_position := center + _cursor
	draw_circle(cursor_position, 10.0, Color.BLACK)
	draw_circle(cursor_position, 7.0, Color.WHITE)

	draw_line(
		cursor_position - Vector2(13.0, 0.0),
		cursor_position + Vector2(13.0, 0.0),
		accent, 2.0, true
	)
	draw_line(
		cursor_position - Vector2(0.0, 13.0),
		cursor_position + Vector2(0.0, 13.0),
		accent, 2.0, true
	)
