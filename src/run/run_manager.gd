extends Node

var current_run: RestaurantRun = null
var level_scene: PackedScene = preload("res://main.tscn")
var active_level: Level = null

signal upgrade_selection_requested()

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
	upgrade_selection_requested.emit()

func complete_upgrade_selection(upgrade: Upgrade) -> void:
	add_upgrade(upgrade)
	active_level.generate_customers(current_run.arrival_config)

func get_rng() -> RandomNumberGenerator:
	assert(current_run != null)
	return current_run.rng
