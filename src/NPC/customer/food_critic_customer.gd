class_name FoodCritic_Customer
extends Customer

@onready var food_critic_animation_player: AnimationPlayer = $CharacterBody3D/ModelOffset/FoodCritic/AnimationPlayer
@onready var model_offset: Node3D = $CharacterBody3D/ModelOffset

var default_position: Vector3
var satisfied_threshold: float = 0.0 # If dish quality lower, other customers lose patience
var impressed_threshold: float = 100.0 # If higher quality, other customers gain patience
var patience_boost: float = 10.0

func _ready() -> void:
	super._ready()
	default_position = model_offset.position

func initialize_food_critic(name: String, level: int, patience: float, 
							 type: StringName, satisfied: float = 70.0,
							impressed: float = 90.0, boost: float = 10.0) -> void:
	initialize_customer(name, level, patience, type)
	satisfied_threshold = satisfied
	impressed_threshold = impressed
	patience_boost = boost

func get_satisfied_threshold() -> float:
	return satisfied_threshold

func get_impressed_threshold() -> float:
	return impressed_threshold

func receive_order_item(item: OrderItem) -> bool:
	if current_state != State.WAITING_FOR_FOOD:
		return false
	
	var food: Food = item.get_edible()
	var dish_quality: float = food.get_dish_quality()
	var received: bool = order.receive_order_item(item)
	
	if not received:
		return false
	
	# Apply effect based on dish quality
	if dish_quality < satisfied_threshold:
		apply_unsatisfied_effect()
	elif dish_quality >= impressed_threshold:
		apply_impressed_effect()
	
	return received

func apply_unsatisfied_effect() -> void:
	var customers: Array[Customer] = RestaurantManager.get_customers()
	for customer in customers:
		if not self.is_equal(customer):
			var new_patience = customer.get_current_patience() - patience_boost
			var new_max_patience = customer.get_max_patience() - patience_boost
			customer.set_patience(new_patience)
			customer.set_max_patience(new_max_patience)
			customer.patience_bar.set_patience(
				0.0,
				max_patience,
				max_patience / 100.0
			)

func apply_impressed_effect() -> void:
	var customers: Array[Customer] = RestaurantManager.get_customers()
	for customer in customers:
		if not self.is_equal(customer):
			var new_patience = customer.get_current_patience() + patience_boost
			var new_max_patience = customer.get_max_patience() + patience_boost
			customer.set_patience(new_patience)
			customer.set_max_patience(new_max_patience)
			customer.patience_bar.set_patience(
				0.0,
				max_patience,
				max_patience / 100.0
			)

func play_animation(anim: String) -> void:
	reset_offset()
	match anim:
		"Idle":
			food_critic_animation_player.play("Idle")
		
		"Walk":
			food_critic_animation_player.play("Walk")
		
		"Sitting_Idle":
			model_offset.position.x -= 0.4
			model_offset.position.y += 0.4
			food_critic_animation_player.play("Sitting_Idle")
		_:
			pass

func reset_offset() -> void:
	model_offset.position = default_position
