extends Node3D

func _ready() -> void:
	$GPUParticles3D.finished.connect(queue_free)
	$GPUParticles3D.emitting = true
	play_sfx_with_fade()

func play_sfx_with_fade() -> void:
	var sfx: AudioStreamPlayer3D = $AudioStreamPlayer3D
	sfx.play()

	var tween := create_tween()
	tween.tween_property(sfx, "volume_db", -40.0, 1.0)
	tween.tween_callback(sfx.stop)
