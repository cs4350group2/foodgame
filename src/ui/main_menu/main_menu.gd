extends Node3D

@onready var new_game_button: Button = %NewGameButton
@onready var settings_button: Button = %SettingsButton
@onready var continue_button: Button = %ContinueButton
@onready var quit_button: Button = %QuitButton
@onready var seed_text: LineEdit = %LineEdit
@onready var menu_buttons: VBoxContainer = %NewGameButton.get_parent()
@onready var settings_page: CenterContainer = %SettingsPage
@onready var back_button: Button = %SettingsPage/Panel/Margin/Settings/BackButton
const MAIN_MENU_THEME = preload("res://src/music/cloud.tres")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	new_game_button.pressed.connect(_start_game)
	continue_button.pressed.connect(_continue_game)
	settings_button.pressed.connect(_open_settings)
	back_button.pressed.connect(_close_settings)
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

func _open_settings() -> void:
	menu_buttons.hide()
	settings_page.show()

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
