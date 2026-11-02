class_name RestaurantUI
extends CanvasLayer

@export var day_manager: DayManager

@onready var coins_label: Label = %MoneyLabel
@onready var day_progress_slider: HSlider = %ProgressSlider
@onready var wave_markers: Control = %WaveMarkers
@onready var start_day_prompt: Label = %StartDayPrompt
@onready var progress_container: HBoxContainer = %ProgressContainer
@onready var day_number: Label = %DayNumber
@onready var controls_label: Label = %ControlsLabel
@onready var notification: Notification = $Notification

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
	day_progress_slider.resized.connect(_position_wave_markers)
	day_progress_slider.theme_changed.connect(_position_wave_markers)

	start_day_prompt.text = " Hit %s to open for the day!" \
		% get_key_to_action(&"start_day")

	controls_label.text = "HOLD [%s] ORDERS     [%s] PAUSE" % [
		get_key_to_action(&"show_orders"), get_key_to_action(&"pause_game")
	]

	_on_day_finish()
	_on_day_update(RunManager.current_run.current_day)

func _on_dm_setup_finish() -> void:
	day_progress_slider.max_value = day_manager.final_wave_start_time
	day_progress_slider.step = day_manager.final_wave_start_time / 1000
	day_progress_slider.value = day_manager.current_time
	_rebuild_wave_markers()

	progress_container.visible = false
	start_day_prompt.visible = true
	set_process_input(true)

func _rebuild_wave_markers() -> void:
	for marker in wave_markers.get_children():
		wave_markers.remove_child(marker)
		marker.queue_free()
	for i in range(day_manager.wave_start_times.size()):
		var marker := ColorRect.new()
		marker.name = "Wave%d" % (i + 1)
		marker.color = Color(1.0, 0.956863, 0.6098, 1.0)
		marker.size = Vector2(3.0, 50.0)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wave_markers.add_child(marker)
	_position_wave_markers()

func _position_wave_markers() -> void:
	var grabber_name := "grabber" if day_progress_slider.editable else "grabber_disabled"
	var grabber_size := day_progress_slider.get_theme_icon(grabber_name).get_size()
	var max_icon_size := day_progress_slider.get_theme_constant("grabber_max_size")
	if max_icon_size > 0 and maxf(grabber_size.x, grabber_size.y) > max_icon_size:
		grabber_size = (grabber_size * max_icon_size / maxf(grabber_size.x, grabber_size.y)).floor()
	var inset := 0.0 if day_progress_slider.get_theme_constant("center_grabber") else grabber_size.x / 2.0
	var track_width := maxf(day_progress_slider.size.x - 2.0 * inset, 0.0)
	for i in range(wave_markers.get_child_count()):
		var marker := wave_markers.get_child(i) as ColorRect
		var ratio := clampf(day_manager.wave_start_times[i] / day_manager.final_wave_start_time, 0.0, 1.0)
		if day_progress_slider.is_layout_rtl():
			ratio = 1.0 - ratio
		var center := inset + ratio * track_width
		marker.position = Vector2(
			clampf(center - marker.size.x / 2.0, 0.0, maxf(day_progress_slider.size.x - marker.size.x, 0.0)),
			(day_progress_slider.size.y - marker.size.y) / 2.0)

func _process(delta: float) -> void:
	day_progress_slider.value = day_manager.current_time

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
	day_number.text = "%d" % day

func _on_day_finish() -> void:
	progress_container.visible = false
	start_day_prompt.visible = false
	set_process_input(false)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("start_day"):
		start_day()
		get_viewport().set_input_as_handled()

func show_notification_top(message: String, show_description: bool = false, description_message: String = "") -> void:
	notification.show_top(message, show_description, description_message)

func show_notification_error_bottom(message: String) -> void:
	notification.show_error_bottom(message)

func show_side(message: String) -> void:
	notification.show_side(message)
