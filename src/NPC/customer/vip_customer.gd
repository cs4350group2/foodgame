class_name VIP_Customer
extends Customer

@onready var vip_animation_player: AnimationPlayer = $CharacterBody3D/Sketchfab_Scene/AnimationPlayer
var dish_quality_requirement: float = 0.0

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
	match anim:
		"Idle":
			vip_animation_player.play("Rig|idle")
		
		"Walk":
			vip_animation_player.play("Rig|walk")
		
		"Sitting_Idle":
			vip_animation_player.play("Rig|sitting_idle")
		_:
			pass
