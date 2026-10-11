extends Node2D

# unspawned notes from chart JSON data
var chart_notes: Array = []

# arrow notes currently on screen, by lane
var active_notes: Dictionary = {
	"Left": [],
	"Down": [],
	"Up": [],
	"Right": []
}

# lane mapping from fluXis lane integers to lane names
const LANE_MAP: Dictionary = {
	1: "Left",
	2: "Down",
	3: "Up",
	4: "Right"
}

var current_time_ms: float = 0.0
var bgm_playback_position: float

@export var note_lead_time_ms: float = 1000.0 # each note takes 1 full second to fall from top of screen to judgment line (if arrow_speed in parent_arrow.gd is changed, this should be changed too)

# offset is negative -> notes arrive EARLIER than audio
# offset is positive -> notes arrive LATER than audio
# limit offset between -150ms and +150ms to protect hit windows
@export_range(-150.0, 150.0, 1.0) var audio_offset_ms: float = 0.0:
	set(value):
		audio_offset_ms = clampf(value, -150.0, 150.0)
		
# adjusted time taken from adding offset to current time
var adjusted_time_ms: float:
	get:
		return current_time_ms + audio_offset_ms

@export var perfect_time_window_ms = 75
@export var good_time_window_ms = 150

# arrow generators
@onready var arrow_generator_left: Node2D = $JudgmentHUD/ArrowGenerators/ArrowGeneratorLeft
@onready var arrow_generator_down: Node2D = $JudgmentHUD/ArrowGenerators/ArrowGeneratorDown
@onready var arrow_generator_up: Node2D = $JudgmentHUD/ArrowGenerators/ArrowGeneratorUp
@onready var arrow_generator_right: Node2D = $JudgmentHUD/ArrowGenerators/ArrowGeneratorRight

# judgment arrows (static white arrows on the judgment line)
@onready var judgment_arrow_left: Node2D = $JudgmentHUD/JudgmentArrowLeft
@onready var judgment_arrow_right: Node2D = $JudgmentHUD/JudgmentArrowRight
@onready var judgment_arrow_up: Node2D = $JudgmentHUD/JudgmentArrowUp
@onready var judgment_arrow_down: Node2D = $JudgmentHUD/JudgmentArrowDown

# hit effect player (plays the note hit effect)
@onready var hit_effect_player: AudioStreamPlayer = $SFX/HitEffectPlayer

# results screen that is shown after the minigame ends
@onready var rhythm_result_screen_v2: Control = $RhythmUI/UIRoot/RhythmResultScreenV2

# signals to handle hit/miss
signal hit(input_judgment : String)
signal miss(input_judgment : String)

# signals for cooking start/cooking end text, and results screen appearance
signal cooking_start
signal cooking_end
signal results_display
signal return_to_restaurant(dish_quality: float)
signal hide_lane(lane_name : String)

# variables to display on results screen
var num_perfects : int = 0
var num_goods : int = 0
var num_misses : int = 0
var player_score : int
var max_score : int
var dish_quality : float 

# booleans tracking whether minigame/audio has started
var is_game_started : bool = false
var is_audio_started : bool = false

const _15_SECONDS_NO_SOUND = preload("uid://cp8g3egjiix00") # 15-second soundless track for testing, can ignore

const ALL_NIGHT_BURGUNDY_TRIMMED_ = preload("uid://bgx2ev5nxatk8") # rhythm minigame burger track 
const HARLEM_HEAT_DAGORED_TRIMMED_ = preload("uid://drtgu1sgw60te") # rhythm minigame steak track
const PIRATE_TAVERN_MAGIKSOLO_TRIMMED_ = preload("uid://3tm476mhsfm7") # rhythm minigame stew track
const MUD_DAGORED = preload("uid://dibhfexgjqvj") # BGM 

# more variables to make code look a bit cleaner for now
var bgm : AudioData = MUD_DAGORED
var chart_song : AudioData
var chart_path : String
var dish_string: String = "test_gold"

