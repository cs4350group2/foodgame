extends Node3D
class_name PatienceBar

@export var progress_bar: TextureProgressBar

func set_patience(min_value: float, max_value: float, step: float) -> void:
	progress_bar.min_value = min_value
	progress_bar.max_value = max_value
	if step <= 0.0:
		step = (max_value - min_value) / 100.0 # divide it into 100 steps
	progress_bar.step = step

func update_patience(value: float) -> void:
	progress_bar.value = value

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
	pass

func set_ordering() -> void:
	pass
