extends CanvasLayer

var previous_mouse_mode: Input.MouseMode

@onready var player: Player = get_parent().get_node_or_null("Player") as Player

@onready var settings_controls: VBoxContainer = $Center/Panel/Margin/Settings/AudioTab/VBoxContainer

@onready var audio_tab: FoldableContainer = $Center/Panel/Margin/Settings/AudioTab
@onready var rhythm_tab: FoldableContainer = $Center/Panel/Margin/Settings/RhythmTab

const RECIPE_MENU_SCENE = preload("res://src/ui/recipe_menu/RecipeMenu.tscn")

func _input(event: InputEvent) -> void:
	if RunManager.is_loading:
		return
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
	%ResumeButton.pressed.connect(unpause_game)
	%MainMenuButton.pressed.connect(_on_main_menu_pressed)
	%RecipeButton.pressed.connect(_on_recipe_pressed)
	settings_controls.sync_values()

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
	AudioManager.rm_player.stop()
	var scene_tree := get_tree()
	var error := scene_tree.change_scene_to_file("res://src/ui/main_menu/MainMenu.tscn")
	if error != OK:
		push_error("Could not open main menu: %s" % error_string(error))
		return
	scene_tree.paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	RunManager.active_level = null

func set_rhythm_settings_locked(is_locked: bool) -> void:
	if is_locked:
		rhythm_tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rhythm_tab.modulate = Color(0.5, 0.5, 0.5, 1)
	
	else:
		rhythm_tab.mouse_filter = Control.MOUSE_FILTER_STOP
		rhythm_tab.modulate = Color.WHITE
	
#! IMPORTANT: Timers still run during pause, so 
# we may need to change the behaviour
func pause_game() -> void:
	if get_tree().paused:
		return
	settings_controls.sync_values()
	previous_mouse_mode = Input.mouse_mode
	get_tree().paused = true
	if is_instance_valid(player):
		player.release_mouse()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	show()

func unpause_game() -> void:
	hide()
	audio_tab.fold()
	rhythm_tab.fold()
	if is_instance_valid(player):
		if previous_mouse_mode == Input.MOUSE_MODE_CAPTURED:
			player.capture_mouse()
		else:
			player.release_mouse()
			Input.mouse_mode = previous_mouse_mode
	else:
		Input.mouse_mode = previous_mouse_mode
	get_tree().paused = false
