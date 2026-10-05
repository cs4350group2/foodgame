extends Node2D

@onready var rhythm_main: Node2D = $".."

@onready var judgment_line: Sprite2D = $JudgmentLine
@onready var judgment_arrow_down: Node2D = $JudgmentArrowDown
@onready var judgment_arrow_up: Node2D = $JudgmentArrowUp
@onready var judgment_arrow_right: Node2D = $JudgmentArrowRight
@onready var judgment_arrow_left: Node2D = $JudgmentArrowLeft

func _ready() -> void:
	rhythm_main.cooking_start.connect(reset_visibility)
	rhythm_main.results_display.connect(fade_out_judgment_arrows_and_line)
	rhythm_main.hide_lane.connect(hide_specific_lane)
	
	get_viewport().size_changed.connect(stretch_hud)
	stretch_hud()

func hide_specific_lane(lane_name : String) -> void:
	var target_arrow: Node2D = null
	match lane_name.to_lower():
		"left": target_arrow = judgment_arrow_left
		"down": target_arrow = judgment_arrow_down
		"up": target_arrow = judgment_arrow_up
		"right": target_arrow = judgment_arrow_right
	
	if target_arrow:
		var tween = create_tween()
		tween.tween_property(target_arrow, "modulate:a", 0.0, 1.0)
	
func reset_visibility() -> void:
	# turn the asset transparencies back to fully visible 
	self.modulate.a = 1.0

func fade_out_judgment_arrows_and_line() -> void:
	var tween = create_tween()
	
	tween.tween_property(self, "modulate:a", 0.0, 1.0)

func stretch_hud() -> void:
	var viewport_size = get_viewport_rect().size
	
	position.x = viewport_size.x / 2.0
	
	# scale judgment line width
	if judgment_line:
		var texture_width = judgment_line.texture.get_width()
		judgment_line.scale.x = 2 * viewport_size.x / texture_width 

	
