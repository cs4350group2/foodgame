class_name Customer
extends CharacterBody3D

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $CharacterBody3D/Timmy/AnimationPlayer
@onready var interaction: InteractComponent = $InteractComponent
@onready var patience_bar: PatienceBar = $PatienceBar
@onready var customer_spawner: CustomerSpawner = get_parent() as CustomerSpawner
@onready var audio_player = $AudioStreamPlayer3D

# SFX
const HMM_SFX = preload("res://assets/sfx/customer/hmm_sfx.mp3")
const ORDER_READY_SFX = preload("res://assets/sfx/customer/order_sfx.wav")
const ORDER_COMPLETE_SFX = preload("res://assets/sfx/customer/satisfied_sfx.wav")
const ANGRY_SFX = preload("res://assets/sfx/customer/angry_sfx.wav")
const ENTER_SFX = preload("res://assets/sfx/customer/enter_sfx.wav")
const ORDER_TAKEN_SFX = preload("res://assets/sfx/customer/order_taken.ogg")
const LEAVING_SFX = preload("res://assets/sfx/customer/leaving_sfx.wav")
const WARNING_SFX = preload("res://assets/sfx/customer/warning_sfx.mp3")
const HOBO_LAUGH_SFX = preload("res://assets/sfx/customer/Hobo_Laugh.mp3")
const PAYMENT_SFX = preload("res://assets/sfx/customer/money_chaching_sfx.mp3")

# VFX
const POOF_SCENE: PackedScene = preload("res://assets/vfx/customer/Poof.tscn")

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

func get_current_state() -> State:
	return current_state

var current_state = State.IDLE
var assigned_sittingNode: SittingNode = null
var order_taken = false
var paid = false
var order: Order
var move_speed: float = 2.0
var mood_bonus: float = 0.0
var customer_lvl: int
var customer_name: String
var customer_type: StringName
var exit_point: Marker3D
var prev_transform: Transform3D

func get_customer_name() -> String:
	return customer_name

func get_customer_lvl() -> int:
	return customer_lvl

func get_customer_type() -> StringName:
	return customer_type

func get_mood_bonus() -> float:
	return mood_bonus

func add_mood_bonus(bonus: float) -> void:
	mood_bonus = minf(mood_bonus + bonus, 100) # can't exceed 100

func assign_sitting_node(node: SittingNode):
	self.assigned_sittingNode = node

func initialize_customer(name: String, level: int, patience: float, type: StringName = &"") -> void:
	customer_name = name
	customer_lvl = level
	max_patience = patience
	customer_type = type

func _ready():
	interaction.supports_primary = true
	interaction.accepts_primary_while_holding = true
	interaction.interacted.connect(_on_interacted)
	audio_player.pitch_scale = RunManager.get_rng().randf_range(0.67, 1.3)
	change_state(State.IDLE)
	patience_bar.set_patience(
		0.0,
		max_patience,
		max_patience / 100.0
	)

func _on_interacted(_player: Player) -> void:
	if is_instance_valid(_player) \
			and is_instance_valid(_player.held_edible):
		_deliver_held_edible(_player)
		return

	match current_state:
		State.ORDERING:
			take_order()

		State.WAITING_FOR_FOOD:
			# If reaches here, the player is 100% not holding an edible
			print("You need to be holding a cooked dish/consumable to deliver it.")
			return

		State.FINISHED:
			RestaurantManager.receive_payment(take_payment())
			play_audio(AudioSfx.PAYMENT)

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

