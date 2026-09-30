extends Node3D

const DEATH_TRACK = preload("res://src/music/mud_dagored.tres")

func _input(event):
	if event.is_pressed():
		get_tree().change_scene_to_file("res://main.tscn")
		AudioManager.bgm_player.pitch_scale = 1.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var title: Label = $CanvasLayer/Control/Label
	var retry_label: Label = $CanvasLayer/Label2
	title.modulate.a = 0.0
	retry_label.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(title, "modulate:a", 1.0, 0.6)
	tween.tween_property(retry_label, "modulate:a", 1.0, 0.6)
	AudioManager.play_bgm(DEATH_TRACK, 0.0)
	AudioManager.bgm_player.pitch_scale = 0.5
