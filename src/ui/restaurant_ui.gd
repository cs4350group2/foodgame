extends CanvasLayer

@export var money_manager: Node # stub for now
@export var game_timer: Node # stub for now

@onready var money_label: Label = $ViewportContainer/MoneyMarginContainer/HBoxContainer/MoneyLabel
@onready var timer_progress_bar: ProgressBar = $ViewportContainer/TimerMarginContainer/ProgressBar

# TODO: Hook up signals
func _ready() -> void:
	pass
	
func _on_money_change(amount: int):
	money_label.text = str(amount)

# note: should we set max_value to actual time?
func _on_timer_change(time_left: float):
	timer_progress_bar.value = time_left
