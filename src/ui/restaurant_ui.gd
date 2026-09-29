extends CanvasLayer

@export var money_manager: Node # stub for now
@export var game_timer: Node # stub for now

@onready var coins_label: Label = $ViewportContainer/MoneyMarginContainer/HBoxContainer/MoneyLabel
@onready var timer_progress_bar: ProgressBar = $ViewportContainer/TimerMarginContainer/ProgressBar

# TODO: Hook up signals
func _ready() -> void:
	RestaurantManager.coins_updated.connect(_on_coins_updated)
	
func _on_coins_updated(amount: int):
	coins_label.text = str(amount)

# note: should we set max_value to actual time?
func _on_timer_change(progress: float):
	timer_progress_bar.value = progress
