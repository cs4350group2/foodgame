extends Node2D

var sitting_nodes: Array[Node] = []
var customers: Array[Customer] = []
var orders: Array[Order] = []
var menu_data: Dictionary
var coins: float = 0

signal coins_updated(amount)
const MUD_DAGORED = preload("uid://dibhfexgjqvj")

# Signals to the UI to update order changes
# there might be drift between UI and Manager cause UI has to mantain its own state too
# if this is a problem we can add the entire orders array as part of the signal
signal order_added(order: Order)
signal order_removed(order: Order)

func load_menu():
	var file = FileAccess.open("res://data/menu.json", FileAccess.READ)
	var text = file.get_as_text()
	menu_data = JSON.parse_string(text)

func get_menu() -> Dictionary:
	return menu_data

func _ready() -> void:
	load_menu()
	AudioManager.play_bgm(MUD_DAGORED)

func _physics_process(delta: float) -> void:
	pass

func register_sitting_nodes(nodes):
	sitting_nodes = nodes

func add_customer(customer: Customer):
	if customer not in customers:
		customers.append(customer)
		assign_sittingNode(customer)

func remove_customer(customer: Customer):
	customers.erase(customer)
	
func add_order(order: Order):
	orders.append(order)
	order_added.emit(order)
	order.order_completed.connect(_on_order_complete)

func remove_order(order: Order):
	orders.erase(order)
	order_removed.emit(order)

func _on_order_complete(order: Order):
	remove_order(order)

func complete_order(order: Order):
	order.complete_order()
	remove_order(order)

func has_vacant_sittingNode() -> bool:
	for node in sitting_nodes:
		if node.is_vacant():
			return true
		
	return false

func find_vacant_sittingNode() -> SittingNode:
	for node in sitting_nodes:
		if node.is_vacant():
			node.reserve()
			return node
		
	return null

func assign_sittingNode(customer: Customer):
	var sittingNode: SittingNode = find_vacant_sittingNode()
	
	if sittingNode == null:
		return
	
	# Assign sitting node for customer and customer for sitting node
	customer.assign_sitting_node(sittingNode)
	sittingNode.assign_customer(customer)
	
	print("Assigned sittingNode: ", sittingNode.name)

func receive_payment(amount: float) -> void:
	print("Coins: ", coins, " + ", amount)
	coins += amount
	coins_updated.emit(coins)

func get_current_coins() -> float:
	return coins