func _ready() -> void:
	audio_offset_ms = AudioManager.audio_offset_ms
	AudioManager.audio_offset_changed.connect(_on_offset_change)
	match dish_string:
		"burger":
			chart_song = ALL_NIGHT_BURGUNDY_TRIMMED_
			chart_path = "res://assets/rhythm minigame/charts/all_night.fsc"
		"steak":
			chart_song = HARLEM_HEAT_DAGORED_TRIMMED_
			chart_path = "res://assets/rhythm minigame/charts/harlem_heat(2lane).fsc" # can change to the modified 4-lane if needed
		"stew":
			chart_song = PIRATE_TAVERN_MAGIKSOLO_TRIMMED_
			chart_path = "res://assets/rhythm minigame/charts/pirate_tavern.fsc"
		"test_gold":
			chart_song = _15_SECONDS_NO_SOUND
			chart_path = "res://assets/rhythm minigame/charts/test_gold_notes.fsc"
		_:
			# fallback when doing standalone testing
			chart_song = PIRATE_TAVERN_MAGIKSOLO_TRIMMED_
			chart_path = "res://assets/rhythm minigame/charts/pirate_tavern.fsc"
			
	rhythm_result_screen_v2.visible = false
	
	var speed_mult : float = bgm.bpm / chart_song.bpm # since this happens before audio starts playing and the values are set
	
	chart_notes = load_rhythm_chart(chart_path, speed_mult) 
	
	# include a slight delay before the cooking start text pops up
	await get_tree().create_timer(1.0).timeout
	
	cooking_start.emit()
	
	if dish_string == "burger" or dish_string == "steak": # hide "up" and "down" lanes for All Night and Harlem Heat charts
		hide_lane.emit("up")
		hide_lane.emit("down")
		
	bgm_playback_position = AudioManager.get_bgm_playback_position()
	await AudioManager.fade_out_bgm(4.5)
	
	current_time_ms = -note_lead_time_ms # this is to prevent the first few notes from triggering early
	is_game_started = true
	
	await AudioManager.rm_player.finished
	
	cooking_end.emit()
	
	# wait for the COOKING END! text to fade out fully
	await get_tree().create_timer(4.0).timeout 
	AudioManager.bgm_player.play(bgm_playback_position)
	
	rhythm_result_screen_v2.perfect_count_label.text = str(num_perfects)
	rhythm_result_screen_v2.good_count_label.text = str(num_goods)
	rhythm_result_screen_v2.miss_count_label.text = str(num_misses)
	
	player_score = num_perfects * 100 + num_goods * 75 
	max_score = (num_perfects + num_goods + num_misses) * 100
	dish_quality = snapped(float(player_score) / float(max_score) * 100, 0.01) # we express dish quality as a float percentage
	rhythm_result_screen_v2.dish_quality_score_label.text = str(dish_quality) + "%"
	
	results_display.emit()

func _process(delta: float) -> void:
	if not is_game_started:
		return
	
	if not is_audio_started:
		current_time_ms += delta * 1000
	
		if current_time_ms >= 0.0:
			is_audio_started = true
			AudioManager.set_rm_volume(0.2) # this value can be modified between 0 and 1 inclusive, i just felt that the original volume was quite loud
			
			AudioManager.play_rhythm_to_target_bpm(chart_song, bgm.bpm, 0.0) 
			current_time_ms = 0.0
	
	else:
		var pitch: float = AudioManager.rm_player.pitch_scale
		current_time_ms = (AudioManager.get_rhythm_playback_position() / pitch) * 1000.0
		
	while not chart_notes.is_empty() and (chart_notes[0]["time"] <= adjusted_time_ms + note_lead_time_ms):
		var is_chord: bool = chart_notes.size() >= 2 and chart_notes[0]["time"] == chart_notes[1]["time"]
		
		if is_chord:
			# pop both notes together and connect them with line
			var note_a_data: Dictionary = chart_notes.pop_front()
			var note_b_data: Dictionary = chart_notes.pop_front()
		
			var arrow_a: Arrow = spawn_note_from_data(note_a_data)
			var arrow_b: Arrow = spawn_note_from_data(note_b_data)
	
			arrow_a.setup_connector(arrow_b)
		else:
			var note_data: Dictionary = chart_notes.pop_front()
			spawn_note_from_data(note_data)
			
	check_missed_notes(adjusted_time_ms)
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("rhythm_left"):
		check_hit("Left", judgment_arrow_left)
		
	if event.is_action_pressed("rhythm_right"):
		check_hit("Right", judgment_arrow_right)
	
	if event.is_action_pressed("rhythm_up"):
		check_hit("Up", judgment_arrow_up)
	
	if event.is_action_pressed("rhythm_down"):
		check_hit("Down", judgment_arrow_down)

