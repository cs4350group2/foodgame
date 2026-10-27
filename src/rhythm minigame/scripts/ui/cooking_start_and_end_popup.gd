extends MarginContainer

@onready var main: Node2D = $"../../.."

@onready var cooking_start_label: Label = $CookingStart
@onready var cooking_end_label: Label = $CookingEnd

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main.cooking_start.connect(animate_cooking_start_text)
	main.cooking_end.connect(animate_cooking_end_text)
	cooking_start_label.modulate.a = 0.0
	cooking_end_label.modulate.a = 0.0

func animate_cooking_start_text():
	cooking_start_label.modulate.a = 0.0
	
	var tween = create_tween()
	
	tween.tween_property(cooking_start_label, "modulate:a", 1.0, 0.5)
	
	# keep text on screen for another 0.75 seconds
	tween.tween_interval(0.5)
	
	tween.tween_property(cooking_start_label, "modulate:a", 0.0, 0.5)

func animate_cooking_end_text(combo_result: String):
	match combo_result:
		"AP":
			cooking_end_label.text = "ALL PERFECT!"
		"FC":
			cooking_end_label.text = "FULL COMBO!"
		"NORMAL":
			cooking_end_label.text = "COOKING END!"
	
	var tween = create_tween()
	
	tween.tween_property(cooking_end_label, "modulate:a", 1.0, 0.5)
	
	# keep text on screen for another 0.75 seconds
	tween.tween_interval(0.75)
	
	tween.tween_property(cooking_end_label, "modulate:a", 0.0, 0.5)
	
