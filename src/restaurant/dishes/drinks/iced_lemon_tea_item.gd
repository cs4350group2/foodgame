extends EdibleItem

var item_name: String = "Iced Lemon Tea"
var mood_bonus: float = 10.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interaction.interacted.connect(_on_interacted)
	initialize_data(item_name, true)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func affect_customer(customer: Customer) -> bool:
	var customer_state = customer.get_current_state()
	var acceptable_states = [customer.State.WAITING_FOR_FOOD]
	
	if customer_state in acceptable_states:
		customer.add_mood_bonus(mood_bonus)
		return true
	else:
		return false
