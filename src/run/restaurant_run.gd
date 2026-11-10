extends Resource
class_name RestaurantRun

const CUSTOMER_UNLOCK_INTERVAL := 3
# Milestone rewards deliberately stay out of UpgradeRepo's selectable catalog.
const CUSTOMER_UNLOCK_UPGRADES: Array[Unlock_Upgrade] = [
	preload("res://src/upgrades/unlock_upgrade/vip_unlock.tres"),
	preload("res://src/upgrades/unlock_upgrade/hobo_unlock.tres"),
	preload("res://src/upgrades/unlock_upgrade/impatient_unlock.tres"),
	preload("res://src/upgrades/unlock_upgrade/food_critic_unlock.tres"),
]

const DISH_UNLOCK_UPGRADES: Array[Unlock_Upgrade] = [
	preload("res://src/upgrades/dish_unlock/steak_unlock.tres"),
	preload("res://src/upgrades/dish_unlock/sushi_unlock.tres"),
	preload("res://src/upgrades/dish_unlock/burger_unlock.tres"),
	preload("res://src/upgrades/dish_unlock/stew_unlock.tres"),
	preload("res://src/upgrades/dish_unlock/rice_bowl_unlock.tres"),
	preload("res://src/upgrades/dish_unlock/grilled_fish_unlock.tres"),
]

@export var day_speed_multiplier: float = 1.01
@export var starting_gradual_customers: int = 1
@export var gradual_increase_per_day: int = 1
@export_range(0, 1000, 1) var starting_danger: int = 0
@export_range(0, 1000, 1) var danger_increase_per_day: int = 2
## We remove a bit of patience every day, up to a minimum
@export_range(0.0, 1.0, 0.01) var patience_decrease_per_day: float = 0.02
@export_range(0.01, 1.0, 0.01) var minimum_patience_multiplier: float = 0.6
@export_range(2, 100, 1) var min_wave_size: int = 2
@export_range(2, 100, 1) var max_wave_size: int = 4
@export_range(1, 4, 1) var max_waves: int = 4
var starting_total_time: float = 45.0
var starting_first_arrival_delay: float = 5.0

var total_time_change: float = 20.0

var current_upgrades: Array[Upgrade]
var upgrade_repo: UpgradeRepo
var current_day: int = 0
var coins: float = 0
var current_speed: float = 1.0

var rng_seed: int = 0
var rng : RandomNumberGenerator
var customer_unlock_rng := RandomNumberGenerator.new()
var remaining_customer_unlocks: Array[Unlock_Upgrade] = []

var arrival_config: ArrivalConfig = ArrivalConfig.new()

# starter dishes if don't like can change
var starter_dishes := [&"Steak", &"Grilled Fish"]
var unlocked_dishes: Array[StringName] = []
var unlocked_drinks: Array[StringName] = []

signal coins_updated(amount)

func add_coins(amount: float) -> void:
	coins += amount
	coins_updated.emit(coins)

func try_remove_coins(amount: float) -> bool:
	if amount > coins:
		return false
	
	coins -= amount
	coins_updated.emit(coins)
	assert(coins >= 0)
	return true

func _init(set_seed: bool, run_seed: int = 0) -> void:
	upgrade_repo = UpgradeRepo.new()
	current_upgrades = []
	current_day = 1
	coins = 0
	
	unlocked_dishes.clear()
	for dish: StringName in starter_dishes:
		unlock_dish(dish)
	
	arrival_config = ArrivalConfig.new()
	_update_arrival_config()
	arrival_config.total_time = starting_total_time
	arrival_config.first_arrival_delay = starting_first_arrival_delay
	rng_seed = run_seed
	rng = RandomNumberGenerator.new()
	if set_seed:
		rng.seed = run_seed
	else:
		rng_seed = rng.seed
	# A separate stream keeps unlock order independent of spawning and choices.
	customer_unlock_rng.seed = hash("%d:customer_unlocks" % rng_seed)
	remaining_customer_unlocks.assign(CUSTOMER_UNLOCK_UPGRADES)
	print("New run started with seed ", rng.seed)

