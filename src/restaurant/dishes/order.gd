class_name Order
extends RefCounted

var items: Array[OrderItem] = []
var completed := false

func _init(order_items: Array[OrderItem]):
	items = order_items

func complete_order():
	completed = true

func is_order_completed() -> bool:
	# All items are delivered
	return completed

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
