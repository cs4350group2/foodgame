extends Control

@onready var rhythm_main: Node2D = $"../../.."

@onready var rhythm_result_screen_v2: Control = $"."
@onready var return_to_restaurant_button: Button = $MainMargin/MainVBox/MainHBox/DishQualityAndButtonSection/ReturnToRestaurantButton

@onready var perfect_count_label: Label = $MainMargin/MainVBox/MainHBox/StatsSection/PerfectRow/PerfectCountLabel
@onready var good_count_label: Label = $MainMargin/MainVBox/MainHBox/StatsSection/GoodRow/GoodCountLabel
@onready var miss_count_label: Label = $MainMargin/MainVBox/MainHBox/StatsSection/MissRow/MissCountLabel

@onready var dish_quality_score_label: Label = $MainMargin/MainVBox/MainHBox/DishQualityAndButtonSection/DishQualityScoreLabel

func _ready() -> void:
	rhythm_main.results_display.connect(display_results_screen)

func display_results_screen():
	visible = true
	rhythm_result_screen_v2.modulate.a = 0.0
	
	var tween = create_tween()
	
	tween.tween_property(rhythm_result_screen_v2, "modulate:a", 1.0, 1.5)

func _on_return_to_restaurant_button_pressed() -> void:
	rhythm_main.return_to_restaurant.emit(rhythm_main.dish_quality)
