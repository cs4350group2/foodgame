class_name Celebrity_Customer
extends Customer

@onready var celebrity_animation_player: AnimationPlayer = $CharacterBody3D/ModelOffset/CelebrityCustomerModel/Character/AnimationPlayer
@onready var model_offset: Node3D = $CharacterBody3D/ModelOffset

var default_position: Vector3
var dish_quality_requirement: float = 0.0

func _ready() -> void:
	super._ready()
	default_position = model_offset.position
	show_spawn_notification()
	apply_starstruck_effects()

func _exit_tree() -> void:
	remove_starstruck_effects()

func initialize_celebrity_customer(name: String, level: int, patience: float, 
							 type: StringName, requirement: float = 70.0) -> void:
	initialize_customer(name, level, patience, type)
	dish_quality_requirement = requirement

func get_dish_quality_requirement() -> float:
	return dish_quality_requirement

func start_ordering() -> void:
	patience = max_patience
	patience_bar.update_patience(max_patience)
	# Decide order
	if order == null:
		var menu: Dictionary = RestaurantManager.get_menu()
		var order_items: Array[OrderItem] = []
		for i in range(3):
			var foods: Array = menu["foods"]
			var food_data = foods[RunManager.get_rng().randi_range(0, foods.size() - 1)]
			print(food_data["name"], food_data["price"], food_data["rarity"])
			var food = Food.new(food_data["name"], food_data["price"], food_data["rarity"])
			var order_item = OrderItem.new(food, customer_lvl)
			order_items.append(order_item)
		order = Order.new(order_items)
		order.order_completed.connect(_on_order_complete)
	play_audio(AudioSfx.ORDERING)

func receive_order_item(item: OrderItem) -> bool:
	if current_state != State.WAITING_FOR_FOOD:
		return false
	
	if StatusEffect.TASTELESS in current_status_effects and StatusEffect.BLIND in current_status_effects:
		return anyhow_receive_order_item()
	
	if StatusEffect.TASTELESS in current_status_effects:
		return tasteless_receive_order_item(item)
	
	if StatusEffect.BLIND in current_status_effects:
		return blind_receive_order_item(item)
	
	var food: Food = item.get_edible()
	var dish_quality: float = food.get_dish_quality()
	if dish_quality >= dish_quality_requirement:
		return order.receive_order_item(item)
	else:
		return false

func apply_starstruck_effects() -> void:
	var customers: Array[Customer] = RestaurantManager.get_customers()
	for customer in customers:
		if not self.is_equal(customer):
			customer.apply_starstruck_effect()

func remove_starstruck_effects() -> void:
	var customers: Array[Customer] = RestaurantManager.get_customers()
	for customer in customers:
		if not self.is_equal(customer):
			customer.stop_starstruck_effect()

func play_animation(anim: String) -> void:
	reset_offset()
	match anim:
		"Idle":
			celebrity_animation_player.play("mixamo_com")
		
		"Walk":
			celebrity_animation_player.play("AnimLib/Proud_Walk")
		
		"Sitting_Idle":
			model_offset.position.x += 0.0
			model_offset.position.y -= 1.1
			celebrity_animation_player.play("AnimLib/Sitting_Idle_Celeb")
		_:
			pass

func reset_offset() -> void:
	model_offset.position = default_position

func take_payment() -> float:
	paid = true
	# Gives 3x bonus
	return order.get_order_total_price() + order.get_total_bonus() * 3

func show_spawn_notification() -> void:
	var message: String = notification_data["special_customer_notification"].get(customer_type)
	var description_message: String = notification_data["special_customer_descriptions"].get(customer_type)
	restaurant_ui.show_notification_top(message, true, description_message)
