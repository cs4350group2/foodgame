extends VBoxContainer

@onready var rhythm_main: Node2D = $"../../../.."
@onready var dish_quality_label: Label = $DishQuality
@onready var dish_quality_value_label: Label = $DishQualityValue

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rhythm_main.cooking_start.connect(update_dish_quality)
	rhythm_main.hit.connect(update_dish_quality)
	rhythm_main.miss.connect(update_dish_quality)
	rhythm_main.empty_press.connect(update_dish_quality)
	rhythm_main.cooking_start.connect(reset_visibility)
	rhythm_main.cooking_end.connect(update_dish_quality)
	rhythm_main.results_display.connect(fade_out_live_dish_quality)
	dish_quality_label.text = "DISH QUALITY:\n (W/O EMPTY)"
	self.modulate.a = 0 # turn invisible until the COOKING START label
	

func update_dish_quality(input_judgment = ""):
	var num_perfects = rhythm_main.num_perfects
	var num_goods = rhythm_main.num_goods
	var num_misses = rhythm_main.num_misses
	var current_dish_quality = rhythm_main.get_current_dish_quality_snapped_without_empty()
	
	if current_dish_quality <= 20.0:
		dish_quality_value_label.add_theme_color_override("font_color", Color(0.60, 0, 0))
	else:
		dish_quality_value_label.add_theme_color_override("font_color", Color.BLACK)
	
	print("Counts (live display) -> P: ", num_perfects, " G: ", num_goods, " M: ", num_misses)
	dish_quality_value_label.text = str(current_dish_quality) + "%"

func reset_visibility() -> void:
	# turn the asset transparencies back to fully visible
	self.modulate.a = 1.0

func fade_out_live_dish_quality() -> void:
	var tween = create_tween()
	
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
