extends Node3D

@onready var new_game_button: Button = %NewGameButton
@onready var settings_button: Button = %SettingsButton
@onready var continue_button: Button = %ContinueButton
@onready var quit_button: Button = %QuitButton
@onready var seed_text: LineEdit = %LineEdit
@onready var menu_buttons: VBoxContainer = %NewGameButton.get_parent()
@onready var settings_page: CenterContainer = %SettingsPage

# settings buttons
@onready var audio_button: Button = $CanvasLayer/Control/SettingsPage/Panel/Margin/ViewManager/CategorySelection/ButtonVBox/AudioButton
@onready var rhythm_button: Button = $CanvasLayer/Control/SettingsPage/Panel/Margin/ViewManager/CategorySelection/ButtonVBox/RhythmButton

# settings tabs
@onready var category_selection: VBoxContainer = $CanvasLayer/Control/SettingsPage/Panel/Margin/ViewManager/CategorySelection
@onready var audio_settings: VBoxContainer = $CanvasLayer/Control/SettingsPage/Panel/Margin/ViewManager/AudioSettings
@onready var rhythm_settings: VBoxContainer = $CanvasLayer/Control/SettingsPage/Panel/Margin/ViewManager/RhythmSettings

# back buttons
@onready var category_back_button: Button = $CanvasLayer/Control/SettingsPage/Panel/Margin/ViewManager/CategorySelection/ButtonVBox/CategoryBackButton
@onready var audio_back_button: Button = $CanvasLayer/Control/SettingsPage/Panel/Margin/ViewManager/AudioSettings/AudioBackButton
@onready var rhythm_back_button: Button = $CanvasLayer/Control/SettingsPage/Panel/Margin/ViewManager/RhythmSettings/RhythmBackButton

@onready var reset_to_defaults_button: Button = $CanvasLayer/Control/SettingsPage/Panel/Margin/ViewManager/RhythmSettings/ResetToDefaultsButton

const MAIN_MENU_THEME = preload("res://src/music/cloud.tres")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	new_game_button.pressed.connect(_start_game)
	continue_button.pressed.connect(_continue_game)
	settings_button.pressed.connect(_open_settings_selection)
	audio_button.pressed.connect(_open_audio_settings)
	rhythm_button.pressed.connect(_open_rhythm_settings)
	category_back_button.pressed.connect(_close_settings)
	audio_back_button.pressed.connect(_go_to_settings_selection)
	rhythm_back_button.pressed.connect(_go_to_settings_selection)
	quit_button.pressed.connect(_on_quit)
	if RunManager.current_run == null:
		continue_button.visible = false
	# Play main menu theme here
	AudioManager.play_bgm(MAIN_MENU_THEME)

func _on_quit() -> void:
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if settings_page.visible and event.is_action_pressed("pause_game") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_close_settings()

func _open_settings_selection() -> void:
	menu_buttons.hide()
	settings_page.show()
	category_selection.visible = true
	audio_settings.visible = false
	rhythm_settings.visible = false

func _open_audio_settings() -> void:
	category_selection.visible = false
	audio_settings.visible = true
	rhythm_settings.visible = false

func _open_rhythm_settings() -> void:
	category_selection.visible = false
	audio_settings.visible = false
	rhythm_settings.visible = true

func _go_to_settings_selection() -> void:
	category_selection.visible = true
	audio_settings.visible = false
	rhythm_settings.visible = false
	
func _close_settings() -> void:
	settings_page.hide()
	menu_buttons.show()

func _start_game() -> void:
	if RunManager.is_loading:
		return
	RunManager.start_new_run(seed_text.text != "", hash(seed_text.text))
	RunManager.enter_level()

func _continue_game() -> void:
	RunManager.enter_level()
