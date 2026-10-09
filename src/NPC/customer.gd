class_name Customer
extends CharacterBody3D

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $CharacterBody3D/Timmy/AnimationPlayer
@onready var interaction: InteractComponent = $InteractComponent
@onready var patience_bar: PatienceBar = $PatienceBar
@onready var customer_spawner: CustomerSpawner = get_parent() as CustomerSpawner
@onready var audio_player = $AudioStreamPlayer3D

const HMM_SFX = preload("res://assets/sfx/customer/hmm_sfx.mp3")
const ORDER_READY_SFX = preload("res://assets/sfx/customer/order_sfx.wav")
const ORDER_COMPLETE_SFX = preload("res://assets/sfx/customer/satisfied_sfx.wav")
const ANGRY_SFX = preload("res://assets/sfx/customer/angry_sfx.wav")
const ENTER_SFX = preload("res://assets/sfx/customer/enter_sfx.wav")
const ORDER_TAKEN_SFX = preload("res://assets/sfx/customer/order_taken.ogg")
const LEAVING_SFX = preload("res://assets/sfx/customer/leaving_sfx.wav")

enum State {
	IDLE,
	WALKING_TO_TABLE,
	SITTING,
	ORDERING,
	WAITING_FOR_FOOD,
	EATING,
	FINISHED,
	LEAVING,
	LEAVING_ANGRY
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
var exit_point: Marker3D
var prev_transform: Transform3D

func get_customer_name() -> String:
	return customer_name

func assign_sitting_node(node: SittingNode):
	self.assigned_sittingNode = node

func initialize_customer(name: String, level: int, patience: float) -> void:
	customer_name = name
	customer_lvl = level
	max_patience = patience

func _ready():
	interaction.interact_while_holding = true
	interaction.interacted.connect(_on_interacted)
	audio_player.pitch_scale = randf_range(0.67, 1.3)
	change_state(State.IDLE)
	patience_bar.set_patience(0.0, max_patience, max_patience / 100.0)

func _on_interacted(_player: Player) -> void:
	match current_state:
		State.ORDERING:
			take_order()
			
		State.WAITING_FOR_FOOD:
			_deliver_held_food(_player)
		
		State.FINISHED:
			RestaurantManager.receive_payment(take_payment())
			
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
		State.LEAVING_ANGRY:
			state_leaving_angry(delta)

func move_toward_navigation_target(delta) -> void:
	var next_position := nav_agent.get_next_path_position()
	var direction := global_position.direction_to(next_position)
	var target_rotation = atan2(direction.x, direction.z) + PI / 2

	velocity = direction * move_speed
	rotation.y = lerp_angle(rotation.y, target_rotation, 10.0 * delta)
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
	patience_bar.set_state(new_state)
	enter_state(new_state)
	
func enter_state(state: State):
	match state:
		State.IDLE:
			animation_player.play("Idle")
			pass
		
		State.WALKING_TO_TABLE:
			play_audio(AudioSfx.ENTER)
			animation_player.play("Walk")
			update_target_location(assigned_sittingNode.global_position)
			pass

		State.SITTING:
			# Start sitting animation
			# Play reading menu animation for random seconds
			prev_transform = global_transform
			global_transform = assigned_sittingNode.get_seating_transform()
			animation_player.play("Sitting_Idle")
			var view_menu_time = randf_range(5.0, 10.0)
			wait_at_table(view_menu_time)
			pass

		State.ORDERING:
			# Tell waiter/customer system that we're ordering
			start_ordering()
			pass

		State.WAITING_FOR_FOOD:
			start_waiting_for_food()
			pass

		State.EATING:
			start_eating()
			pass

		State.FINISHED:
			pass

		State.LEAVING:
			global_transform = prev_transform
			animation_player.play("Walk")
			update_target_location(exit_point.global_position)
			pass
		State.LEAVING_ANGRY:
			global_transform = prev_transform
			animation_player.play("Walk")
			play_audio(AudioSfx.ANGRY)
			update_target_location(exit_point.global_position)
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

		State.LEAVING_ANGRY:
			pass

# States

func state_idle(delta):
	# Decide what the customer should do next
	RestaurantManager.add_customer(self)
	
	if assigned_sittingNode != null:
		change_state(State.WALKING_TO_TABLE)

func state_walking_to_table(delta):
	if nav_agent.is_navigation_finished():
		change_state(State.SITTING)
		return
	
