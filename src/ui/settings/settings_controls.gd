extends VBoxContainer
## Shared settings behavior; each menu provides its own layout and styling.

@onready var master_slider: HSlider = %MasterSlider
@onready var bgm_slider: HSlider = %BGMSlider
@onready var rhythm_slider: HSlider = %RhythmSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var offset_slider: HSlider = %OffsetSlider

func _ready() -> void:
	master_slider.value_changed.connect(_on_master_changed)
	bgm_slider.value_changed.connect(_on_bgm_changed)
	rhythm_slider.value_changed.connect(_on_rhythm_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	offset_slider.value_changed.connect(_on_offset_changed)
	visibility_changed.connect(_on_visibility_changed)
	sync_values()

func _on_visibility_changed() -> void:
	if is_node_ready() and is_visible_in_tree():
		sync_values()

func sync_values() -> void:
	master_slider.set_value_no_signal(AudioManager.get_master_setting_level() * 100.0)
	bgm_slider.set_value_no_signal(AudioManager.get_bgm_setting_level() * 100.0)
	rhythm_slider.set_value_no_signal(AudioManager.get_rm_setting_level() * 100.0)
	sfx_slider.set_value_no_signal(AudioManager.get_sfx_setting_level() * 100.0)
	offset_slider.set_value_no_signal(AudioManager.audio_offset_ms)
	%MasterValue.text = "%d%%" % int(master_slider.value)
	%BGMValue.text = "%d%%" % int(bgm_slider.value)
	%RhythmValue.text = "%d%%" % int(rhythm_slider.value)
	%SFXValue.text = "%d%%" % int(sfx_slider.value)
	%OffsetValue.text = "%+d ms" % int(offset_slider.value)

func _on_master_changed(value: float) -> void:
	AudioManager.set_master_setting_volume(value / 100.0)
	%MasterValue.text = "%d%%" % int(value)

func _on_bgm_changed(value: float) -> void:
	AudioManager.set_bgm_setting_volume(value / 100.0)
	%BGMValue.text = "%d%%" % int(value)

func _on_rhythm_changed(value: float) -> void:
	AudioManager.set_rm_setting_volume(value / 100.0)
	%RhythmValue.text = "%d%%" % int(value)

func _on_sfx_changed(value: float) -> void:
	AudioManager.set_sfx_setting_volume(value / 100.0)
	%SFXValue.text = "%d%%" % int(value)

func _on_offset_changed(value: float) -> void:
	AudioManager.audio_offset_ms = value
	%OffsetValue.text = "%+d ms" % int(AudioManager.audio_offset_ms)
