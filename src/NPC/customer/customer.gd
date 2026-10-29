class_name Customer
extends CharacterBody3D

@onready var effect_anchor: Node3D = $EffectAnchor
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $CharacterBody3D/Timmy/AnimationPlayer
@onready var interaction: InteractComponent = $InteractComponent
@onready var patience_bar: PatienceBar = $PatienceBar
@onready var customer_spawner: CustomerSpawner = get_parent() as CustomerSpawner
@onready var audio_player = $AudioStreamPlayer3D
@onready var effect_audio_player = $EffectAudioStreamPlayer3D
@onready var restaurant_ui: RestaurantUI = get_tree().current_scene.get_node("RestaurantUi")

static var type_format_dict: Dictionary[StringName, String] = {
	&"": "Regular",
	&"FoodCritic": "Food Critic",
}

# Notifications
var notification_data: Dictionary

# SFX
const HMM_SFX = preload("res://assets/sfx/customer/hmm_new.mp3")
const ORDER_READY_SFX = preload("res://assets/sfx/customer/order_fulfilled_new.mp3")
const ORDER_COMPLETE_SFX = preload("res://assets/sfx/customer/satisfied_sfx.wav")
const ANGRY_SFX = preload("res://assets/sfx/customer/angry_new.mp3")
const ENTER_SFX = preload("res://assets/sfx/customer/enter_new.mp3")
const ORDER_TAKEN_SFX = preload("res://assets/sfx/customer/order_taken_new.mp3")
const LEAVING_SFX = preload("res://assets/sfx/customer/leaving_new.mp3")
const WARNING_SFX = preload("res://assets/sfx/customer/warning_new.mp3")
const HOBO_LAUGH_SFX = preload("res://assets/sfx/customer/hobo_laugh_new.mp3")
const PAYMENT_SFX = preload("res://assets/sfx/customer/chaching_new.mp3")
const SNORING_SFX = preload("res://assets/sfx/customer/snoring_sfx.mp3")
const GULP_SFX = preload("res://assets/sfx/customer/gulp_sfx.mp3")

# VFX
const POOF_SCENE: PackedScene = preload("res://assets/vfx/customer/Poof.tscn")
const PATIENCE_GAIN_SCENE: PackedScene = preload("res://addons/reeboo_vfx/status_effects/patience_gain.tscn")
const UNCONSCIOUS_SCENE: PackedScene = preload("res://addons/reeboo_vfx/status_effects/unconscious.tscn")
const MOOD_GAIN_SCENE: PackedScene = preload("res://addons/reeboo_vfx/status_effects/mood_gain.tscn")
const BLINDED_SCENE: PackedScene = preload("res://addons/reeboo_vfx/status_effects/blinded.tscn")
const TASTELESS_SCENE: PackedScene = preload("res://addons/reeboo_vfx/status_effects/tasteless.tscn")
const MEMORY_RESET_SCENE: PackedScene = preload("res://addons/reeboo_vfx/status_effects/memory_reset.tscn")

enum State {
	IDLE,
	WALKING_TO_TABLE,
	SITTING,
	ORDERING,
	WAITING_FOR_FOOD,
	EATING,
	WALKING_TO_CASHIER,
	PAYING,
	LEAVING,
	LEAVING_ANGRY
}

func get_state_name(state: State) -> String:
	return State.keys()[state]

func get_current_state() -> State:
	return current_state

var current_state = State.IDLE
var assigned_sittingNode: SittingNode = null
var order_taken: bool = false
var paid: bool = false
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

func reset_customer_memory() -> void:
	order_taken = false
	order = null
	paid = false
	done_waiting_at_table = false
	set_patience_timer_stop(false)
	change_state(State.IDLE)

func load_notification_data() -> void:
	var file = FileAccess.open("res://data/notification.json", FileAccess.READ)
	if file == null:
		push_error("Could not open notification.json")
		return
	notification_data = JSON.parse_string(file.get_as_text())

func _ready():
	interaction.supports_primary = true
	interaction.accepts_primary_while_holding = true
	interaction.interacted.connect(_on_interacted)
	audio_player.pitch_scale = RunManager.get_rng().randf_range(0.67, 1.3)
	effect_audio_player.pitch_scale = RunManager.get_rng().randf_range(0.67, 1.3)
	change_state(State.IDLE)
	patience_bar.set_patience(
		0.0,
		max_patience,
		max_patience / 100.0
	)
	load_notification_data()

