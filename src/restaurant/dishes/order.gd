class_name Order
extends RefCounted

signal order_completed(order: Order)
signal order_item_received(item: OrderItem, quantity: int)

var items: Array[OrderItem] = []
var items_received: Array[OrderItem] = []

func _init(order_items: Array[OrderItem]):
	items = order_items

func find_item_in_order(item_received: OrderItem) -> OrderItem:
	for item in items:
		if item.get_edible().is_equal(item_received.get_edible()):
			return item
	return null

func find_received_item_in_order(item: OrderItem) -> OrderItem:
	for received_item in items_received:
		if received_item.get_edible().is_equal(item.get_edible()):
			return received_item
	return null

func is_order_completed() -> bool:
	# this check requires OrderItems to all have a unique edible
	# maybe a dictionary then would be better?
	for item in items:
		var found := false

		for item_received in items_received:
			if item.get_edible().is_equal(item_received.get_edible()):
				print("Required quantity: ", item.get_quantity())
				print("Received quantity: ", item_received.get_quantity())
				if item_received.get_quantity() >= item.get_quantity():
					found = true
					break
	
		if not found:
			return false
	
	return true

func get_order_items() -> Array[OrderItem]:
	return items

func get_items_received() -> Array[OrderItem]:
	return items_received

func get_item(index: int) -> OrderItem:
	return items[index]

func get_order_total_price() -> float:
	var total: float = 0
	for item in items:
		total += item.get_total_price()
		
	return total

# Assume that items won't be added midway. If not, we will have to create signals for this.
func add_order_item(item: OrderItem) -> void:
	items.append(item)

# Return true if successfully received item, else return false
func receive_order_item(item: OrderItem) -> bool:
	# Reject invalid item
	var order_item = find_item_in_order(item)
	if order_item == null:
		return false

	for received_item in items_received:
		if received_item.get_edible().is_equal(item.get_edible()):
			var remaining_quantity_required = order_item.get_quantity() - received_item.get_quantity()
			if item.get_quantity() > remaining_quantity_required:
				return false
			received_item.add_quantity(item.get_quantity())
			order_item_received.emit(item, received_item.get_quantity())
			if is_order_completed():
				order_completed.emit(self)
			return true

	if item.get_quantity() > order_item.get_quantity():
		return false
	items_received.append(item)
	order_item_received.emit(item, item.get_quantity())
	if is_order_completed():
		order_completed.emit(self)
	return true
