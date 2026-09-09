extends Node3D

@export var audio_data: AudioData

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioManager.play_bgm(audio_data, 0.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	print(AudioManager.bgm_player.get_playback_position())