func _process(delta: float) -> void:
	if StatusEffect.UNCONSCIOUS in current_status_effects:
		if unconscious_effect_remaining > 0.0:
			unconscious_effect_remaining -= delta
			if unconscious_effect_remaining <= 0.0:
				remove_status_effect(StatusEffect.UNCONSCIOUS)
	
	match current_state:
		pass

func _on_interacted(_player: Player) -> void:
	if is_instance_valid(_player) \
			and is_instance_valid(_player.held_edible):
		print(_player.held_edible)
		_deliver_held_edible(_player)
		return

	match current_state:
		State.ORDERING:
			take_order()

		State.WAITING_FOR_FOOD:
			# If reaches here, the player is 100% not holding an edible
			var error_message: String = notification_data["error"].get("delivering_empty_handed")
			restaurant_ui.show_notification_error_bottom(error_message)
			return

		State.PAYING:
			if not RestaurantManager.is_next_to_pay(self):
				return
			RestaurantManager.receive_payment(take_payment())
			RestaurantManager.customer_paid(self)
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
		State.PAYING:
			state_paying(delta)
		State.WALKING_TO_CASHIER:
			state_walking_to_cashier(delta)
		State.LEAVING:
			state_leaving(delta)
		State.LEAVING_ANGRY:
			state_leaving_angry(delta)

func move_toward_navigation_target(delta) -> void:
	var next_position := nav_agent.get_next_path_position()
	var direction := global_position.direction_to(next_position)
	var target_rotation = atan2(direction.x, direction.z) + PI / 2

	velocity = velocity.move_toward(direction * move_speed, .25)
	rotation.y = lerp_angle(rotation.y, target_rotation, 10.0 * delta)
	move_and_slide()

func update_target_location(target_location):
	nav_agent.target_position = target_location

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

# <------------- State Management --------------------------------------------->

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

		State.WALKING_TO_CASHIER:
			play_animation("Walk")
			RestaurantManager.enqueue_for_payment(self)
			pass

		State.PAYING:
			play_animation("Idle")
			pass

		State.LEAVING:
			play_animation("Walk")
			update_target_location(exit_point.global_position)
			pass

		State.LEAVING_ANGRY:
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
			global_transform = prev_transform
			pass

		State.WALKING_TO_CASHIER:
			pass

		State.PAYING:
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
	HOBO_LAUGH,
	SNORING,
	GULP,
}

func stop_audio() -> void:
	audio_player.stop()

func play_audio(audio_type: AudioSfx):
	match audio_type:
		AudioSfx.THINKING:
			audio_player.volume_linear = 1.0
			audio_player.stream = HMM_SFX
		AudioSfx.ANGRY:
			audio_player.volume_linear = 1.0
			audio_player.stream = ANGRY_SFX
		AudioSfx.ORDERING:
			audio_player.volume_linear = 1.0
			audio_player.stream = ORDER_READY_SFX
		AudioSfx.COMPLETE:
			audio_player.volume_linear = 1.0
			audio_player.stream = ORDER_COMPLETE_SFX
		AudioSfx.PAYMENT:
			audio_player.volume_linear = 1.0
			audio_player.stream = PAYMENT_SFX
		AudioSfx.ORDER_TAKEN:
			audio_player.volume_linear = 1.0
			audio_player.stream = ORDER_TAKEN_SFX
		AudioSfx.ENTER:
			audio_player.volume_linear = 1.0
			audio_player.stream = ENTER_SFX
		AudioSfx.LEAVING:
			audio_player.volume_linear = 1.0
			audio_player.stream = LEAVING_SFX
		AudioSfx.WARNING:
			audio_player.volume_linear = 1.0
			audio_player.stream = WARNING_SFX
		AudioSfx.HOBO_LAUGH:
			audio_player.volume_linear = 1.0
			audio_player.stream = HOBO_LAUGH_SFX
		AudioSfx.GULP:
			audio_player.volume_linear = 1.5
			audio_player.stream = GULP_SFX
	audio_player.play()

