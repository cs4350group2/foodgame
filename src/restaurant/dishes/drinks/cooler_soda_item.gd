extends EdibleItem

var item_name: String = "Cooler Soda"
var increment: float = 30.0

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
	var acceptable_states = [customer.State.ORDERING, 
							customer.State.WAITING_FOR_FOOD]
	
	if customer_state in acceptable_states:
		var curr_patience = customer.get_current_patience()
		var new_patience = curr_patience + increment
		customer.set_patience(new_patience)
		customer.show_patience_gain()
		return true
	else:
		return false
