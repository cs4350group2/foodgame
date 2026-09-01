extends MarginContainer

@onready var input_judgment: Label = $InputJudgment
@onready var main: Node2D = $"../.."
@onready var timer: Timer = $InputJudgment/Timer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main.hit.connect(successful_hit)
	main.miss.connect(miss_hit)

func successful_hit(indicator_text : String):
	input_judgment.text = indicator_text
	timer.start()
	await timer.timeout
	input_judgment.text = "" # removes the judgment text after timer duration

func miss_hit(indicator_text : String):
	input_judgment.text = indicator_text
	timer.start()
	await timer.timeout
	input_judgment.text = "" 
	
	
