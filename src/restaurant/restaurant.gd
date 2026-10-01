class_name Restaurant
extends Node

@onready var sittingNodes = $SittingNodes.get_children()
@onready var customer_spawner: CustomerSpawner = $CustomerSpawner
@onready var day_manager: DayManager = $DayManager

func _ready():
	RestaurantManager.register_sitting_nodes(sittingNodes)
	if not customer_spawner:
		push_error("Customer Spawner not found!")
		return
	if not day_manager:
		push_error("Day manager not found!")
		return
	day_manager.spawn_customer.connect(customer_spawner.spawn_customer)
	day_manager.setup_with_uniform_arrival(5.0, 300.0, 6)
