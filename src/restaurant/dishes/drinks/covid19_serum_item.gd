extends EdibleItem

var item_name: String = "Covid-19 Serum"

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
	var acceptable_states = [customer.State.IDLE,
							customer.State.WALKING_TO_TABLE,
							customer.State.SITTING,
							customer.State.ORDERING,
							customer.State.WAITING_FOR_FOOD,
							customer.State.EATING,
							customer.State.WALKING_TO_CASHIER,
							customer.State.PAYING,
							customer.State.LEAVING,
							customer.State.LEAVING_ANGRY,]
	
	if customer_state in acceptable_states:
		# Customer now accepts any food and any quality
		
		return true
	else:
		return false
