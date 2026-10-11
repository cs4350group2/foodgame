class_name VIP_Customer
extends Customer

var dish_quality_requirement: float = 0.0

func receive_order_item(item: OrderItem) -> bool:
	if current_state != State.WAITING_FOR_FOOD:
		return false
	
	# if the order is finished, we let the signal tell us
	var food: Food = item.get_edible()
	var dish_quality: float = food.get_dish_quality()
	if dish_quality >= dish_quality_requirement:
		return order.receive_order_item(item)
	else:
		return false
