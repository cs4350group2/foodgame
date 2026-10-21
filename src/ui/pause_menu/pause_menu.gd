extends CanvasLayer

var previous_mouse_mode: Input.MouseMode

@onready var player: Player = get_parent().get_node_or_null("Player") as Player

@onready var master_slider: HSlider = %MasterSlider
@onready var bgm_slider: HSlider = %BGMSlider
@onready var rhythm_slider: HSlider = %RhythmSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var offset_slider: HSlider = %OffsetSlider

const RECIPE_MENU_SCENE = preload("res://src/ui/recipe_menu/RecipeMenu.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game") and not event.is_echo():
		get_viewport().set_input_as_handled()
		var drink_menu := get_parent().get_node_or_null("RestaurantUi/DrinkMenu") as Control
		if is_instance_valid(drink_menu) and drink_menu.visible:
			drink_menu.close_menu()
			return
		if recipe_menu and recipe_menu.visible:
			_on_recipe_closed()
		elif get_tree().paused:
			unpause_game()
		else:
			pause_game()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	master_slider.value_changed.connect(_on_master_changed)
	bgm_slider.value_changed.connect(_on_bgm_changed)
	rhythm_slider.value_changed.connect(_on_rhythm_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	offset_slider.value_changed.connect(_on_offset_changed)
	%ResumeButton.pressed.connect(unpause_game)
	%MainMenuButton.pressed.connect(_on_main_menu_pressed)
	%RecipeButton.pressed.connect(_on_recipe_pressed)
	_sync_sliders()

var recipe_menu: Control = null

func _on_recipe_pressed():
	if not recipe_menu:
		recipe_menu = RECIPE_MENU_SCENE.instantiate()
		add_child(recipe_menu)
		recipe_menu.button.pressed.connect(_on_recipe_closed)
	$Center.hide()
	recipe_menu.show()

func _on_recipe_closed() -> void:
	recipe_menu.hide()
	$Center.show()

func _on_main_menu_pressed() -> void:
	var scene_tree := get_tree()
	var error := scene_tree.change_scene_to_file("res://src/ui/main_menu/MainMenu.tscn")
	if error != OK:
		push_error("Could not open main menu: %s" % error_string(error))
		return
	scene_tree.paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	RunManager.active_level = null

func _sync_sliders() -> void:
	master_slider.set_value_no_signal(AudioManager.get_master_setting_level() * 100.0)
	bgm_slider.set_value_no_signal(AudioManager.get_bgm_setting_level() * 100.0)
	rhythm_slider.set_value_no_signal(AudioManager.get_rm_setting_level() * 100.0)
	sfx_slider.set_value_no_signal(AudioManager.get_sfx_setting_level() * 100.0)
	offset_slider.set_value_no_signal(AudioManager.audio_offset_ms)
	%MasterValue.text = "%d%%" % int(master_slider.value)
	%BGMValue.text = "%d%%" % int(bgm_slider.value)
	%RhythmValue.text = "%d%%" % int(rhythm_slider.value)
	%SFXValue.text = "%d%%" % int(sfx_slider.value)
	%OffsetValue.text = "%+d ms" % int(AudioManager.audio_offset_ms)

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

#! IMPORTANT: Timers still run during pause, so 
# we may need to change the behaviour
func pause_game() -> void:
	if get_tree().paused:
		return
	_sync_sliders()
	previous_mouse_mode = Input.mouse_mode
	get_tree().paused = true
	if is_instance_valid(player):
		player.release_mouse()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	show()

func unpause_game() -> void:
	hide()
	if is_instance_valid(player):
		if previous_mouse_mode == Input.MOUSE_MODE_CAPTURED:
			player.capture_mouse()
		else:
			player.release_mouse()
			Input.mouse_mode = previous_mouse_mode
	else:
		Input.mouse_mode = previous_mouse_mode
	get_tree().paused = false
