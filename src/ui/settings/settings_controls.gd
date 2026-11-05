extends VBoxContainer
## Shared settings behavior; each menu provides its own layout and styling.

@onready var master_slider: HSlider = %MasterSlider
@onready var bgm_slider: HSlider = %BGMSlider
@onready var rhythm_slider: HSlider = %RhythmSlider
@onready var sfx_slider: HSlider = %SFXSlider

@onready var note_speed_slider: HSlider = %NoteSpeedSlider
@onready var offset_slider: HSlider = %OffsetSlider
@onready var background_brightness_slider: HSlider = %BackgroundBrightnessSlider
@onready var note_vfx_check_button: CheckButton = %NoteVFXCheckButton
@onready var note_sfx_check_button: CheckButton = %NoteSFXCheckButton

@onready var rhythm_preview: Control = %RhythmPreview

func _ready() -> void:
	master_slider.value_changed.connect(_on_master_changed)
	bgm_slider.value_changed.connect(_on_bgm_changed)
	rhythm_slider.value_changed.connect(_on_rhythm_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	
	note_speed_slider.value_changed.connect(_on_note_speed_changed)
	offset_slider.value_changed.connect(_on_offset_changed)
	background_brightness_slider.value_changed.connect(_on_background_brightness_changed)
	note_vfx_check_button.toggled.connect(_on_note_vfx_check_button_toggled)
	note_sfx_check_button.toggled.connect(_on_note_sfx_check_button_toggled)
	
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
	offset_slider.set_value_no_signal(RhythmManager.audio_offset_ms)
	%MasterValue.text = "%d%%" % int(master_slider.value)
	%BGMValue.text = "%d%%" % int(bgm_slider.value)
	%RhythmValue.text = "%d%%" % int(rhythm_slider.value)
	%SFXValue.text = "%d%%" % int(sfx_slider.value)
	
	%NoteSpeedValue.text = "%.1f" % float(note_speed_slider.value)
	%OffsetValue.text = "%+d ms" % int(offset_slider.value)
	%BackgroundBrightnessValue.text = "%d%%" % int(background_brightness_slider.value)
	
	note_vfx_check_button.set_pressed_no_signal(RhythmManager.note_vfx_enabled)
	note_sfx_check_button.set_pressed_no_signal(RhythmManager.note_sfx_enabled)

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

func _on_note_speed_changed(value: float) -> void:
	RhythmManager.set_note_speed(value)
	rhythm_preview.current_note_speed = value
	%NoteSpeedValue.text = "%.1f" % float(note_speed_slider.value)

func _on_offset_changed(value: float) -> void:
	RhythmManager.audio_offset_ms = value
	%OffsetValue.text = "%+d ms" % int(RhythmManager.audio_offset_ms)

func _on_background_brightness_changed(value: float) -> void:
	var normalized_brightness : float = value / 100.0
	RhythmManager.set_background_brightness(normalized_brightness)
	rhythm_preview.background_brightness = normalized_brightness
	%BackgroundBrightnessValue.text = "%d%%" % int(background_brightness_slider.value)

func _on_note_vfx_check_button_toggled(toggled_on: bool) -> void:
	RhythmManager.note_vfx_enabled = toggled_on
	
func _on_note_sfx_check_button_toggled(toggled_on: bool) -> void:
	RhythmManager.note_sfx_enabled = toggled_on
	
func _on_reset_to_defaults_button_pressed() -> void:
	RhythmManager.set_note_speed(5.0)
	note_speed_slider.value = 5.0
	%NoteSpeedValue.text = "%.1f" % float(note_speed_slider.value)
	
	RhythmManager.audio_offset_ms = 0.0
	offset_slider.value = 0.0
	%OffsetValue.text = "%+d ms" % int(RhythmManager.audio_offset_ms)
	
	RhythmManager.set_background_brightness(0.5)
	background_brightness_slider.value = 50
	%BackgroundBrightnessValue.text = "%d%%" % int(background_brightness_slider.value)

	RhythmManager.note_vfx_enabled = true
	RhythmManager.note_sfx_enabled = true
