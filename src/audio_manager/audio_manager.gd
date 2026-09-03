extends Node

@onready var bgm_player: AudioStreamPlayer = $BackgroundMusicPlayer
@onready var rm_player: AudioStreamPlayer = $RhythmMusicStreamPlayer

# store the BPMs of what we're currently playing for matching purposes
var bgm_bpm: float = 0.0
var rm_bpm: float = 0.0

# we might also need the first beat time to sync, or just assume it starts from 0.0

func play_bgm(audio_stream: AudioStream, original_bpm: float, 
			  target_bpm: float, from_position: float = 0.0):
	assert(original_bpm > 0)
	assert(target_bpm > 0)
	
	bgm_player.stream = audio_stream
	bgm_player.pitch_scale = target_bpm / original_bpm
	bgm_bpm = target_bpm
	bgm_player.play(from_position)

func play_rhythm_and_match_bgm(audio_stream: AudioStream, original_bpm: float,
							   from_position: float = 0.0):
	play_rhythm(audio_stream, original_bpm, bgm_bpm, from_position)

func play_rhythm(audio_stream: AudioStream, original_bpm: float,
				 target_bpm: float, from_position: float = 0.0):
	assert(original_bpm > 0)
	assert(target_bpm > 0)
	
	rm_player.stream = audio_stream
	rm_player.pitch_scale = target_bpm / original_bpm
	rm_bpm = target_bpm
	rm_player.play(from_position)

func get_rhythm_playback_position() -> float:
	return rm_player.get_playback_position()

func get_bgm_playback_position() -> float:
	return bgm_player.get_playback_position()

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
