class_name Customer
extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D
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

var current_state = State.IDLE
var assigned_sittingNode: SittingNode = null

func _ready():
	change_state(State.IDLE)

func _physics_process(delta):
	var current_location = global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	var new_velocity = (next_location - current_location).normalized() * move_speed
	
	velocity = new_velocity
	move_and_slide()

func update_target_location(target_location):
	nav_agent.target_position = target_location

# State Management

func change_state(new_state: State):
	if current_state == new_state:
		return
		
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
	world.assign_sittingNode(self)
	
	if assigned_sittingNode != null:
		change_state(State.WALKING_TO_TABLE)

func state_walking_to_table(delta):
	# Set navigation target somewhere else
	# navigation_agent.target_position = table_position
	update_target_location(assigned_sittingNode.global_position)

	if nav_agent.is_navigation_finished():
		change_state(State.SITTING)
		return

	var next_position = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_position)

	velocity = direction * move_speed
	move_and_slide()


func state_sitting(delta):
	# Wait for some amount of time before ordering

	# Example:
	# if sit_timer <= 0:
	#     change_state(State.ORDERING)

	pass


func state_ordering(delta):
	# Choose food / send order to restaurant system

	# Example:
	# order = choose_random_food()
	# restaurant.place_order(self, order)

	change_state(State.WAITING_FOR_FOOD)


func state_waiting_for_food(delta):
	# Wait until restaurant tells us the food is ready

	# Example:
	# if food_received:
	#     change_state(State.EATING)

	pass


func state_eating(delta):
	# Play eating animation
	# Decrease food/eating timer

	# Example:
	# if eating_timer <= 0:
	#     change_state(State.FINISHED)

	pass


func state_finished(delta):
	# Pay, finish eating, etc.

	change_state(State.LEAVING)


func state_leaving(delta):
	# Walk toward the restaurant exit

	if nav_agent.is_navigation_finished():
		if assigned_sittingNode != null:
			assigned_sittingNode.free()
		
		queue_free()
		return
		
	var next_position = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_position)

	velocity = direction * move_speed
	move_and_slide()
