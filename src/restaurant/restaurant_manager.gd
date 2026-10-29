extends Node2D

var bartable_cashier: Node3D

var sitting_nodes: Array[Node] = []
var customers: Array[Customer] = []
var orders: Array[Order] = []
var menu_data: Dictionary
var drinks_menu_data: Dictionary
var coins: float = 0

# Customers waiting to pay, ordered from the register outward.
var cashier_queue: Array[Customer] = []
const CASHIER_QUEUE_SPACING: float = 1.25

signal coins_updated(amount)

signal angry_customer_left()
# parameterless for now, might need to pass in the exact customers
signal customer_added()
signal customer_removed()

# Signals to the UI to update order changes
# there might be drift between UI and Manager cause UI has to mantain its own state too
# if this is a problem we can add the entire orders array as part of the signal
signal order_added(order: Order)
signal order_removed(order: Order)

func reset() -> void:
	sitting_nodes.clear()
	orders.clear()
	customers.clear()
	cashier_queue.clear()

func register_cashier(cashier: Node3D) -> void:
	bartable_cashier = cashier
	_refresh_cashier_queue()

func enqueue_for_payment(customer: Customer) -> void:
	if not is_instance_valid(customer) or cashier_queue.has(customer):
		return
	cashier_queue.append(customer)
	_refresh_cashier_queue()

func is_next_to_pay(customer: Customer) -> bool:
	return not cashier_queue.is_empty() and cashier_queue[0] == customer

func customer_paid(customer: Customer) -> void:
	if cashier_queue.is_empty() or cashier_queue[0] != customer:
		return
	cashier_queue.pop_front()
	_refresh_cashier_queue()

func remove_from_cashier_queue(customer: Customer) -> void:
	if cashier_queue.has(customer):
		cashier_queue.erase(customer)
		_refresh_cashier_queue()

func _refresh_cashier_queue() -> void:
	if not is_instance_valid(bartable_cashier):
		return
	# The register is the first spot. Positive local Z places the remaining
	# customers behind it; rotate the direction with the cashier scene.
	var behind_direction := bartable_cashier.global_basis.z.normalized()
	for i in cashier_queue.size():
		var customer := cashier_queue[i]
		if not is_instance_valid(customer):
			continue
		var slot := bartable_cashier.global_position + behind_direction * CASHIER_QUEUE_SPACING * i
		customer.set_cashier_queue_target(slot, i == 0)

func load_menu():
	# Load menu
	var file = FileAccess.open("res://data/menu.json", FileAccess.READ)
	var text = file.get_as_text()
	menu_data = JSON.parse_string(text)
	
	# Load drinks menu
	var drinks_file = FileAccess.open("res://data/drinks.json", FileAccess.READ)
	var drinks_text = drinks_file.get_as_text()
	drinks_menu_data = JSON.parse_string(drinks_text)

func get_menu() -> Dictionary:
	return menu_data

func get_drinks_menu() -> Dictionary:
	return drinks_menu_data

func get_customers() -> Array[Customer]:
	return customers

func _ready() -> void:
	load_menu()

func _physics_process(delta: float) -> void:
	pass

func register_sitting_nodes(nodes):
	sitting_nodes = nodes

func add_customer(customer: Customer):
	if customer not in customers && assign_sittingNode(customer):
		customers.append(customer)
		customer_added.emit()

func remove_customer(customer: Customer):
	customers.erase(customer)
	customer_removed.emit()

func remove_angry_customer(customer: Customer):
	# i hope this kills the player if it's last customer
	# last life
	angry_customer_left.emit()
	remove_customer(customer)

func add_order(order: Order):
	if order not in orders:
		orders.append(order)
		order_added.emit(order)
		order.order_completed.connect(_on_order_complete)

func remove_order(order: Order):
	if order in orders:
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

func assign_sittingNode(customer: Customer) -> bool:
	var sittingNode: SittingNode = find_vacant_sittingNode()
	
	if sittingNode == null:
		return false
	
	# Assign sitting node for customer and customer for sitting node
	customer.assign_sitting_node(sittingNode)
	sittingNode.assign_customer(customer)
	
	print("Assigned sittingNode: ", sittingNode.name)
	return true

func receive_payment(amount: float) -> void:
	RunManager.current_run.add_coins(amount)

func get_current_coins() -> float:
	return RunManager.current_run.coins

func get_cashier_location() -> Vector3:
	return bartable_cashier.global_position
