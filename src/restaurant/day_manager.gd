extends Node3D
class_name DayManager

const GAME_OVER_SCENE := preload("res://src/ui/game_over/GameOver.tscn")
const THANKS_FOR_PLAYING = preload("res://src/ui/ThanksForPlaying.tscn")

const MUD_DAGORED = preload("uid://dibhfexgjqvj")
const CHILL_BGM = preload("res://src/music/honey_jam.tres")

@export var last_customer_offset := 5.0
@export var early_finish_delay := 2.0
@export var fade_duration := 2.0
var num_lives: int = 1
var current_time: float = 0
var total_duration: float
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
	# ignore customer types for now
	self.num_customers = len(arrivals)
	current_time = 0
	total_duration = timings.back().arrival_time + last_customer_offset
	customers_to_serve = num_customers
	current_customers = 0
	
	setup_finished.emit()

func _process(delta):
	if not day_started:
		return
	current_time += delta
	if current_customers == num_customers:
		return
	if (current_time >= timings[current_customers].arrival_time):
		# Remove this randomization of spawning customer after upgrades of
		# customers is implemented
		var customer_string_names = [
			&"",
			&"VIP",
			&"Impatient",
			&"FoodCritic",
			&"Hobo",
		]
		spawn_customer.emit(customer_string_names.pick_random())
		
		# Then uncomment this
		# spawn_customer.emit(timings[current_customers].customer_type)
		current_customers += 1

func _ready() -> void:
	RestaurantManager.angry_customer_left.connect(_on_angry_customer_left)
	RestaurantManager.customer_removed.connect(_on_customer_removed)
	AudioManager.play_bgm(CHILL_BGM)

func _on_customer_removed():
	customers_to_serve -= 1
	if customers_to_serve <= 0:
		if num_lives > 0:
			if current_time < total_duration:
				await get_tree().create_timer(early_finish_delay).timeout
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