func play_animation(anim: String) -> void:
	match anim:
		"Idle":
			animation_player.play("Idle")
		
		"Walk":
			animation_player.play("Walk")
		
		"Sitting_Idle":
			animation_player.play("Sitting_Idle")
		_:
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
			play_animation("Idle")
			pass
		
		State.WALKING_TO_TABLE:
			play_audio(AudioSfx.ENTER)
			play_animation("Walk")
			update_target_location(assigned_sittingNode.global_position)
			pass

		State.SITTING:
			# Start sitting animation
			# Play reading menu animation for random seconds
			prev_transform = global_transform
			global_transform = assigned_sittingNode.get_seating_transform()
			play_animation("Sitting_Idle")
			var view_menu_time = RunManager.get_rng().randf_range(5.0, 10.0)
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
			play_animation("Walk")
			update_target_location(exit_point.global_position)
			pass
		State.LEAVING_ANGRY:
			global_transform = prev_transform
			play_animation("Walk")
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
	PAYMENT,
	LEAVING,
	WARNING,
	HOBO_LAUGH
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
		AudioSfx.PAYMENT:
			audio_player.volume_linear = 1.0
			audio_player.stream = PAYMENT_SFX
		AudioSfx.ORDER_TAKEN:
			audio_player.volume_linear = 0.9
			audio_player.stream = ORDER_TAKEN_SFX
		AudioSfx.ENTER:
			audio_player.volume_linear = 2.0
			audio_player.stream = ENTER_SFX
		AudioSfx.LEAVING:
			audio_player.volume_linear = 0.4
			audio_player.stream = LEAVING_SFX
		AudioSfx.WARNING:
			audio_player.volume_linear = 2.0
			audio_player.stream = WARNING_SFX
		AudioSfx.HOBO_LAUGH:
			audio_player.volume_linear = 1.5
			audio_player.stream = HOBO_LAUGH_SFX
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
		var foods: Array = menu["foods"]
		var food_data = foods[RunManager.get_rng().randi_range(0, foods.size() - 1)]
		print(food_data["name"], food_data["price"], food_data["rarity"])
		var food = Food.new(food_data["name"], food_data["price"], food_data["rarity"])
		var order_item = OrderItem.new(food, customer_lvl)
		order = Order.new([order_item])	
		order.order_completed.connect(_on_order_complete)
	play_audio(AudioSfx.ORDERING)

func get_order() -> Order:
	return order

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

func get_max_patience() -> float:
	return max_patience

func set_patience(new_patience: float) -> void:
	patience = min(max_patience, new_patience)

func set_max_patience(new_max_patience) -> void:
	max_patience = new_max_patience

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

func start_eating(eating_time: float = 10.0) -> void:
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

func _deliver_held_edible(player: Player) -> void:
	var held_edible: EdibleItem = player.held_edible
	if not is_instance_valid(held_edible):
		print("You need to be holding a cooked dish/consumable to deliver it.")
		return
	
	if held_edible.is_ingredient():
		print("Ingredients cannot be delivered. Cook them first.")
		return
	
	var data: Edible = held_edible.get_data()
	if held_edible.is_drink:
		if held_edible.affect_customer(self):
			var delivered_edible := player._release_held_edible()
			delivered_edible.queue_free()
			print("Delivered %s." % data.get_edible_name())
	else: # is Food
		var food_data := data as Food
		if food_data == null:
			return

		var original_quality := food_data.get_dish_quality()
		food_data.set_dish_quality(original_quality + get_mood_bonus())

		var delivered_item := OrderItem.new(food_data, 1)

		if not receive_order_item(delivered_item):
			print("That dish does not match the customer's order/requirement.")
			food_data.set_dish_quality(original_quality)
			return

		var delivered_edible := player._release_held_edible()
		delivered_edible.queue_free()

		print("Delivered %s." % food_data.get_edible_name())

func state_eating(delta):
	# Play eating animation
	pass

func take_payment() -> float:
	paid = true
	return order.get_order_total_price() + order.get_total_bonus()

func state_finished(delta):
	# Pay, finish eating, etc.
	# if we don't want to interact to take payment:
	#RestaurantManager.receive_payment(take_payment())
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

func disappear_with_poof() -> void: # When customer drink EXTREMELY SAFE Drink
	var poof := POOF_SCENE.instantiate()
	
	if assigned_sittingNode != null:
		assigned_sittingNode.clear()
	customer_spawner.release_name(customer_name)
	if RestaurantManager.orders.has(self.order):
		RestaurantManager.remove_order(self.order)
	RestaurantManager.remove_customer(self)
	get_tree().current_scene.add_child(poof)
	poof.global_position = global_position
	queue_free()

func is_equal(other: Customer) -> bool:
	return (
		customer_name == other.get_customer_name()
		and customer_lvl == other.get_customer_lvl()
		and customer_type == other.get_customer_type()
	)
