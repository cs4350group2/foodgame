extends Node3D
class_name Level

@onready var player: Player = %Player

@export var ui_nodes: Array[Node]
var temp_nodes: Dictionary[int, Node] = {}
@onready var day_manager: DayManager = %DayManager
@onready var restaurant_ui: RestaurantUI = $RestaurantUi

@export var available_customers: Array[CustomerSpawnRule] = [
	CustomerSpawnRule.new(&"VIP", 2),
	CustomerSpawnRule.new(&"Hobo", 1),
	CustomerSpawnRule.new(&"Impatient", 1),
	CustomerSpawnRule.new(&"FoodCritic", 2),
]

# This comes from RestaurantRun.current_upgrades, replaying those effects
# rebuilds this level's unlocked set without changing the customer catalog.
var unlocked_customer_types: Array[StringName] = []

signal clear_temp()

func unlock_customer_type(cust_name: StringName, cust_weight: float) -> void:
	update_customer_type(cust_name, cust_weight)
	if not unlocked_customer_types.has(cust_name):
		unlocked_customer_types.append(cust_name)

# Updates the selection weight of a customer type in the available rule list.
func update_customer_type(cust_name: StringName, cust_weight: float):
	for rule in available_customers:
		if cust_name == rule.customer_type:
			rule.selection_weight = cust_weight
			return
	push_error("No customer spawn rule configured for %s." % cust_name)

# I can't think of a good name for this function
func clear_temp_nodes() -> void:
	clear_temp.emit()
	for n: Node in temp_nodes.values():
		if is_instance_valid(n):
			n.queue_free()
	temp_nodes.clear()

func _ready() -> void:
	day_manager.day_starting.connect(clear_temp_nodes)

func register_temp(temp: Node):
	temp_nodes[temp.get_instance_id()] = temp

func unregister_temp(temp: Node):
	if temp_nodes.has(temp.get_instance_id()):
		temp_nodes.erase(temp.get_instance_id())

func _exit_tree() -> void:
	RestaurantManager.reset()

func generate_arrivals(config: ArrivalConfig) -> Array[CustomerArrival]:
	# Unlock eligibility is independent of weight, so weight modifiers cannot
	# introduce a customer before its milestone upgrade has been granted.
	var unlocked_rules: Array[CustomerSpawnRule] = []
	for rule in available_customers:
		if unlocked_customer_types.has(rule.customer_type):
			unlocked_rules.append(rule)
	return CustomerArrivalGenerator.new().generate(config, unlocked_rules, RunManager.get_rng())

func generate_customers(config: ArrivalConfig) -> void:
	var arrivals := generate_arrivals(config)
	if not arrivals.is_empty():
		day_manager.setup(arrivals)
