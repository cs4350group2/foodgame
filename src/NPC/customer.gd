class_name Customer
extends CharacterBody3D

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $CharacterBody3D/Timmy/AnimationPlayer
@onready var interaction: InteractComponent = $InteractComponent

enum State {
	IDLE,
	WALKING_TO_TABLE,
	SITTING,
	ORDERING,
	WAITING_FOR_FOOD,
	EATING,
	FINISHED,
	LEAVING
}

func get_state_name(state: State) -> String:
	return State.keys()[state]

var current_state = State.IDLE
var assigned_sittingNode: SittingNode = null
var order_taken = false
var paid = false
var order: Order
var move_speed = 2.0
var customer_lvl: int
var customer_name: String

func get_customer_name() -> String:
	return customer_name

func assign_sitting_node(node: SittingNode):
	self.assigned_sittingNode = node

func initialize_customer(name: String, level: int, patience: float) -> void:
	customer_name = name
	customer_lvl = level
	max_patience = patience

func _ready():
	interaction.interacted.connect(_on_interacted)
	change_state(State.IDLE)

func _on_interacted(_player: Player) -> void:
	match current_state:
		State.ORDERING:
			take_order()
			
		State.WAITING_FOR_FOOD:
			change_state(State.EATING)
		
		State.FINISHED:
			take_payment()
			
	print("Interacted with the customer.")

func _physics_process(delta):
	match current_state:
		State.IDLE:
			state_idle(delta)
		State.WALKING_TO_TABLE:
			state_walking_to_table(delta)
		State.SITTING:
			state_sitting(delta)
		State.ORDERING:
			state_ordering(delta)
		State.WAITING_FOR_FOOD:
			state_waiting_for_food(delta)
		State.EATING:
			state_eating(delta)
		State.FINISHED:
			state_finished(delta)
		State.LEAVING:
			state_leaving(delta)

func move_toward_navigation_target() -> void:
	var next_position := nav_agent.get_next_path_position()
	var direction := global_position.direction_to(next_position)

	velocity = direction * move_speed
	move_and_slide()

func update_target_location(target_location):
	nav_agent.target_position = target_location

func _process(delta: float) -> void:
	match current_state:
		pass

# -------------- State Management ----------------------------------

func change_state(new_state: State):
	if current_state == new_state:
		return
		
	print("Changing state from: ", get_state_name(current_state), " to ", get_state_name(new_state))
	exit_state(current_state)
	current_state = new_state
	enter_state(new_state)
	
func enter_state(state: State):
	match state:
		State.IDLE:
			pass
		
		State.WALKING_TO_TABLE:
			pass

		State.SITTING:
			# Start sitting animation
			# Play reading menu animation for random seconds
			# $AnimationPlayer.play("sit")
			var view_menu_time = randf_range(5.0, 10.0)
			wait_at_table(view_menu_time)
			pass

		State.ORDERING:
			# Tell waiter/customer system that we're ordering
			pass

		State.WAITING_FOR_FOOD:
			start_waiting_for_food()
			pass

		State.EATING:
			# $AnimationPlayer.play("eat")
			pass

		State.FINISHED:
			pass

		State.LEAVING:
			pass

func exit_state(state:State):
	match state:
		State.IDLE:
			pass

		State.WALKING_TO_TABLE:
			pass

		State.SITTING:
			pass

		State.ORDERING:
			pass

		State.WAITING_FOR_FOOD:
			pass

		State.EATING:
			pass

		State.FINISHED:
			pass

		State.LEAVING:
			pass

# States

func state_idle(delta):
	# Decide what the customer should do next
	RestaurantManager.add_customer(self)
	
	if assigned_sittingNode != null:
		change_state(State.WALKING_TO_TABLE)

func state_walking_to_table(delta):
	# Set navigation target somewhere else
	# navigation_agent.target_position = table_position
	update_target_location(assigned_sittingNode.global_position)
	#animation_player.play("Walk")

	if nav_agent.is_navigation_finished():
		change_state(State.SITTING)
		return
	
	move_toward_navigation_target()

var done_waiting_at_table: bool
func wait_at_table(view_menu_time: float) -> void:
	print("Customer is looking at menu for ", view_menu_time, " seconds")
	done_waiting_at_table = false
	await get_tree().create_timer(view_menu_time).timeout
	done_waiting_at_table = true

func state_sitting(delta):
	# Wait until sitting animation finish
	# Execute sitting animation here
	if done_waiting_at_table:
		change_state(State.ORDERING)

func take_order() -> void:
	RestaurantManager.add_order(order)
	order_taken = true

func state_ordering(delta):
	# Decide order
	if order == null:
		var menu: Dictionary = RestaurantManager.get_menu()
		var food_data = menu["foods"].pick_random()
		print(food_data["name"], food_data["price"], food_data["rarity"])
		var food = Food.new(food_data["name"], food_data["price"], food_data["rarity"])
		var order_item = OrderItem.new(food, customer_lvl)
		order = Order.new([order_item])
		
	if order_taken:
		change_state(State.WAITING_FOR_FOOD)

# Seconds that the customer will wait
@export var max_patience: float
var patience: float

func get_current_patience() -> float:
	return patience

func start_waiting_for_food() -> void:
	patience = max_patience

func state_waiting_for_food(delta):
	# Wait until restaurant tells us the food is ready
	patience -= delta
	if patience <= 0.0:
		patience = 0.0
		print(self, " leaving because out of patience")
		change_state(State.LEAVING)

	if order.is_order_completed():
		change_state(State.EATING)

func state_eating(delta):
	# Play eating animation
	# Decrease food/eating timer
	var finish_eating = false
	var eating_time = 20
	
	await get_tree().create_timer(eating_time).timeout
	finish_eating = true
	
	if finish_eating:
		change_state(State.FINISHED)

func take_payment() -> float:
	paid = true
	return order.get_order_total_price()

func state_finished(delta):
	# Pay, finish eating, etc.
	
	# Go to counter/Leave money on table for collection
	
	if paid:
		change_state(State.LEAVING)


func state_leaving(delta):
	# Walk toward the restaurant exit
	# update_target_location(exit)
	
	move_toward_navigation_target()
	
	if nav_agent.is_navigation_finished():
		if assigned_sittingNode != null:
			assigned_sittingNode.clear()
		
		queue_free()
		return
