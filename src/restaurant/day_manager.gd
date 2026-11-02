extends Node3D
class_name DayManager

const GAME_OVER_SCENE := preload("res://src/ui/game_over/GameOver.tscn")
const THANKS_FOR_PLAYING = preload("res://src/ui/ThanksForPlaying.tscn")

const MUD_DAGORED = preload("uid://dibhfexgjqvj")
const CHILL_BGM = preload("res://src/music/honey_jam.tres")

@export var fade_duration := 2.0
var num_lives: int = 1
var current_time: float = 0
var final_wave_start_time: float
var wave_start_times: Array[float] = []
var num_customers: int
# this allows us to have non-uniform customer behaviors
var timings: Array[CustomerArrival]
var current_customers: int
var customers_to_serve: int
var day_started: bool = false

# signal for the customerspawner to ingest
signal spawn_customer(customer_type: StringName)
signal setup_finished()

signal day_starting()
signal day_finished()

func setup(arrivals: Array[CustomerArrival]):
	assert(len(arrivals) > 0)
	timings = arrivals.duplicate()
	self.num_customers = len(arrivals)
	current_time = 0
	# A schedule without waves uses the last arrival as its timer endpoint
	final_wave_start_time = timings.back().arrival_time
	wave_start_times.clear()
	var last_wave_index := -1
	for arrival in timings:
		if arrival.wave_index > last_wave_index:
			last_wave_index = arrival.wave_index
			wave_start_times.append(arrival.arrival_time)
			final_wave_start_time = arrival.arrival_time
	customers_to_serve = num_customers
	current_customers = 0
	
	setup_finished.emit()

func _process(delta):
	if not day_started:
		return
	current_time += delta
	while current_customers < num_customers \
			and current_time >= timings[current_customers].arrival_time:
		spawn_customer.emit(timings[current_customers].customer_type)
		current_customers += 1

func _ready() -> void:
	RestaurantManager.angry_customer_left.connect(_on_angry_customer_left)
	RestaurantManager.customer_removed.connect(_on_customer_removed)
	AudioManager.play_bgm(CHILL_BGM)

func _on_customer_removed():
	customers_to_serve -= 1
	if customers_to_serve <= 0:
		if num_lives > 0:
			trigger_level_complete()

func _on_angry_customer_left():
	num_lives -= 1
	if num_lives <= 0:
		trigger_game_over()

func start_day() -> void:
	day_starting.emit()

	day_started = true

	await AudioManager.fade_out_bgm(3.0)
	AudioManager.play_bgm(MUD_DAGORED)

func trigger_level_complete() -> void:
	day_started = false
	day_finished.emit()

	await AudioManager.fade_out_bgm(3.0)
	AudioManager.play_bgm(CHILL_BGM)

	RunManager.level_complete()

func trigger_game_over():
	var overlay := CanvasLayer.new()
	overlay.layer = 100
	add_child(overlay)
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	overlay.add_child(fade)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(fade, "color:a", 1.0, fade_duration)
	tween.tween_property(AudioManager.bgm_player, "pitch_scale",
		0.05, fade_duration)
	await tween.finished
	AudioManager.stop_bgm()
	AudioManager.bgm_player.pitch_scale = 1.0
	var error := get_tree().change_scene_to_packed(GAME_OVER_SCENE)
	if error != OK:
		push_error("Could not open GameOver scene: %s" % error_string(error))
