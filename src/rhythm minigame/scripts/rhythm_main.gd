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
@onready var arrow_generator_left : Node2D = $ArrowGeneratorLeft
@onready var arrow_generator_right : Node2D = $ArrowGeneratorRight
@onready var arrow_generator_up: Node2D = $ArrowGeneratorUp
@onready var arrow_generator_down: Node2D = $ArrowGeneratorDown

# judgment arrows (static white arrows on the judgment line)
@onready var judgment_arrow_left: Node2D = $JudgmentHUD/JudgmentArrowLeft
@onready var judgment_arrow_right: Node2D = $JudgmentHUD/JudgmentArrowRight
@onready var judgment_arrow_up: Node2D = $JudgmentHUD/JudgmentArrowUp
@onready var judgment_arrow_down: Node2D = $JudgmentHUD/JudgmentArrowDown

# plays the note hit effect
@onready var hit_effect_player: AudioStreamPlayer = $HitEffectPlayer

# results screen that is shown after the minigame ends
@onready var rhythm_result_screen: Control = $CanvasLayer/RhythmResultScreen

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

const ALL_NIGHT_BURGUNDY_TRIMMED_ = preload("uid://bgx2ev5nxatk8") # rhythm minigame burger track 
const HARLEM_HEAT_DAGORED_TRIMMED_ = preload("uid://drtgu1sgw60te") # rhythm minigame steak track
const PIRATE_TAVERN_MAGIKSOLO_TRIMMED_ = preload("uid://3tm476mhsfm7") # rhythm minigame stew track
const MUD_DAGORED = preload("uid://dibhfexgjqvj") # BGM 

# more variables to make code look a bit cleaner for now
var bgm : AudioData = MUD_DAGORED
var chart_song : AudioData
var chart_path : String
var dish_string: String = "burger"

func _ready() -> void:
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
		_:
			# fallback when doing standalone testing
			chart_song = PIRATE_TAVERN_MAGIKSOLO_TRIMMED_
			chart_path = "res://assets/rhythm minigame/charts/pirate_tavern.fsc"
			
	rhythm_result_screen.visible = false
	
	var speed_mult : float = bgm.bpm / chart_song.bpm # since this happens before audio starts playing and the values are set
	
	chart_notes = load_rhythm_chart(chart_path, speed_mult) 
	
	# include a slight delay before the cooking start text pops up
	await get_tree().create_timer(1.0).timeout
	
	cooking_start.emit()
	
	if dish_string == "burger" or dish_string == "steak": # hide "up" and "down" lanes for All Night and Harlem Heat charts
		hide_lane.emit("up")
		hide_lane.emit("down")
		
	
	# wait 4 seconds before the chart begins, then starts the minigame
	await get_tree().create_timer(4.5).timeout
	
	current_time_ms = -note_lead_time_ms # this is to prevent the first few notes from triggering early
	is_game_started = true
	
	await AudioManager.rm_player.finished
	
	cooking_end.emit()
	
	# wait for the COOKING END! text to fade out fully
	await get_tree().create_timer(4.0).timeout 
	
	rhythm_result_screen.perfect_label.text += str(num_perfects) + "\n"
	rhythm_result_screen.good_label.text += str(num_goods) + "\n"
	rhythm_result_screen.miss_label.text += " " + str(num_misses)
	
	player_score = num_perfects * 100 + num_goods * 50 
	max_score = (num_perfects + num_goods + num_misses) * 100
	dish_quality = snapped(float(player_score) / float(max_score) * 100, 0.01) # we express dish quality as a percent number
	rhythm_result_screen.dish_quality_score.text = str(dish_quality) + "%"
	
	results_display.emit()

func _process(delta: float) -> void:
	if not is_game_started:
		return
	
	if not is_audio_started:
		current_time_ms += delta * 1000
	
		if current_time_ms >= 0.0:
			is_audio_started = true
			AudioManager.set_rm_volume(0.5) # this value can be modified between 0 and 1 inclusive, i just felt that the original volume was quite loud
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
	var lane_array: Array = active_notes[lane_name]
	
	if lane_array.is_empty():
		return
		
	var closest_arrow: Node2D = lane_array[0] # this is the oldest live arrow

	var time_diff: float = abs(adjusted_time_ms - closest_arrow.target_hit_time_ms)
	
	if time_diff > good_time_window_ms:
		return
	
	# successful hit (good/perfect)
	judgment_arrow.animation_player.stop()
	judgment_arrow.animation_player.play("successful_hit")
	hit_effect_player.play()
	
	# input judgments (timings can still be tweaked in the future if needed)
	if time_diff <= perfect_time_window_ms:
		hit.emit("PERFECT")
		num_perfects += 1
	
	else:
		hit.emit("GOOD")
		num_goods += 1
	
	remove_arrow(closest_arrow, lane_name)

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
			remove_arrow(oldest_arrow, lane_name)

func spawn_note_from_data(note_data: Dictionary) -> Arrow:
	var lane_name: String = LANE_MAP[int(note_data["lane"])]
	var hit_time_ms: float = note_data["time"]
	
	var new_arrow: Arrow
	
	match lane_name:
		# generates a note based on the lane
		"Left":
			new_arrow = arrow_generator_left.make_arrow()
		"Down":
			new_arrow = arrow_generator_down.make_arrow()
		"Up":
			new_arrow = arrow_generator_up.make_arrow()
		"Right":
			new_arrow = arrow_generator_right.make_arrow()
	
	new_arrow.target_hit_time_ms = hit_time_ms
	active_notes[lane_name].append(new_arrow)
	
	if new_arrow.connector_line:
		# by default, hide line connector
		new_arrow.connector_line.visible = false
	
	return new_arrow
				
func remove_arrow(arrow: Arrow, lane_name: String) -> void:
	active_notes[lane_name].erase(arrow)
	arrow.free()

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
