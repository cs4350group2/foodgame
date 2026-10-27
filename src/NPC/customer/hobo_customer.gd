class_name Hobo_Customer
extends Customer

@onready var hobo_animation_player: AnimationPlayer = $CharacterBody3D/ModelOffset/Hobo/AnimationPlayer
@onready var model_offset: Node3D = $CharacterBody3D/ModelOffset

var default_position: Vector3

func _ready() -> void:
	super._ready()
	default_position = model_offset.position
	show_spawn_notification()

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

		State.LEAVING: # Only can receive payment if confronted when they are leaving
			if not paid:
				RestaurantManager.receive_payment(take_payment())
				play_audio(AudioSfx.PAYMENT)

	print("Interacted with the customer.")

func start_eating(eating_time: float = 10.0) -> void:
	play_audio(AudioSfx.COMPLETE)
	await get_tree().create_timer(eating_time).timeout

	# Do nothing if the customer changed state while waiting.
	if current_state == State.EATING:
		play_audio(AudioSfx.HOBO_LAUGH)
		change_state(State.LEAVING)

func play_animation(anim: String) -> void:
	reset_offset()
	match anim:
		"Idle":
			hobo_animation_player.play("Idle")
		
		"Walk":
			hobo_animation_player.play("Walk")
		
		"Sitting_Idle":
			model_offset.position.y += 0.1
			hobo_animation_player.play("Sitting_Idle")
		_:
			pass

func reset_offset() -> void:
	model_offset.position = default_position

func show_spawn_notification() -> void:
	var message: String = notification_data["special_customer_notification"].get(customer_type)
	var description_message: String = notification_data["special_customer_descriptions"].get(customer_type)
	restaurant_ui.show_notification_top(message, true, description_message)
