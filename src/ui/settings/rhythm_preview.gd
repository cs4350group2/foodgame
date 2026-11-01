extends Control

@onready var background: TextureRect = $Background
@onready var preview_note: Node2D = $PreviewNote
@onready var judgment_line: Sprite2D = $JudgmentLine

var current_note_speed: float = 5.0:
	set(value):
		current_note_speed = value
		start_preview_loop() # restart preview loop if note speed is changed

var background_brightness: float = 0.50:
	set(value):
		background_brightness = value
		if background:
			background.self_modulate.a = background_brightness

var tween : Tween

func _ready() -> void:
	background.self_modulate.a = background_brightness
	start_preview_loop()

func start_preview_loop() -> void:
	if tween and tween.is_valid():
		tween.kill()
	
	var time_to_reach_judgment_line_sec = 5.0 / current_note_speed
	
	var start_y: float = 0.0
	var target_y: float = judgment_line.position.y
	var overflow_y: float = 25.0 # distance past the judgment line that the preview note travels
	
	var time_after_judgment_line_sec: float = time_to_reach_judgment_line_sec * (overflow_y / target_y) # travel at same speed afterwards
	
	preview_note.position.y = start_y
	preview_note.visible = true
	
	tween = create_tween().set_loops()
	
	tween.tween_property(preview_note, "position:y", target_y, time_to_reach_judgment_line_sec).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(preview_note, "position:y", target_y + overflow_y, time_after_judgment_line_sec).set_trans(Tween.TRANS_LINEAR)
	
	tween.tween_interval(0.5)
	
	tween.tween_callback(func():
		preview_note.position.y = start_y
	)
	tween.tween_interval(0.2)
	
