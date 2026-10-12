class_name VIP_Customer
extends Customer

@onready var vip_animation_player: AnimationPlayer = $CharacterBody3D/ModelOffset/Sketchfab_Scene/AnimationPlayer
@onready var model_offset: Node3D = $CharacterBody3D/ModelOffset

var default_position: Vector3
var dish_quality_requirement: float = 0.0

func _ready() -> void:
	super._ready()
	default_position = model_offset.position

func initialize_vip_customer(name: String, level: int, patience: float, 
							 type: StringName, requirement: float = 50.0) -> void:
	initialize_customer(name, level, patience, type)
	dish_quality_requirement = requirement

func get_dish_quality_requirement() -> float:
	return dish_quality_requirement

func receive_order_item(item: OrderItem) -> bool:
	if current_state != State.WAITING_FOR_FOOD:
		return false
	
	# if the order is finished, we let the signal tell us
	var food: Food = item.get_edible()
	var dish_quality: float = food.get_dish_quality()
	if dish_quality >= dish_quality_requirement:
		return order.receive_order_item(item)
	else:
		return false

func play_animation(anim: String) -> void:
	reset_offset()
	match anim:
		"Idle":
			vip_animation_player.play("Rig|idle")
		
		"Walk":
			vip_animation_player.play("Rig|walk")
		
		"Sitting_Idle":
			model_offset.position.x -= 0.2
			model_offset.position.y -= 0.6
			vip_animation_player.play("Rig|sitting_idle")
		_:
			pass

func reset_offset() -> void:
	model_offset.position = default_position

func take_payment() -> float:
	paid = true
	# Gives 2x bonus
	return order.get_order_total_price() + order.get_total_bonus() * 2
