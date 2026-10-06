extends Node3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var title: Label = $CanvasLayer/Control/Label
	var restart_label: Label = $CanvasLayer/RestartLabel
	title.modulate.a = 0.0
	restart_label.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(title, "modulate:a", 1.0, 0.6)
	tween.tween_property(restart_label, "modulate:a", 1.0, 0.6)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file("res://main.tscn")
		AudioManager.bgm_player.pitch_scale = 1.0
