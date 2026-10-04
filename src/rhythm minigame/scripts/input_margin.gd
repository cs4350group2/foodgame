extends MarginContainer

@onready var input_judgment: Label = $InputJudgment
@onready var main: Node2D = $"../.."
@onready var timer: Timer = $InputJudgment/Timer

var tween : Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main.hit.connect(display_judgment)
	main.miss.connect(display_judgment)
	
	# text starts as invisible
	input_judgment.modulate.a = 0.0

func display_judgment(indicator_text : String):
	input_judgment.text = indicator_text
	
	# set pivot offset to midpoint of text
	input_judgment.pivot_offset = input_judgment.size / 2.0
	
	if tween and tween.is_running():
		tween.kill()

	tween = create_tween()
	
	input_judgment.modulate.a = 0.0
	
	# slight enlargement to give "punch-y" effect on new judgment
	input_judgment.scale = Vector2(1.18, 1.18) 
	
	# appear almost instantly
	tween.tween_property(input_judgment, "modulate:a", 1.0, 0.01)
	
	# scale back to original text size
	tween.tween_property(input_judgment, "scale", Vector2.ONE, 0.03)
	
	# wait 0.4 seconds if not overridden by other judgments
	tween.tween_interval(0.4)
	
	# become invisible immediately afterwards
	tween.tween_property(input_judgment, "modulate:a", 0.0, 0.0)
	
	
