extends Resource
class_name UpgradeRepo

# Shared upgrade definitions. Keep per-run ownership separate from these Resources.
# JSON format: { "upgrade_id": "res://path/to/upgrade.tres" }

static var upgrade_catalog: Dictionary[StringName, Upgrade] = {}
# upgrades with no dependencies
static var starter_upgrades: Dictionary[StringName, Upgrade] = {}

static var is_catalog_loaded := false

static func load_catalog(path: String = "res://src/upgrades/upgrades.txt") -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	assert(file != null)
	var text := file.get_as_text()
	
	while not file.eof_reached():
		var resource_path := file.get_line().strip_edges()
		if resource_path.is_empty() or resource_path.begins_with("#"):
			continue
		
		assert(ResourceLoader.exists(resource_path))
		
		var upgrade := load(resource_path) as Upgrade
		
		assert(upgrade != null)
		assert(upgrade.name != "")
		upgrade_catalog[upgrade.name] = upgrade
	file.close()
	
	load_starter_upgrades()
	is_catalog_loaded = true

static func load_starter_upgrades() -> void:
	for u: Upgrade in upgrade_catalog.values():
		if len(u.dependencies) == 0:
			starter_upgrades[u.name] = u

var available_upgrades: Dictionary[StringName, Upgrade] = {}
# yea i would rather use a set but whatever
var chosen_ids: Dictionary[StringName, int] = {}

func _init() -> void:
	if not is_catalog_loaded:
		push_error("Error initializing upgrade repo: Static catalog has not been loaded.")
	available_upgrades = starter_upgrades.duplicate_deep()

func on_upgrade_chosen(upgrade: Upgrade) -> void:
	assert(available_upgrades.has(upgrade.name))
	# add the upgrade to active upgrades
	chosen_ids[upgrade.name] = 1
	# remove the upgrades from available upgrades
	available_upgrades.erase(upgrade.name)
	# find all upgrades that we fulfil dependencies and add it
	for u: Upgrade in upgrade_catalog.values():
		if chosen_ids.has(u.name) or available_upgrades.has(u.name):
			continue
		var to_add = true
		for dep: StringName in u.dependencies:
			to_add = to_add and chosen_ids.has(dep)
		if to_add:
			available_upgrades[u.name] = u

func get_random_upgrades(n: int, rng: RandomNumberGenerator) -> Array[Upgrade]:
	var pool: Array[Upgrade] = []
	pool.assign(available_upgrades.values())
	
	var result: Array[Upgrade] = []
	var count := clampi(n, 0, pool.size())
	
	for i in range(count):
		var index := rng.randi_range(0, pool.size() - 1)
		result.append(pool[index])
		pool.remove_at(index)
	
	return result
