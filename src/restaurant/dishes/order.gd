class_name Order
extends RefCounted

var items: Array[OrderItem] = []
var items_received: Array[OrderItem] = []

func _init(order_items: Array[OrderItem]):
	items = order_items

func is_item_in_order(item_received: OrderItem) -> bool:
	for item in items:
		if item.edible.is_equal(item_received.edible):
			return true
	return false

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
		total += item.get_price()
		
	return total

func add_order_item(item: OrderItem) -> void:
	items.append(item)

func receive_order_item(item_received: OrderItem) -> void:
	# Reject invalid item
	if not is_item_in_order(item_received):
		return

	for item in items_received:
		if item.edible.is_equal(item_received.edible):
			item.quantity += item_received.quantity
			return

	items_received.append(item_received)
