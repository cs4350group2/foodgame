extends Node3D
class_name PatienceBar

const ordering_overlay := preload("res://assets/ui/circle bars/32x32/32x32 circle bar progress orange.png")
const waiting_overlay := preload("res://assets/ui/circle bars/32x32/32x32 circle bar progress red.png")

@export var progress_bar: TextureProgressBar
@export_range(0.0, 1.0) var warning_percentage: float = 0.25
@export var warning_progress_tint: Color
@export var animation_duration: float

@export var ordering_icon: Texture2D
@export var ordering_tint: Color

@export var waiting_icon: Texture2D
@export var waiting_tint: Color

@export var icon: TextureRect


var blink_tween: Tween
var warning_active := false
@onready var original_under_tint: Color = progress_bar.tint_under
@onready var original_progress_tint: Color = progress_bar.tint_progress

func _set_icon_color(color: Color) -> void:
	icon.material.set_shader_parameter("icon_color", color)

func set_patience(min_value: float, max_value: float, step: float) -> void:
	progress_bar.min_value = min_value
	progress_bar.max_value = max_value
	if step <= 0.0:
		step = (max_value - min_value) / 100.0 # divide it into 100 steps
	progress_bar.step = step

func update_patience(value: float) -> void:
	progress_bar.value = value

	var progress_percentage := (value - progress_bar.min_value) / (progress_bar.max_value - progress_bar.min_value)
	if progress_percentage >= warning_percentage and warning_active:
		warning_active = false
		_stop_warning()
	elif progress_percentage < warning_percentage and not warning_active:
		warning_active = true
		_start_warning()

func _stop_warning() -> void:
	if blink_tween:
		blink_tween.kill()
	progress_bar.tint_under = original_under_tint
	progress_bar.tint_progress = original_progress_tint

func _start_warning() -> void:
	if blink_tween:
		blink_tween.kill()
	blink_tween = create_tween().set_loops()
	blink_tween.tween_property(
		progress_bar, "tint_progress",
		warning_progress_tint, animation_duration
	)
	blink_tween.tween_property(
		progress_bar, "tint_progress",
		original_progress_tint, animation_duration
	)


func set_state(state: Customer.State):
	match state:
		Customer.State.WAITING_FOR_FOOD:
			visible = true
			set_waiting_for_food()
		Customer.State.ORDERING:
			visible = true
			set_ordering()
		Customer.State.SITTING:
			return
		_:
			visible = false

func set_sitting() -> void:
	pass

func set_waiting_for_food() -> void:
	progress_bar.texture_progress = waiting_overlay
	icon.texture = waiting_icon
	_set_icon_color(waiting_tint)

func set_ordering() -> void:
	progress_bar.texture_progress = ordering_overlay
	icon.texture = ordering_icon
	_set_icon_color(ordering_tint)