func check_hit(lane_name: String, judgment_arrow: Node2D) -> void:
	# always play judgment arrow animation regardless of input judgment
	judgment_arrow.animation_player.stop()
	judgment_arrow.animation_player.play("on_player_input")
	
	var lane_array: Array = active_notes[lane_name]
	
	if lane_array.is_empty():
		return
		
	var closest_arrow: Node2D = lane_array[0] # this is the oldest live arrow

	var time_diff: float = abs(adjusted_time_ms - closest_arrow.target_hit_time_ms)
	
	if time_diff > good_time_window_ms:
		return
	
	# hit effect only plays on successful hit (good/perfect)
	closest_arrow.hit_effect_player.play()
	
	# input judgments (timings can still be tweaked in the future if needed)
	if time_diff <= perfect_time_window_ms:
		hit.emit("PERFECT")
		num_perfects += 1
	
	else:
		hit.emit("GOOD")
		num_goods += 1
	
	active_notes[lane_name].erase(closest_arrow)
	closest_arrow.play_hit_anim()

func check_missed_notes(adjusted_ms: float) -> void:
	# don't check notes too early
	if not is_audio_started or current_time_ms < 0.0:
		return
		
	for lane_name in active_notes.keys():
		var lane_array: Array = active_notes[lane_name]
		if lane_array.is_empty():
			continue
			
		var oldest_arrow: Node2D = lane_array[0]
		
		if adjusted_ms > (oldest_arrow.target_hit_time_ms + good_time_window_ms):
			miss.emit("MISS")
			num_misses += 1
			active_notes[lane_name].erase(oldest_arrow)
			oldest_arrow.queue_free()

func spawn_note_from_data(note_data: Dictionary) -> Arrow:
	# note_data is the FIRST ELEMENT (representing the front-most note) of the HitObjects array returned from load_rhythm_chart
	var lane_name: String = LANE_MAP[int(note_data["lane"])]
	var generator: Node2D = get("arrow_generator_" + lane_name.to_lower())
	
	var hit_time_ms: float = note_data["time"]
	
	var new_arrow: Arrow = generator.make_note_from_data(note_data)
				
	new_arrow.target_hit_time_ms = note_data["time"]
	active_notes[lane_name].append(new_arrow)
	
	if new_arrow.connector_line:
		# by default, hide line connector
		new_arrow.connector_line.visible = false
	
	return new_arrow

func load_rhythm_chart(file_path: String, speed_mult : float) -> Array:
	# parses fluXis chart text data and returns the HitObjects array (array of notes)
	if not FileAccess.file_exists(file_path):
		print("Chart file not found!")
		return []
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_string) != OK:
		print("Failed to load rhythm chart as JSON.")
		return []
		
	var data = json.data	
	var parsed_notes: Array = []
	
	var raw_notes: Array = data.get("HitObjects", [])
	
	for note in raw_notes:
		# scales each note's timestamp according to the speed multiplier
		var note_data : Dictionary = note.duplicate()
		
		note_data["time"] = float(note["time"]) / speed_mult 
		parsed_notes.append(note_data)
	
	return parsed_notes

func _on_offset_change(val: float):
	audio_offset_ms = val