	move_toward_navigation_target(delta)

var done_waiting_at_table: bool
func wait_at_table(view_menu_time: float) -> void:
	print("Customer is looking at menu for ", view_menu_time, " seconds")
	done_waiting_at_table = false
	play_audio(AudioSfx.THINKING)
	await get_tree().create_timer(view_menu_time).timeout
	done_waiting_at_table = true

enum AudioSfx {
	ENTER,
	ORDER_TAKEN,
	THINKING,
	ANGRY,
	ORDERING,
	COMPLETE,
	LEAVING
}

func play_audio(audio_type: AudioSfx):
	match audio_type:
		AudioSfx.THINKING:
			audio_player.volume_linear = 1.0
			audio_player.stream = HMM_SFX
		AudioSfx.ANGRY:
			audio_player.volume_linear = 1.6
			audio_player.stream = ANGRY_SFX
		AudioSfx.ORDERING:
			audio_player.volume_linear = 1.3
			audio_player.stream = ORDER_READY_SFX
		AudioSfx.COMPLETE:
			audio_player.volume_linear = 0.2
			audio_player.stream = ORDER_COMPLETE_SFX
		AudioSfx.ORDER_TAKEN:
			audio_player.volume_linear = 0.9
			audio_player.stream = ORDER_TAKEN_SFX
		AudioSfx.ENTER:
			audio_player.volume_linear = 2.0
			audio_player.stream = ENTER_SFX
		AudioSfx.LEAVING:
			audio_player.volume_linear = 0.4
			audio_player.stream = LEAVING_SFX
	audio_player.play()

func state_sitting(delta):
	# Wait until sitting animation finish
	# Execute sitting animation here
	if done_waiting_at_table:
		change_state(State.ORDERING)

func take_order() -> void:
	RestaurantManager.add_order(order)
	order_taken = true
	play_audio(AudioSfx.ORDER_TAKEN)

func start_ordering() -> void:
	patience = max_patience
	patience_bar.update_patience(max_patience)
	# Decide order
	if order == null:
		var menu: Dictionary = RestaurantManager.get_menu()
		var food_data = menu["foods"].pick_random()
		print(food_data["name"], food_data["price"], food_data["rarity"])
		var food = Food.new(food_data["name"], food_data["price"], food_data["rarity"], 1.0)
		var order_item = OrderItem.new(food, customer_lvl)
		order = Order.new([order_item])	
		order.order_completed.connect(_on_order_complete)
	play_audio(AudioSfx.ORDERING)

func state_ordering(delta):
	# Wait until player takes order
	patience -= delta
	patience_bar.update_patience(patience)
	if patience <= 0.0:
		patience = 0.0
		print(self, " leaving because out of patience")
		change_state(State.LEAVING_ANGRY)
		return
		
	if order_taken:
		change_state(State.WAITING_FOR_FOOD)

# Seconds that the customer will wait
@export var max_patience: float
var patience: float

func get_current_patience() -> float:
	return patience

func start_waiting_for_food() -> void:
	patience = max_patience
	patience_bar.update_patience(max_patience)

func state_waiting_for_food(delta):
	# Wait until restaurant tells us the food is ready
	patience -= delta
	patience_bar.update_patience(patience)
	if patience <= 0.0:
		patience = 0.0
		print(self, " leaving because out of patience")
		change_state(State.LEAVING_ANGRY)
		
		return

func start_eating(eating_time: float = 5.0) -> void:
	play_audio(AudioSfx.COMPLETE)
	await get_tree().create_timer(eating_time).timeout

	# Do nothing if the customer changed state while waiting.
	if current_state == State.EATING:
		change_state(State.FINISHED)
	
func _on_order_complete(completed_order: Order):
	# some guard checks
	if completed_order == order and current_state == State.WAITING_FOR_FOOD:
		change_state(State.EATING)

func receive_order_item(item: OrderItem) -> bool:
	if current_state != State.WAITING_FOR_FOOD:
		return false
	
	# if the order is finished, we let the signal tell us
	return order.receive_order_item(item)

func _deliver_held_food(player: Player) -> void:
	if not is_instance_valid(player.held_edible):
		print("You need to be holding a cooked dish to deliver it.")
		return

	var food_data: Food = player.held_edible.get_data()
	if food_data == null:
		print("Ingredients cannot be delivered. Cook them first.")
		return

	var delivered_item := OrderItem.new(food_data, 1)
	if not receive_order_item(delivered_item):
		print("That dish does not match the customer's order.")
		return

	var delivered_edible := player.held_edible
	player.held_edible = null
	delivered_edible.queue_free()
	print("Delivered %s." % food_data.edible_name)

func state_eating(delta):
	# Play eating animation
	pass

func take_payment() -> float:
	paid = true
	return order.get_order_total_price()

func state_finished(delta):
	# Pay, finish eating, etc.
	_on_interacted(null)
	# Go to counter/Leave money on table for collection
	
	if paid:
		change_state(State.LEAVING)


func state_leaving(delta):
	# Walk toward the restaurant exit	
	move_toward_navigation_target(delta)
	
	if nav_agent.is_navigation_finished():
		if assigned_sittingNode != null:
			assigned_sittingNode.clear()
		
		customer_spawner.release_name(customer_name)
		RestaurantManager.remove_customer(self)
		queue_free()
		return

func state_leaving_angry(delta):
	move_toward_navigation_target(delta)
	if nav_agent.is_navigation_finished():
		if assigned_sittingNode != null:
			assigned_sittingNode.clear()
		customer_spawner.release_name(customer_name)
		RestaurantManager.remove_angry_customer(self)
		queue_free()
		return
