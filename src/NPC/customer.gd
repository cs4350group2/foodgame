class_name Customer
extends CharacterBody3D

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $CharacterBody3D/Timmy/AnimationPlayer
@onready var world = get_tree().current_scene

var move_speed = 2.0

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
var order: Order

func assign_sitting_node(node: SittingNode):
	self.assigned_sittingNode = node

func _ready():
	change_state(State.IDLE)

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

# State Management

func change_state(new_state: State):
	if current_state == new_state:
		return
		
	print("Changing state from: ", get_state_name(current_state), " to ", get_state_name(new_state))
	exit_state(current_state)
	current_state = new_state
	enter_state(current_state)
	
func enter_state(state: State):
	match state:
		State.IDLE:
			pass
		
		State.WALKING_TO_TABLE:
			pass

		State.SITTING:
			# Start sitting animation
			# $AnimationPlayer.play("sit")
			pass

		State.ORDERING:
			# Tell waiter/customer system that we're ordering
			pass

		State.WAITING_FOR_FOOD:
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

func state_sitting(delta):
	# Wait for some amount of time before ordering

	# Wait until sitting animation finish
	# Execute sitting animation here
	
	# Play reading menu animation for random seconds
	var view_menu_time = randf_range(5.0, 10.0)
	
	await get_tree().create_timer(view_menu_time).timeout
	
	change_state(State.ORDERING)

func take_order() -> Order:
	order_taken = true
	return order

func state_ordering(delta):
	# Choose food / send order to restaurant system
	order = Order.new(["Burger", "Fries"])

	# Example:
	# order = choose_random_food()
	# restaurant.place_order(self, order)

	if order_taken:
		change_state(State.WAITING_FOR_FOOD)

func state_waiting_for_food(delta):
	# Wait until restaurant tells us the food is ready

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

func state_finished(delta):
	# Pay, finish eating, etc.
	var paid = false
	
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
