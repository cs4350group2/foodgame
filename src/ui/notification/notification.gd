class_name Notification
extends CanvasLayer

@export var debug: bool = false

@onready var top: Panel = $Top
@onready var error_bottom: Panel = $ErrorBottom
@onready var top_label: Label = $Top/Label

const TOP_MIN_WIDTH := 400.0
const TOP_HORIZONTAL_PADDING := 40.0
const TOP_VERTICAL_PADDING := 20.0
const VIEWPORT_SIDE_MARGIN := 20.0

var top_tween_reference = null
var show_top_description: bool = false

func _ready() -> void:
	top.modulate = Color(1, 1, 1, 0)
	error_bottom.modulate = Color(1, 1, 1, 0)

func show_top(message: String, show_description: bool = false, description_message: String = "") -> void:
	if top_tween_reference:
		top_tween_reference.kill()

	top_label.text = message
	_resize_top_to_text(message)
		
	var description := top.find_child("Description") as Control
	if show_description && description:
		description.visible = true
		var description_label := description.find_child("Label") as Label
		if description_label:
			description_label.text = description_message
			_resize_description_to_text(description, description_label, description_message)
	else:
		description.visible = false
	
	if top_label:
		top.scale = Vector2(0.8, 0.8)
		top.modulate = Color(1, 1, 1, 0)
		
		top_tween_reference = create_tween().set_parallel(true)
		top_tween_reference.tween_property(top, "scale", Vector2(1, 1), 0.5)
		top_tween_reference.tween_property(top, "modulate", Color(1, 1, 1, 1), 0.5)
		
		top_tween_reference.chain().tween_interval(7)
		top_tween_reference.chain().tween_property(top, "modulate", Color(1, 1, 1, 0), 0.5)

func _resize_top_to_text(message: String) -> void:
	var font := top_label.get_theme_font("font")
	var font_size := top_label.get_theme_font_size("font_size")
	var viewport_width := get_viewport().get_visible_rect().size.x
	var max_width := maxf(120.0, viewport_width - VIEWPORT_SIDE_MARGIN * 2.0)
	var text_width := font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var panel_width := minf(maxf(TOP_MIN_WIDTH, text_width + TOP_HORIZONTAL_PADDING), max_width)
	var label_width := panel_width - TOP_HORIZONTAL_PADDING
	var text_size := font.get_multiline_string_size(
		message,
		HORIZONTAL_ALIGNMENT_CENTER,
		label_width,
		font_size
	)
	var panel_height := maxf(40.0, text_size.y + TOP_VERTICAL_PADDING)

	top.offset_left = -panel_width * 0.5
	top.offset_right = panel_width * 0.5
	top.offset_bottom = top.offset_top + panel_height

func _resize_description_to_text(description: Control, label: Label, message: String) -> void:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var viewport_width := get_viewport().get_visible_rect().size.x
	var max_width := maxf(120.0, viewport_width - VIEWPORT_SIDE_MARGIN * 2.0)
	var text_width := font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var panel_width := minf(maxf(TOP_MIN_WIDTH, text_width + TOP_HORIZONTAL_PADDING), max_width)
	var label_width := panel_width - TOP_HORIZONTAL_PADDING
	var text_size := font.get_multiline_string_size(
		message,
		HORIZONTAL_ALIGNMENT_CENTER,
		label_width,
		font_size
	)
	var panel_height := maxf(30.0, text_size.y + TOP_VERTICAL_PADDING)
	var header_height := top.offset_bottom - top.offset_top
	var description_top := header_height + 8.0

	description.offset_left = -panel_width * 0.5
	description.offset_right = panel_width * 0.5
	description.offset_top = description_top
	description.offset_bottom = description_top + panel_height