func play_effect_audio(audio_type: AudioSfx):
	match audio_type:
		AudioSfx.SNORING:
			effect_audio_player.volume_linear = 3.0
			effect_audio_player.stream = SNORING_SFX
	effect_audio_player.play()

func stop_effect_audio():
	effect_audio_player.stop()

func state_sitting(delta):
	# Wait until sitting animation finish
	# Execute sitting animation here
	if done_waiting_at_table:
		change_state(State.ORDERING)

func take_order() -> void:
	order.customer_name = customer_name
	order.customer_type = customer_type
	RestaurantManager.add_order(order)
	order_taken = true
	play_audio(AudioSfx.ORDER_TAKEN)
	
	var message: String = notification_data["action_notification"].get("take_order") % get_customer_name()
	restaurant_ui.show_side(message)

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
	if not patience_timer_stopped:
		patience -= delta
		patience_bar.update_patience(patience)
	
	if patience <= 0.0:
		patience = 0.0
		print(self, " leaving because out of patience")
		var message: String = notification_data["customer_action_notification"].get("leaving_out_of_patience") % get_customer_name()
		restaurant_ui.show_side(message)
		change_state(State.LEAVING_ANGRY)
		return
		
	if order_taken:
		change_state(State.WAITING_FOR_FOOD)

func show_warning_notification() -> void:
	var message: String = notification_data["customer_action_notification"]\
		.get("low_patience_warning") % get_customer_name()
	restaurant_ui.show_side(message)

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
	if not patience_timer_stopped:
		patience -= delta
		patience_bar.update_patience(patience)
	
	if patience <= 0.0:
		patience = 0.0
		print(self, " leaving because out of patience")
		var message: String = notification_data["customer_action_notification"].get("leaving_out_of_patience") % get_customer_name()
		restaurant_ui.show_side(message)
		change_state(State.LEAVING_ANGRY)
		
		return

func start_eating(eating_time: float = 10.0) -> void:
	play_audio(AudioSfx.COMPLETE)
	await get_tree().create_timer(eating_time).timeout

	# Do nothing if the customer changed state while waiting.
	if current_state == State.EATING:
		change_state(State.WALKING_TO_CASHIER)
	
func _on_order_complete(completed_order: Order):
	# some guard checks
	if completed_order == order and current_state == State.WAITING_FOR_FOOD:
		change_state(State.EATING)

func receive_order_item(item: OrderItem) -> bool:
	if current_state != State.WAITING_FOR_FOOD:
		return false
	
	if StatusEffect.TASTELESS in current_status_effects and StatusEffect.BLIND in current_status_effects:
		return anyhow_receive_order_item()
	
	if StatusEffect.TASTELESS in current_status_effects:
		return tasteless_receive_order_item(item)
	
	if StatusEffect.BLIND in current_status_effects:
		return blind_receive_order_item(item)
	
	# if the order is finished, we let the signal tell us
	return order.receive_order_item(item)

func anyhow_receive_order_item() -> bool: # Accepts any food and auto 100% dish quality
	var order_items = order.get_order_items()
	
	for item in order_items:
		var received_item = order.find_received_item_in_order(item)
		if received_item:
			if received_item.get_quantity() < item.get_quantity():
				# Order havent receive sufficient qty of this item
				var food: Food = item.get_edible()
				food.set_dish_quality(100.0)
				var food_item = OrderItem.new(food, 1)
				order.receive_order_item(food_item)
				break
			else: # Order already received sufficient qty of this item
				continue
		else: # Order havent receive this item yet
			var food: Food = item.get_edible()
			food.set_dish_quality(100.0)
			var food_item = OrderItem.new(food, 1)
			order.receive_order_item(food_item)
			break
			
	return true

func tasteless_receive_order_item(item: OrderItem) -> bool: # Auto 100% quality
	var food: Food = item.get_edible()
	food.set_dish_quality(100.0)
	return order.receive_order_item(item)

