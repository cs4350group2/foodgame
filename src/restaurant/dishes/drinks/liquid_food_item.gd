extends EdibleItem

var item_name: String = "Liquid Food"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	initialize_data(item_name, true)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func affect_customer(customer: Customer) -> bool:
	var customer_state = customer.get_current_state()
	var acceptable_states = [customer.State.WAITING_FOR_FOOD]
	
	# Only affect customer if customer waiting for food
	if customer_state in acceptable_states:
		var customer_order: Order = customer.get_order()
		var order_items = customer_order.get_order_items()
		var received_items = customer_order.get_items_received()
		
		for item in order_items:
			var received_item = customer_order.find_received_item_in_order(item)
			if received_item:
				if received_item.get_quantity() < item.get_quantity():
					# Order havent receive sufficient qty of this item
					var liquid_food: Food = item.get_edible()
					liquid_food.set_dish_quality(50.0)
					var liquid_food_item = OrderItem.new(liquid_food, 1)
					customer_order.receive_order_item(liquid_food_item)
				else: # Order already received sufficient qty of this item
					continue
			else: # Order havent receive this item yet
				var liquid_food: Food = item.get_edible()
				liquid_food.set_dish_quality(50.0)
				var liquid_food_item = OrderItem.new(liquid_food, 1)
				customer_order.receive_order_item(liquid_food_item)
		
		return true
	else:
		return false
