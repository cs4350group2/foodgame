class_name CookingTimerBar
extends Node3D

@export var progress_bar: TextureProgressBar
var total_duration: float

func _ready() -> void:
	visible = false
	progress_bar.min_value = 0.0
	progress_bar.value = 0.0

func start_timer(duration: float) -> void:
	total_duration = maxf(duration, 0.01)
	progress_bar.max_value = total_duration
	progress_bar.value = 0.0
	visible = true

func update_timer(time_remaining: float) -> void:
	progress_bar.value = clampf(
		total_duration - time_remaining,
		progress_bar.min_value,
		progress_bar.max_value
	)

func stop_timer() -> void:
	progress_bar.value = 0.0
	visible = false
