extends CanvasLayer

var total_duration: float

@export var day_manager: DayManager

@onready var coins_label: Label = %MoneyLabel
@onready var timer_progress_bar: ProgressBar = %ProgressBar

func _ready() -> void:
	RestaurantManager.coins_updated.connect(_on_coins_updated)
	day_manager.setup_finished.connect(_on_dm_setup_finish)
	# restaurant might set up before we connect, so we just call the function outright
	_on_dm_setup_finish()

func _on_dm_setup_finish():
	total_duration = day_manager.total_duration
	timer_progress_bar.max_value = total_duration
	timer_progress_bar.step = total_duration / 1000

func _process(delta: float) -> void:
	timer_progress_bar.value = day_manager.current_time

func _on_coins_updated(amount: int):
	coins_label.text = str(amount)
