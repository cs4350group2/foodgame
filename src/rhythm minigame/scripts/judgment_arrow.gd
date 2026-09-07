extends Node2D

@onready var main: Node2D = $"../.."

@onready var judgment_hud: Node2D = $".." # parent node of all judgment arrows and line

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	main.cooking_start.connect(reset_visibility)
	main.results_display.connect(fade_out_judgment_arrows_and_line)
	
func reset_visibility() -> void:
	# turn the asset transparencies back to fully visible 
	judgment_hud.modulate.a = 1.0

func fade_out_judgment_arrows_and_line() -> void:
	var tween = create_tween()
	
	tween.tween_property(judgment_hud, "modulate:a", 0.0, 1.0)
