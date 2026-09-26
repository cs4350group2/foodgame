extends Node3D

const FOOD_SCENE = preload("res://models/physics/food/ingredients/buns.tscn")
@onready var interaction: InteractComponent = $"InteractComponent"

func _ready() -> void:
	interaction.interacted.connect(_on_interacted)

func _on_interacted(player: Player) -> void:
	if is_instance_valid(player.held_food):
		return

	var food := FOOD_SCENE.instantiate() as FoodItem
	get_tree().current_scene.add_child(food)
	player.pick_up_food(food)
	print("Pulled burger buns from the box.")
