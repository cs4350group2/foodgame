extends Node3D
class_name FoodSpawner

@export var food_scene: PackedScene
@export var spawner_name: String = "spawner"
@onready var interaction: InteractComponent = $"InteractComponent"

func _ready() -> void:
	interaction.interacted.connect(_on_interacted)

func _on_interacted(player: Player) -> void:
	if is_instance_valid(player.held_edible):
		return

	if food_scene == null:
		return

	var food := food_scene.instantiate() as EdibleItem
	get_tree().current_scene.add_child(food)
	player.pick_up_edible(food)
	print("Pulled %s from the %s." % [food.ingredient_name, spawner_name])
