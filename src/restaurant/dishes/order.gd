class_name Order
extends RefCounted

var items: Array[OrderItem] = []
var items_received: Array[OrderItem] = []

func _init(order_items: Array[OrderItem]):
	items = order_items

func find_item_in_order(item_received: OrderItem) -> OrderItem:
	for item in items:
		if item.edible.is_equal(item_received.edible):
			return item
	return null

func is_order_completed() -> bool:
	for item in items:
		var found := false

		for item_received in items_received:
			if item.edible.is_equal(item_received.edible):
				if item_received.quantity >= item.quantity:
					found = true
					break
	
		if not found:
			return false
	
	return true

func get_order_items() -> Array[OrderItem]:
	return items

func get_item(index: int) -> OrderItem:
	return items[index]

func get_order_total_price() -> float:
	var total: float = 0
	for item in items:
		total += item.get_total_price()
		
	return total

func add_order_item(item: OrderItem) -> void:
	items.append(item)

# Return true if successfully received item, else return false
func receive_order_item(item: OrderItem) -> bool:
	# Reject invalid item
	var order_item = find_item_in_order(item)
	if order_item == null :
		return false

	for received_item in items_received:
		if received_item.edible.is_equal(item.edible):
			var remaining_quantity_required = order_item.quantity - received_item.quantity
			if item.quantity > remaining_quantity_required:
				return false
			else:
				received_item.quantity += item.quantity
				items_received.append(item)
				return true
			
	return false
