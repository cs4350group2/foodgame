extends CanvasLayer

var total_duration: float

@export var day_manager: DayManager

@onready var coins_label: Label = %MoneyLabel
@onready var timer_progress_bar: TextureProgressBar = %ProgressBar
@onready var start_day_prompt: Label = %StartDayPrompt
@onready var progress_container: HBoxContainer = %ProgressContainer
@onready var day_number: Label = %DayNumber

func get_key_to_action(input_name: StringName) -> String:
	var events = InputMap.action_get_events(input_name)
	for event in events:
		if event is InputEventKey:
			return OS.get_keycode_string(event.physical_keycode)
	return "LShift"

func _ready() -> void:
	_on_coins_updated(RunManager.current_run.coins)
	RunManager.current_run.coins_updated.connect(_on_coins_updated)
	RunManager.day_updated.connect(_on_day_update)

	day_manager.setup_finished.connect(_on_dm_setup_finish)
	day_manager.day_finished.connect(_on_day_finish)

	start_day_prompt.text = " Hit %s to open for the day!" \
		% get_key_to_action(&"start_day")

	_on_day_finish()
	_on_day_update(RunManager.current_run.current_day)

func _on_dm_setup_finish() -> void:
	total_duration = day_manager.total_duration
	timer_progress_bar.max_value = total_duration
	timer_progress_bar.step = total_duration / 1000
	timer_progress_bar.value = day_manager.current_time

	progress_container.visible = false
	start_day_prompt.visible = true
	set_process_input(true)

func _process(delta: float) -> void:
	timer_progress_bar.value = day_manager.current_time

func _on_coins_updated(amount: float):
	coins_label.text = "%d" % amount 

func start_day() -> void:
	if day_manager.day_started:
		return
	self.set_process_input(false)
	start_day_prompt.visible = false
	progress_container.visible = true
	day_manager.start_day()

func _on_day_update(day: int) -> void:
	day_number.text = "Day %d" % day

func _on_day_finish() -> void:
	progress_container.visible = false
	start_day_prompt.visible = false
	set_process_input(false)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("start_day"):
		start_day()
		get_viewport().set_input_as_handled()
