extends EdibleItem

var item_name: String = "Soda"
var increment: float = 10.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interaction.interacted.connect(_on_interacted)
	initialize_data(item_name, true)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func affect_customer(customer: Customer) -> void:
	var curr_patience = customer.get_current_patience()
	var new_patience = curr_patience + increment
	customer.set_patience(new_patience)
