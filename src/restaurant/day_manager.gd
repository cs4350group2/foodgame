extends Node3D
class_name DayManager

const GAME_OVER_SCENE := preload("res://src/ui/GameOver.tscn")
const THANKS_FOR_PLAYING = preload("res://src/ui/ThanksForPlaying.tscn")

const MUD_DAGORED = preload("uid://dibhfexgjqvj")

var fade_duration := 2.0
var num_lives: int = 1
var current_time: float = 0
var total_duration: float
var num_customers: int
# this allows us to have non-uniform customer behaviors
var timings: Array[float]
var current_customers: int
var customers_to_serve: int

# signal for the customerspawner to ingest
signal spawn_customer()
signal setup_finished()

# Called when the node enters the scene tree for the first time.
func setup_with_uniform_arrival(time_to_first_customer: float, 
	day_duration: float, num_customers: int):
	assert(num_customers > 0)
	self.num_customers = num_customers
	timings.clear()
	var spacing := day_duration / num_customers
	for i in range(num_customers):
		timings.append(time_to_first_customer + (i * spacing))
	current_time = 0
	current_customers = 0
	# use the last timing in case of any FP issues
	total_duration = timings.back()
	customers_to_serve = num_customers
	print("total_duration: ", total_duration)
	print("time_to_first: ", time_to_first_customer)
	
	setup_finished.emit()

func _process(delta):
	current_time += delta
	if current_customers == num_customers:
		return
	if (current_time >= timings[current_customers]):
		spawn_customer.emit()
		current_customers += 1

func _ready() -> void:
	RestaurantManager.angry_customer_left.connect(_on_angry_customer_left)
	RestaurantManager.customer_removed.connect(_on_customer_removed)
	if AudioManager.bgm_player.playing:
		AudioManager.bgm_player.pitch_scale = 1.0
	else:
		AudioManager.play_bgm(MUD_DAGORED)

func _on_customer_removed():
	customers_to_serve -= 1
	if customers_to_serve <= 0:
		if num_lives > 0:
			trigger_level_complete()

func _on_angry_customer_left():
	num_lives -= 1
	if num_lives <= 0:
		trigger_game_over()

func trigger_level_complete():
	get_tree().change_scene_to_packed(THANKS_FOR_PLAYING)

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
