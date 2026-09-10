extends Node2D

# song to be played in the minigame
var chart_song: String = ""

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

@export var perfect_time_window_ms = 100
@export var good_time_window_ms = 200 

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
signal hide_lane(lane_name : String)

# variables to display on results screen
var num_perfects : int = 0
var num_goods : int = 0
var num_misses : int = 0
var player_score : int
var max_score : int
var dish_quality : float 

var chart_stream : AudioStream

# booleans tracking whether minigame/audio has started
var is_game_started : bool = false
var is_audio_started : bool = false

const ALL_NIGHT_BURGUNDY_TRIMMED_ = preload("uid://bgx2ev5nxatk8") # rhythm minigame audio track (testing only one for now)
const MUD_DAGORED = preload("uid://dibhfexgjqvj") # BGM 

func _ready() -> void:
	rhythm_result_screen.visible = false
	
	var speed_mult : float = MUD_DAGORED.bpm / ALL_NIGHT_BURGUNDY_TRIMMED_.bpm # since this happens before audio starts playing and the values are set
	
	var chart_path: String = "res://assets/rhythm minigame/charts/all_night.fsc"
	
	chart_notes = load_rhythm_chart(chart_path, speed_mult) # for testing purposes, will have to hardcode specific cases in the future
	
	# include a slight delay before the cooking start text pops up
	await get_tree().create_timer(1.0).timeout
	
	cooking_start.emit()
	
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
			# AudioManager.play_rhythm_and_match_bgm(ALL_NIGHT_BURGUNDY_TRIMMED_, 0.0) 
			AudioManager.set_rm_volume(0.5)
			AudioManager.play_rhythm_to_target_bpm(ALL_NIGHT_BURGUNDY_TRIMMED_, MUD_DAGORED.bpm, 0.0) 
			current_time_ms = 0.0
	
	else:
		var pitch: float = AudioManager.rm_player.pitch_scale
		current_time_ms = (AudioManager.get_rhythm_playback_position() / pitch) * 1000.0
		
	while not chart_notes.is_empty() and (chart_notes[0]["time"] <= current_time_ms + note_lead_time_ms):
		var note_data: Dictionary = chart_notes.pop_front()
		spawn_note_from_data(note_data)
	
	check_missed_notes(current_time_ms)
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		check_hit("Left", judgment_arrow_left)
		
	if event.is_action_pressed("ui_right"):
		check_hit("Right", judgment_arrow_right)
	
	if event.is_action_pressed("ui_up"):
		check_hit("Up", judgment_arrow_up)
	
	if event.is_action_pressed("ui_down"):
		check_hit("Down", judgment_arrow_down)

func check_missed_notes(current_ms: float) -> void:
	for lane_name in active_notes.keys():
		var lane_array: Array = active_notes[lane_name]
		if lane_array.is_empty():
			continue
			
		var oldest_arrow: Node2D = lane_array[0]
		
		if current_ms > (oldest_arrow.target_hit_time_ms + good_time_window_ms):
			miss.emit("MISS")
			num_misses += 1
			remove_arrow(oldest_arrow, lane_name)

func spawn_note_from_data(note_data: Dictionary) -> void:
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
	
func check_hit(lane_name: String, judgment_arrow: Node2D) -> void:
	var lane_array: Array = active_notes[lane_name]
	
	if lane_array.is_empty():
		return
		
	var closest_arrow: Node2D = lane_array[0] # this is the oldest live arrow

	var time_diff: float = abs(current_time_ms - closest_arrow.target_hit_time_ms)
	
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
