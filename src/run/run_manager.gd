extends Node

const DISH_UNLOCK_INTERVAL := 2

var current_run: RestaurantRun = null
const LEVEL_PATH := "res://main.tscn"
const LOADING_SCREEN = preload("res://src/ui/loading_screen/LoadingScreen.tscn")
var is_loading: bool = false
var active_level: Level = null
var pending_customer_unlock: Unlock_Upgrade = null
var pending_dish_choices: Array[Upgrade]

signal upgrade_selection_requested(upgrades: Array[Upgrade])
signal day_updated(day_number: int)

func _ready() -> void:
	UpgradeRepo.load_catalog()

func retire_run() -> void:
	pending_customer_unlock = null
	current_run = null
	active_level = null

func start_new_run(seed_entered: bool, start_seed: int) -> void:
	pending_customer_unlock = null
	AudioManager.bgm_bpm = AudioManager.MUD_DAGORED.bpm
	current_run = RestaurantRun.new(seed_entered, start_seed)

func enter_level() -> void:
	if is_loading or current_run == null:
		return
	is_loading = true
	var loading_screen := LOADING_SCREEN.instantiate() as CanvasLayer
	get_tree().root.add_child(loading_screen)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var status_label := loading_screen.get_node("%Status") as Label
	var progress_bar := loading_screen.get_node("%Progress") as ProgressBar
	# Draw the screen before starting any expensive resource or scene work.
	await get_tree().process_frame
	await get_tree().process_frame
	var error := ResourceLoader.load_threaded_request(LEVEL_PATH)
	if error != OK:
		_show_loading_error(loading_screen, "Could not load restaurant: %s" % error_string(error))
		return
	var progress: Array = []
	while true:
		var status := ResourceLoader.load_threaded_get_status(LEVEL_PATH, progress)
		if not progress.is_empty():
			progress_bar.value = float(progress[0]) * 100.0
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			break
		if status != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_show_loading_error(loading_screen, "Could not load restaurant.")
			return
		await get_tree().process_frame
	var level_scene := ResourceLoader.load_threaded_get(LEVEL_PATH) as PackedScene
	if level_scene == null:
		_show_loading_error(loading_screen, "Restaurant scene is unavailable.")
		return
	progress_bar.value = 100.0
	await get_tree().process_frame
	await get_tree().process_frame
	var next_level := level_scene.instantiate() as Level
	if next_level == null:
		_show_loading_error(loading_screen, "Could not create restaurant.")
		return
	error = get_tree().change_scene_to_node(next_level)
	if error != OK:
		next_level.queue_free()
		_show_loading_error(loading_screen, "Could not enter restaurant: %s" % error_string(error))
		return
	active_level = next_level
	await get_tree().scene_changed
	current_run.apply_upgrades(active_level)
	active_level.generate_customers(current_run.arrival_config)
	# Keep the overlay through scene initialization and the first rendered frame.
	await get_tree().process_frame
	await get_tree().process_frame
	loading_screen.hide()
	loading_screen.queue_free()
	is_loading = false
	AudioManager.play_bgm(active_level.day_manager.CHILL_BGM)

func _show_loading_error(loading_screen: CanvasLayer, message: String) -> void:
	push_error(message)
	loading_screen.get_node("%Status").text = message
	loading_screen.get_node("%Progress").hide()
	var back_button := loading_screen.get_node("%BackButton") as Button
	back_button.show()
	back_button.pressed.connect(func() -> void:
		loading_screen.queue_free()
		is_loading = false
	, CONNECT_ONE_SHOT)

func add_upgrade(new_upgrade: Upgrade) -> void:
	current_run.add_upgrade(new_upgrade)
	new_upgrade.apply_effect(active_level)

func level_complete() -> void:
	var completed_day := current_run.current_day
	
	pending_customer_unlock = current_run.progress_day()
	if pending_customer_unlock != null:
		pending_customer_unlock.apply_effect(active_level)
	day_updated.emit(current_run.current_day)
	
	pending_dish_choices.clear()
	if completed_day % DISH_UNLOCK_INTERVAL == 0:
		pending_dish_choices = current_run.get_dish_unlock_choices()
	
	if not pending_dish_choices.is_empty():
		upgrade_selection_requested.emit(pending_dish_choices)
	else:
		_prepare_next_day()
	
func complete_upgrade_selection(upgrade: Upgrade) -> void:
	add_upgrade(upgrade.duplicate())
	_prepare_next_day()

func _prepare_next_day() -> void:
	active_level.generate_customers(current_run.arrival_config)
	# Wait until the normal choice is resolved so its UI does not hide the reward.
	if pending_customer_unlock != null:
		active_level.restaurant_ui.show_notification_top(
			String(pending_customer_unlock.display_name), true, pending_customer_unlock.description)
		pending_customer_unlock = null

func get_rng() -> RandomNumberGenerator:
	assert(current_run != null)
	return current_run.rng

# helper functions to quickly release and capture mouse, helpful for
# engaging and disengaging the cursor. also disables the ability to capture
# mouse with left click until capture_player_mouse is called.
func release_player_mouse() -> void:
	active_level.player.set_process_unhandled_input(false)
	active_level.player.release_mouse()

func capture_player_mouse() -> void:
	active_level.player.set_process_unhandled_input(true)
	active_level.player.capture_mouse()