func blind_receive_order_item(item: OrderItem) -> bool: # Accepts any food
	var order_items = order.get_order_items()
	var dish_quality = item.get_edible().get_dish_quality()
	
	for order_item in order_items:
		var received_item = order.find_received_item_in_order(order_item)
		if received_item:
			if received_item.get_quantity() < order_item.get_quantity():
				# Order havent receive sufficient qty of this item
				var food: Food = order_item.get_edible()
				food.set_dish_quality(dish_quality)
				var food_item = OrderItem.new(food, 1)
				order.receive_order_item(food_item)
				break
			else: # Order already received sufficient qty of this item
				continue
		else: # Order havent receive this item yet
			var food: Food = order_item.get_edible()
			food.set_dish_quality(dish_quality)
			var food_item = OrderItem.new(food, 1)
			order.receive_order_item(food_item)
			break
			
	return true

func _deliver_held_edible(player: Player) -> void:
	var held_edible: EdibleItem = player.held_edible
	if not is_instance_valid(held_edible):
		var error_message: String = notification_data["error"].get("delivering_empty_handed")
		restaurant_ui.show_notification_error_bottom(error_message)
		return
	
	if held_edible.is_ingredient():
		var error_message: String = notification_data["error"].get("uncooked_ingredient_error")
		restaurant_ui.show_notification_error_bottom(error_message)
		return
	
	var data: Edible = held_edible.get_data()
	if held_edible.is_drink:
		if held_edible.affect_customer(self):
			var delivered_edible := player._release_held_edible()
			play_audio(AudioSfx.GULP)
			delivered_edible.interaction.set_highlighted(false)
			delivered_edible.interaction.enabled = false
			delivered_edible.collision_layer = 0
			delivered_edible.collision_mask = 0
			delivered_edible.queue_free()
			
			var action_message: String = (
				notification_data["action_notification"].get("deliver_item") 
				% [
					data.get_edible_name(),
					get_customer_name()
				]
			)
			restaurant_ui.show_side(action_message)
			print("Delivered %s." % data.get_edible_name())
	else: # is Food
		if current_state != State.WAITING_FOR_FOOD:
			var error_message = notification_data["error"].get("dish_deliver_before_order_taken")
			restaurant_ui.show_notification_error_bottom(error_message)
			return
		
		var food_data := data as Food
		if food_data == null:
			return

		var original_quality := food_data.get_dish_quality()
		food_data.set_dish_quality(original_quality + get_mood_bonus())

		var delivered_item := OrderItem.new(food_data, 1)

		if not receive_order_item(delivered_item):
			var error_message: String = notification_data["error"].get("order_dish_requirement_not_fulfilled")
			restaurant_ui.show_notification_error_bottom(error_message)
			food_data.set_dish_quality(original_quality)
			return

		var delivered_edible := player._release_held_edible()
		delivered_edible.interaction.set_highlighted(false)
		delivered_edible.interaction.enabled = false
		delivered_edible.collision_layer = 0
		delivered_edible.collision_mask = 0
		delivered_edible.queue_free()
		
		var action_message: String = (
				notification_data["action_notification"].get("deliver_item") 
				% [
					food_data.get_edible_name(),
					get_customer_name()
				]
			)
		restaurant_ui.show_side(action_message)
		print("Delivered %s." % food_data.get_edible_name())

func state_eating(delta):
	# Play eating animation
	pass

func state_walking_to_cashier(delta):
	if nav_agent.is_navigation_finished():
		if RestaurantManager.is_next_to_pay(self):
			change_state(State.PAYING)
		else:
			# Queuing
			play_animation("Idle")
	move_toward_navigation_target(delta)

func set_cashier_queue_target(target: Vector3, is_front: bool) -> void:
	if current_state != State.WALKING_TO_CASHIER:
		return
	update_target_location(target)
	play_animation("Walk")

func take_payment() -> float:
	if not paid:
		paid = true
		return order.get_order_total_price() + order.get_total_bonus()
	else:
		return 0.0

func state_paying(delta):
	# Pay, finish eating, etc.
	# if we don't want to interact to take payment:
	#RestaurantManager.receive_payment(take_payment())
	# Go to counter/Leave money on table for collection
	
	if paid:
		change_state(State.LEAVING)


func state_leaving(delta):
	RestaurantManager.remove_from_cashier_queue(self)
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
	RestaurantManager.remove_from_cashier_queue(self)
	move_toward_navigation_target(delta)
	if nav_agent.is_navigation_finished():
		if assigned_sittingNode != null:
			assigned_sittingNode.clear()
		customer_spawner.release_name(customer_name)
		RestaurantManager.remove_angry_customer(self)
		queue_free()
		return

