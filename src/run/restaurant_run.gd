extends Resource
class_name RestaurantRun

var starting_customers: int = 3
var starting_total_time: float = 45.0
var starting_first_arrival_delay: float = 10.0

# how many customers arrive, and the total time they spawn in
var customer_increase: int = 2
var total_time_change: float = 20.0

var current_upgrades: Array[Upgrade]
var upgrade_repo: UpgradeRepo
var current_day: int = 0
var coins: float = 0

var rng_seed: int = 0
var rng : RandomNumberGenerator

var arrival_config: ArrivalConfig = ArrivalConfig.new()

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
	arrival_config = ArrivalConfig.new()
	arrival_config.num_customers = starting_customers
	arrival_config.total_time = starting_total_time
	arrival_config.first_arrival_delay = starting_first_arrival_delay
	rng_seed = run_seed
	rng = RandomNumberGenerator.new()
	if set_seed:
		rng.seed = run_seed
	else:
		rng_seed = rng.seed
	print("New run started with seed ", rng.seed)

func apply_upgrades(level: Level) -> void:
	for upgrade: Upgrade in current_upgrades:
		upgrade.apply_effect(level)

func add_upgrade(new_upgrade: Upgrade) -> void:
	current_upgrades.append(new_upgrade)
	upgrade_repo.on_upgrade_chosen(new_upgrade)

func get_random_available_upgrades(n: int) -> Array[Upgrade]:
	return upgrade_repo.get_random_upgrades(n, rng)


func progress_day() -> void:
	current_day += 1
	# idk
	arrival_config.num_customers += customer_increase
	arrival_config.total_time += total_time_change
