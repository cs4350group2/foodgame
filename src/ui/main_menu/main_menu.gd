extends Node3D

@onready var new_game_button: Button = %NewGameButton
@onready var settings_button: Button = %SettingsButton
@onready var continue_button: Button = %ContinueButton
@onready var seed_text: LineEdit = %LineEdit
const MAIN_MENU_THEME = preload("res://src/music/cloud.tres")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	new_game_button.pressed.connect(_start_game)
	continue_button.pressed.connect(_continue_game)
	if RunManager.current_run == null:
		continue_button.visible = false
	# Play main menu theme here
	AudioManager.play_bgm(MAIN_MENU_THEME)

func _start_game() -> void:
	RunManager.start_new_run(seed_text.text == "", hash(seed_text.text))
	RunManager.enter_level()

func _continue_game() -> void:
	RunManager.enter_level()
