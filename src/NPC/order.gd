class_name Order

var items: Array[String] = []
var completed := false

func _init(order_items: Array[String]):
	items = order_items

func complete_order():
	completed = true

func is_order_completed() -> bool:
	# All items are delivered
	return completed
