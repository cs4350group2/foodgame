extends Node3D
class_name Level

@onready var player: Player = %Player

class CustomerDistribution:
	var cust_name: StringName
	var spawn_weight: float

	func _init(ct: StringName, sw: float):
		cust_name = ct
		spawn_weight = sw

@export var ui_nodes: Array[Node]
@export var jitter_amount := 0.1
var temp_nodes: Dictionary[int, Node] = {}
@onready var day_manager: DayManager = %DayManager

var available_customers: Array[CustomerDistribution] = [CustomerDistribution.new(&"regular", 100.0)]
var total_weight: float = 100.0

signal clear_temp()

# Updates the weight of a customer type, or adds it if it doesn't already exist
func update_customer_type(cust_name: StringName, cust_weight: float):
	for cd: CustomerDistribution in available_customers:
		if cust_name == cd.cust_name:
			total_weight += cust_weight - cd.spawn_weight
			cd.spawn_weight = cust_weight
			return
	available_customers.append(CustomerDistribution.new(cust_name, cust_weight))
	total_weight += cust_weight

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

func choose_customer(rng: RandomNumberGenerator) -> StringName:
	var value := rng.randf_range(0.0, total_weight)
	for cust: CustomerDistribution in available_customers:
		if value < cust.spawn_weight:
			return cust.cust_name
		else: value -= cust.spawn_weight
	# if we somehow don't get anybody, return the first customer
	return available_customers[0].cust_name

func generate_arrivals(config: ArrivalConfig) -> Array[CustomerArrival]:
	var rng := RunManager.get_rng()
	var res: Array[CustomerArrival] = []
	var current := config.first_arrival_delay

	assert(config.num_customers > 0)

	var average_difference := 0.0 if config.num_customers == 0 else config.total_time / (config.num_customers - 1)
	var random_jitter := 0.0 # random offset either way up to 10% of the spawn difference,
	# hopefully this makes for a more natural feeling arrival

	for i in range(config.num_customers):
		var cust_type := choose_customer(rng)
		var cust_arrival := CustomerArrival.new(cust_type, current + random_jitter)
		res.append(cust_arrival)

		current += average_difference
		var jitter_range := average_difference * jitter_amount
		random_jitter = rng.randf_range(-jitter_range, jitter_range)
	return res

func generate_customers(config: ArrivalConfig) -> void:
	day_manager.setup(generate_arrivals(config))
