extends CanvasLayer

var previous_mouse_mode: Input.MouseMode

@onready var bgm_slider: HSlider = %BGMSlider
@onready var rhythm_slider: HSlider = %RhythmSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var offset_slider: HSlider = %OffsetSlider

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game") and not event.is_echo():
		get_viewport().set_input_as_handled()
		if get_tree().paused:
			unpause_game()
		else:
			pause_game()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	bgm_slider.value_changed.connect(_on_bgm_changed)
	rhythm_slider.value_changed.connect(_on_rhythm_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	offset_slider.value_changed.connect(_on_offset_changed)
	%ResumeButton.pressed.connect(unpause_game)
	%MainMenuButton.pressed.connect(_on_main_menu_pressed)
	_sync_sliders()

func _on_main_menu_pressed() -> void:
	var scene_tree := get_tree()
	var error := scene_tree.change_scene_to_file("res://src/ui/MainMenu.tscn")
	if error != OK:
		push_error("Could not open main menu: %s" % error_string(error))
		return
	scene_tree.paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	RunManager.active_level = null

func _sync_sliders() -> void:
	bgm_slider.set_value_no_signal(AudioManager.get_bgm_setting_level() * 100.0)
	rhythm_slider.set_value_no_signal(AudioManager.get_rm_setting_level() * 100.0)
	sfx_slider.set_value_no_signal(AudioManager.get_sfx_setting_level() * 100.0)
	offset_slider.set_value_no_signal(AudioManager.audio_offset_ms)
	%BGMValue.text = "%d%%" % int(bgm_slider.value)
	%RhythmValue.text = "%d%%" % int(rhythm_slider.value)
	%SFXValue.text = "%d%%" % int(sfx_slider.value)
	%OffsetValue.text = "%+d ms" % int(AudioManager.audio_offset_ms)

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

#! IMPORTANT: Timers still run during pause, so 
# we may need to change the behaviour
func pause_game() -> void:
	if get_tree().paused:
		return
	_sync_sliders()
	previous_mouse_mode = Input.mouse_mode
	get_tree().paused = true
	Input.mouse_mode = Input.MouseMode.MOUSE_MODE_VISIBLE
	show()

func unpause_game() -> void:
	hide()
	Input.mouse_mode = previous_mouse_mode
	get_tree().paused = false