# <-------------------------------VFX------------------------------------------>
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

func show_patience_gain() -> void:
	var effect := PATIENCE_GAIN_SCENE.instantiate()
	get_tree().current_scene.add_child(effect)
	effect.global_position = effect_anchor.global_position

func show_mood_gain() -> void:
	var effect := MOOD_GAIN_SCENE.instantiate()
	get_tree().current_scene.add_child(effect)
	effect.global_position = effect_anchor.global_position

func show_blinded_vfx() -> void:
	var effect := BLINDED_SCENE.instantiate()
	get_tree().current_scene.add_child(effect)
	effect.global_position = effect_anchor.global_position

func show_tasteless_vfx() -> void:
	var effect := TASTELESS_SCENE.instantiate()
	get_tree().current_scene.add_child(effect)
	effect.global_position = effect_anchor.global_position

func show_unconscious_effect() -> void:
	if is_instance_valid(unconscious_effect):
		return
	
	unconscious_effect = UNCONSCIOUS_SCENE.instantiate() as Node3D
	get_tree().current_scene.add_child(unconscious_effect)
	unconscious_effect.global_position = effect_anchor.global_position

func show_memory_reset_vfx() -> void:
	var effect := MEMORY_RESET_SCENE.instantiate()
	get_tree().current_scene.add_child(effect)
	effect.global_position = effect_anchor.global_position

func is_equal(other: Customer) -> bool:
	return (
		customer_name == other.get_customer_name()
		and customer_lvl == other.get_customer_lvl()
		and customer_type == other.get_customer_type()
	)

# <-------------------------------Status Effect-------------------------------->
enum StatusEffect {
	NORMAL,
	UNCONSCIOUS,
	TASTELESS,
	BLIND,
}

var current_status_effects: Array[StatusEffect] = []
var patience_timer_stopped: bool = false
var unconscious_effect_remaining: float = 0.0
var unconscious_effect: Node3D

func enter_status_effect(status_effect: StatusEffect) -> void:
	match status_effect:
		StatusEffect.NORMAL:
			pass
		StatusEffect.UNCONSCIOUS:
			show_unconscious_effect()
			pass
		StatusEffect.TASTELESS:
			show_tasteless_vfx()
			pass
		StatusEffect.BLIND:
			show_blinded_vfx()
			pass
		_:
			pass

func exit_status_effect(status_effect: StatusEffect) -> void:
	match status_effect:
		StatusEffect.NORMAL:
			pass
		StatusEffect.UNCONSCIOUS:
			stop_unconscious_effect()
			pass
		StatusEffect.TASTELESS:
			pass
		StatusEffect.BLIND:
			pass
		_:
			pass

func add_status_effect(status_effect: StatusEffect) -> void:
	if status_effect == StatusEffect.NORMAL or status_effect in current_status_effects:
		return
	current_status_effects.append(status_effect)
	enter_status_effect(status_effect)

func remove_status_effect(status_effect: StatusEffect) -> void:
	if not status_effect in current_status_effects:
		return
	current_status_effects.erase(status_effect)
	exit_status_effect(status_effect)

func set_patience_timer_stop(value: bool) -> void:
	patience_timer_stopped = value

func apply_unconscious_effect(duration: float) -> void:
	add_status_effect(StatusEffect.UNCONSCIOUS)
	set_patience_timer_stop(true)
	unconscious_effect_remaining = maxf(unconscious_effect_remaining, maxf(duration, 0.0))
	play_effect_audio(AudioSfx.SNORING)

func stop_unconscious_effect() -> void:
	set_patience_timer_stop(false)
	if effect_audio_player.stream == SNORING_SFX:
		stop_effect_audio()
	unconscious_effect_remaining = 0.0
	if is_instance_valid(unconscious_effect):
		unconscious_effect.queue_free()
		unconscious_effect = null

static func convert_to_formatted_type(cust_type: StringName) -> String:
	if type_format_dict.has(cust_type):
		return type_format_dict[cust_type]
	
	return cust_type

# sorry for the bad name but I can't think of a good name
func get_formatted_type() -> String:
	return convert_to_formatted_type(self.customer_type)