func apply_upgrades(level: Level) -> void:
	for upgrade: Upgrade in current_upgrades:
		upgrade.apply_effect(level)

func add_upgrade(new_upgrade: Upgrade) -> void:
	if UpgradeRepo.upgrade_catalog.has(new_upgrade.name):
		upgrade_repo.on_upgrade_chosen(new_upgrade)

	current_upgrades.append(new_upgrade)

func get_random_available_upgrades(n: int) -> Array[Upgrade]:
	return upgrade_repo.get_random_upgrades(n, rng)


func progress_day() -> Unlock_Upgrade:
	current_day += 1
	_update_arrival_config()
	arrival_config.total_time += total_time_change
	# Advancing into day 3 grants the first reward, before its schedule is built
	if current_day % CUSTOMER_UNLOCK_INTERVAL != 0 or remaining_customer_unlocks.is_empty():
		return null
	var index := customer_unlock_rng.randi_range(0, remaining_customer_unlocks.size() - 1)
	var upgrade := remaining_customer_unlocks[index].duplicate() as Unlock_Upgrade
	remaining_customer_unlocks.remove_at(index)
	# Automatic rewards are owned upgrades, but are never selected from UpgradeRepo
	current_upgrades.append(upgrade)
	return upgrade

func _calculate_gradual_customer_count(day: int) -> int:
	return starting_gradual_customers + (day - 1) * gradual_increase_per_day

func _calculate_danger_rating(day: int) -> int:
	return starting_danger + (day - 1) * danger_increase_per_day

func get_patience_multiplier() -> float:
	return maxf(minimum_patience_multiplier,
		1.0 - maxi(current_day - 1, 0) * patience_decrease_per_day)

func _calculate_wave_sizes(day: int) -> Array[int]:
	assert(day >= 1)
	assert(min_wave_size >= 2 and max_wave_size >= min_wave_size)
	assert(max_waves >= 1 and max_waves <= 4)
	var sizes: Array[int] = []
	# Fill later waves first; a newly introduced, smaller wave arrives earlier.
	var days_per_wave := max_wave_size - min_wave_size + 1
	var remaining_days := mini(day - 1, max_waves * days_per_wave - 1)
	while remaining_days >= days_per_wave:
		sizes.append(max_wave_size)
		remaining_days -= days_per_wave
	sizes.append(min_wave_size + remaining_days)
	sizes.reverse()
	return sizes

func _update_arrival_config() -> void:
	arrival_config.gradual_customer_count = _calculate_gradual_customer_count(current_day)
	arrival_config.wave_sizes = _calculate_wave_sizes(current_day)
	arrival_config.danger_rating = _calculate_danger_rating(current_day)

func get_dish_unlock_choices() -> Array[Upgrade]:
	var pool: Array[Upgrade] = []
	for upgrade: Unlock_Upgrade in DISH_UNLOCK_UPGRADES:
		if not is_dish_unlocked(upgrade.food_to_unlock):
			pool.append(upgrade)
	
	var choices: Array[Upgrade] = []
	for i in range(mini(2, pool.size())):
		var index := rng.randi_range(0, pool.size() - 1)
		choices.append(pool[index])
		pool.remove_at(index)
	
	return choices

func get_music_speed_multiplier() -> float:
	return pow(1.01, maxi(current_day - 1, 0))

func is_dish_unlocked(dish_name: StringName) -> bool:
	return unlocked_dishes.has(dish_name)
	
func unlock_dish(dish_name: StringName) -> void:
	if not is_dish_unlocked(dish_name):
		unlocked_dishes.append(dish_name)
	
	for upgrade: Unlock_Upgrade in DISH_UNLOCK_UPGRADES:
		if upgrade.food_to_unlock == dish_name:
			upgrade_repo.mark_dependency_satisfied(upgrade.name)
		
func has_drink_unlock(drink_name: StringName) -> bool:
	return unlocked_drinks.has(drink_name)

func unlock_drink(drink_name: StringName) -> void:
	if not has_drink_unlock(drink_name):
		unlocked_drinks.append(drink_name)
