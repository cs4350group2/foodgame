class_name Notification
extends CanvasLayer

@export var debug: bool = false
@export var side_label_node: PackedScene = preload("res://src/ui/notification/SideLabel.tscn")

@onready var top: Panel = $Top
@onready var error_bottom: Panel = $ErrorBottom
@onready var top_label: Label = $Top/Label
@onready var error_bottom_label: Label = $ErrorBottom/Label
@onready var side: VBoxContainer = $Side

const TOP_MIN_WIDTH := 400.0
const ERROR_MIN_WIDTH := 160.0
const TOP_HORIZONTAL_PADDING := 40.0
const TOP_VERTICAL_PADDING := 20.0
const VIEWPORT_SIDE_MARGIN := 20.0
const ERROR_BOTTOM_MARGIN := 108.0

var top_tween_reference = null
var error_bottom_tween_reference = null
var side_tween_reference = null
var show_top_description: bool = false

func _ready() -> void:
	top.modulate = Color(1, 1, 1, 0)
	error_bottom.modulate = Color(1, 1, 1, 0)

func show_top(message: String, show_description: bool = false, description_message: String = "") -> void:
	visible = true

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

func show_error_bottom(message: String) -> void:
	visible = true

	if error_bottom_tween_reference:
		error_bottom_tween_reference.kill()

	error_bottom_label.text = message
	_resize_error_bottom_to_text(message)

	if error_bottom_label:
		error_bottom.scale = Vector2(0.8, 0.8)
		error_bottom.modulate = Color(1, 1, 1, 0)

		error_bottom_tween_reference = create_tween().set_parallel(true)
		error_bottom_tween_reference.tween_property(error_bottom, "scale", Vector2(1, 1), 0.5)
		error_bottom_tween_reference.tween_property(error_bottom, "modulate", Color(1, 1, 1, 1), 0.5)

		error_bottom_tween_reference.chain().tween_interval(5)
		error_bottom_tween_reference.chain().tween_property(error_bottom, "modulate", Color(1, 1, 1, 0), 0.5)

func show_side(message: String) -> void:
	visible = true
	var side_label: Label = side_label_node.instantiate()
	side_label.text = message
	side_label.scale = Vector2(0.8, 0.8)
	side_label.modulate = Color(1, 1, 1, 0)
	side.add_child(side_label)

	# Keep each label's animation and hold independent from other side notifications.
	side_tween_reference = side_label.create_tween().set_parallel(true)
	var tween: Tween = side_tween_reference
	tween.tween_property(side_label, "scale", Vector2.ONE, 0.5)
	tween.tween_property(side_label, "modulate", Color.WHITE, 0.5)
	await tween.finished
	await get_tree().create_timer(4.0).timeout
	if not is_instance_valid(side_label):
		return

	side_tween_reference = side_label.create_tween().set_parallel(true)
	tween = side_tween_reference
	tween.tween_property(side_label, "scale", Vector2(0.8, 0.8), 0.5)
	tween.tween_property(side_label, "modulate", Color(1, 1, 1, 0), 0.5)
	await tween.finished
	if is_instance_valid(side_label):
		side_label.queue_free()

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


func _resize_error_bottom_to_text(message: String) -> void:
	var font := error_bottom_label.get_theme_font("font")
	var font_size := error_bottom_label.get_theme_font_size("font_size")
	var viewport_width := get_viewport().get_visible_rect().size.x
	var max_width := maxf(120.0, viewport_width - VIEWPORT_SIDE_MARGIN * 2.0)
	var text_width := font.get_multiline_string_size(
		message,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size
	).x
	var panel_width := minf(maxf(ERROR_MIN_WIDTH, text_width + TOP_HORIZONTAL_PADDING), max_width)
	var label_width := panel_width - TOP_HORIZONTAL_PADDING
	var text_size := font.get_multiline_string_size(
		message,
		HORIZONTAL_ALIGNMENT_CENTER,
		label_width,
		font_size
	)
	var panel_height := maxf(40.0, text_size.y + TOP_VERTICAL_PADDING)

	error_bottom.offset_left = -panel_width * 0.5
	error_bottom.offset_right = panel_width * 0.5
	error_bottom.offset_top = -ERROR_BOTTOM_MARGIN - panel_height
	error_bottom.offset_bottom = -ERROR_BOTTOM_MARGIN
