extends Node

@onready var bgm_player: AudioStreamPlayer = $BackgroundMusicPlayer
@onready var rm_player: AudioStreamPlayer = $RhythmMusicStreamPlayer

signal audio_offset_changed(value: float)

@export_range(-150.0, 150.0, 1.0)
var audio_offset_ms: float = 0.0:
	set(value):
		var clamped_value := clampf(value, -150.0, 150.0)
		if is_equal_approx(audio_offset_ms, clamped_value):
			return
		audio_offset_ms = clamped_value
		audio_offset_changed.emit(audio_offset_ms)

# store the BPMs of what we're currently playing for matching purposes
var bgm_bpm: float = 0.0
var rm_bpm: float = 0.0
var song_first_beat: float = 0.0

func play_bgm(audio_data: AudioData, from_position: float = 0.0):
	play_bgm_to_target_bpm(audio_data, audio_data.bpm, from_position)

func play_bgm_to_target_bpm(audio_data: AudioData, 
			  target_bpm: float, from_position: float = 0.0):
	assert(audio_data.bpm > 0)
	assert(target_bpm > 0)
	var audio_stream := audio_data.audio_stream
	var original_bpm := audio_data.bpm
	bgm_player.stream = audio_stream
	bgm_player.pitch_scale = target_bpm / original_bpm
	bgm_bpm = target_bpm
	# for beat matching purposes
	song_first_beat = audio_data.first_beat
	bgm_player.play(from_position)
	
	print("Song playing!")

func play_rhythm_and_match_bgm(audio_data: AudioData,
							   from_position: float = 0.0):
	play_rhythm_to_target_bpm(audio_data, bgm_bpm, from_position)

func play_rhythm_to_target_bpm(audio_data: AudioData,
				 target_bpm: float, from_position: float = 0.0):
	assert(audio_data.bpm > 0)
	assert(target_bpm > 0)
	var audio_stream := audio_data.audio_stream
	var original_bpm := audio_data.bpm
	rm_player.stream = audio_stream
	rm_player.pitch_scale = target_bpm / original_bpm
	rm_bpm = target_bpm
	rm_player.play(from_position)

func get_rhythm_playback_position() -> float:
	return rm_player.get_playback_position()

func get_bgm_playback_position() -> float:
	return bgm_player.get_playback_position()

func fade_out_bgm(duration: float):
	var tween := create_tween()
	var original_volume := bgm_player.volume_linear
	tween.tween_property(bgm_player, "volume_linear", 0.0, duration)
	await tween.finished
	stop_bgm()
	bgm_player.volume_linear = original_volume

func stop_bgm():
	bgm_player.stop()

func stop_rhythm():
	rm_player.stop()

func set_bgm_volume(volume: float):
	var bus := AudioServer.get_bus_index("BGM")
	AudioServer.set_bus_volume_linear(bus, volume)

func set_rm_volume(volume: float):
	var bus := AudioServer.get_bus_index("Rhythm Music")
	AudioServer.set_bus_volume_linear(bus, volume)

func set_bgm_setting_volume(volume: float):
	var bus := AudioServer.get_bus_index("BGM Setting")
	AudioServer.set_bus_volume_linear(bus, volume)

func set_rm_setting_volume(volume: float):
	var bus := AudioServer.get_bus_index("Rhythm Setting")
	AudioServer.set_bus_volume_linear(bus, volume)

func set_sfx_setting_volume(volume: float):
	var bus := AudioServer.get_bus_index("SFX Setting")
	AudioServer.set_bus_volume_linear(bus, volume)

func get_bgm_setting_level() -> float:
	var bus := AudioServer.get_bus_index("BGM Setting")
	return AudioServer.get_bus_volume_linear(bus)

func get_rm_setting_level() -> float:
	var bus := AudioServer.get_bus_index("Rhythm Setting")
	return AudioServer.get_bus_volume_linear(bus)

func get_sfx_setting_level() -> float:
	var bus := AudioServer.get_bus_index("SFX Setting")
	return AudioServer.get_bus_volume_linear(bus)
