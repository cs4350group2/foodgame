extends Node2D

var left : bool = false
var right : bool = false

@onready var input_detector : Area2D = $InputDetector
@onready var arrow_generator_left : Node2D = $ArrowGeneratorLeft
@onready var arrow_generator_right : Node2D = $ArrowGeneratorRight
@onready var judgment_arrow_left : Node2D = $JudgmentArrow
@onready var judgment_arrow_right : Node2D = $JudgmentArrow2
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var main_animation_player: AnimationPlayer = $AnimationPlayer
@onready var hit_effect_player: AudioStreamPlayer = $HitEffectPlayer
@onready var miss_area: Area2D = $MissArea
@onready var rhythm_result_screen: Control = $CanvasLayer/RhythmResultScreen

signal hit(input_judgment : String)
signal miss(input_judgment : String)

var num_perfects : int = 0
var num_goods : int = 0
var num_misses : int = 0
var player_score : int
var max_score : int
var dish_quality : float 

func _ready() -> void:
	rhythm_result_screen.visible = false
	main_animation_player.play("test song")
	
	await main_animation_player.animation_finished
	rhythm_result_screen.perfect_label.text += str(num_perfects) + "\n"
	rhythm_result_screen.good_label.text += str(num_goods) + "\n"
	rhythm_result_screen.miss_label.text += " " + str(num_misses)
	
	player_score = num_perfects * 100 + num_goods * 50 
	max_score = (num_perfects + num_goods + num_misses) * 100
	dish_quality = snapped(float(player_score) / float(max_score) * 100, 0.01) # we express dish quality as a percent number
	rhythm_result_screen.dish_quality_score.text = str(dish_quality) + "%"
	
	rhythm_result_screen.visible = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		check_hit("Left", judgment_arrow_left)
		
	if event.is_action_pressed("ui_right"):
		check_hit("Right", judgment_arrow_right)
		

func check_hit(lane_name: String, judgment_arrow: Node2D) -> void:
	for area in input_detector.get_overlapping_areas():
		var arrow_node = area.get_parent()
			
		if area.name.contains(lane_name):
			judgment_arrow.animation_player.stop()
			judgment_arrow.animation_player.play("successful_hit") 
			hit_effect_player.play() # plays the hit sound effect
			
			send_to_ui(area) # handles the input judgment separately in a different function
			
			arrow_node.free() # arrow is deleted after hit
			
			return

func send_to_ui(area : Area2D):
	# this function handles "PERFECT" and "GOOD" hits
	# a "MISS" is instead handled below in the _on_miss_area_area_entered() signal function
	if area.name.contains("Perfect"):
		hit.emit("PERFECT")
		num_perfects += 1
			
	if area.name.contains("Good"):
		hit.emit("GOOD")
		num_goods += 1
		
func _on_miss_area_area_entered(area: Area2D) -> void:
	# get rid of falling arrows if they fall into the miss area 
	if area.name.contains("Left") or area.name.contains("Right"):
		area.get_parent().free()
		miss.emit("MISS")
		num_misses += 1
		
