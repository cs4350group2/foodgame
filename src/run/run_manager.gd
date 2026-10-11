extends Node

var current_run: RestaurantRun = null
var level_scene: PackedScene = preload("res://main.tscn")
var active_level: Level = null

signal upgrade_selection_requested(upgrades: Array[Upgrade])
signal day_updated(day_number: int)

func _ready() -> void:
	UpgradeRepo.load_catalog()

func retire_run() -> void:
	current_run = null

func start_new_run(seed_entered: bool, start_seed: int) -> void:
	current_run = RestaurantRun.new(seed_entered, start_seed)

func enter_level() -> void:
	active_level = level_scene.instantiate()
	get_tree().change_scene_to_node(active_level)
	await get_tree().scene_changed
	current_run.apply_upgrades(active_level)
	active_level.generate_customers(current_run.arrival_config)

func add_upgrade(new_upgrade: Upgrade) -> void:
	current_run.add_upgrade(new_upgrade)
	new_upgrade.apply_effect(active_level)

func level_complete() -> void:
	current_run.progress_day()
	day_updated.emit(current_run.current_day)
	
	# idk how decide if you should pick an upgrade
	var upgrades := current_run.get_random_available_upgrades(3)
	# generate some upgrades here
	if len(upgrades) != 0:
		upgrade_selection_requested.emit(upgrades)
	else:
		active_level.generate_customers(current_run.arrival_config)
	
func complete_upgrade_selection(upgrade: Upgrade) -> void:
	add_upgrade(upgrade.duplicate())
	active_level.generate_customers(current_run.arrival_config)

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
