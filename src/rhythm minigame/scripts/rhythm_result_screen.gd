extends Control

@onready var main: Node2D = $"../.."

@onready var rhythm_result_screen: Control = $"."
@onready var back_to_restaurant: Button = $VBoxContainer/BackToRestaurant

@onready var dish_quality_score: Label = $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/DishQualityContainer/DishQualityScore
@onready var perfect_label: Label = $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/PerfectContainer/Label
@onready var good_label: Label = $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/GoodContainer/Label
@onready var miss_label: Label = $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/MissContainer/Label

func _ready() -> void:
	main.results_display.connect(display_results_screen)

func display_results_screen():
	visible = true
	rhythm_result_screen.modulate.a = 0.0
	
	var tween = create_tween()
	
	tween.tween_property(rhythm_result_screen, "modulate:a", 1.0, 1.5)

func _on_back_to_restaurant_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
