extends Node2D

var sitting_nodes: Array[Node] = []
var customers: Array[Customer] = []
var orders: Array[Order] = []
var menu_data: Dictionary

func load_menu():
	var file = FileAccess.open("res://data/menu.json", FileAccess.READ)
	var text = file.get_as_text()
	menu_data = JSON.parse_string(text)

func get_menu() -> Dictionary:
	return menu_data

func _ready() -> void:
	load_menu()

func _physics_process(delta: float) -> void:
	pass

func register_sitting_nodes(nodes):
	sitting_nodes = nodes

func add_customer(customer: Customer):
	customers.append(customer)
	assign_sittingNode(customer)

func remove_customer(customer: Customer):
	customers.erase(customer)
	
func add_order(order: Order):
	orders.append(order)

func remove_order(order: Order):
	orders.erase(order)

func complete_order(order: Order):
	order.complete_order()
	remove_order(order)

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
