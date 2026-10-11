extends Node2D

@onready var rhythm_main: Node2D = $".."

@onready var judgment_line: Sprite2D = $JudgmentLine
@onready var judgment_note_left: Node2D = $JudgmentNoteLeft
@onready var judgment_note_down: Node2D = $JudgmentNoteDown
@onready var judgment_note_up: Node2D = $JudgmentNoteUp
@onready var judgment_note_right: Node2D = $JudgmentNoteRight

func _ready() -> void:
	rhythm_main.cooking_start.connect(reset_visibility)
	rhythm_main.results_display.connect(fade_out_judgment_arrows_and_line)
	rhythm_main.hide_lane.connect(hide_specific_lane)
	
	get_viewport().size_changed.connect(stretch_hud)
	stretch_hud()

func hide_specific_lane(lane_name : String) -> void:
	var target_note: Node2D = null
	match lane_name.to_lower():
		"left": target_note = judgment_note_left
		"down": target_note = judgment_note_down
		"up": target_note = judgment_note_up
		"right": target_note = judgment_note_right
	
	if target_note:
		var tween = create_tween()
		tween.tween_property(target_note, "modulate:a", 0.0, 1.0)
	
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

	
