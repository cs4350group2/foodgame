extends Node

@export_range(1.0, 10.0, 0.1) var note_speed: float = 5.0 # 5.0 is the default note speed
@export_range(0.0, 1.0, 0.05) var background_brightness : float = 0.5 # 0.5 is default background brightness

signal note_speed_changed(value: float)
signal audio_offset_changed(value: float)
signal background_brightness_changed(value: float)

@export_range(-150.0, 150.0, 1.0)
var audio_offset_ms: float = 0.0:
	set(value):
		var clamped_value := clampf(value, -150.0, 150.0)
		if is_equal_approx(audio_offset_ms, clamped_value):
			return
		audio_offset_ms = clamped_value
		audio_offset_changed.emit(audio_offset_ms)
		
func set_note_speed(speed: float):
	note_speed = speed
	note_speed_changed.emit(speed)

func set_background_brightness(brightness: float):
	background_brightness = brightness
	background_brightness_changed.emit(brightness)
