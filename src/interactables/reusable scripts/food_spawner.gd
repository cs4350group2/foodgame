extends Node3D
class_name FoodSpawner

@export var food_scene: PackedScene
@export var spawner_name: String = "spawner"
@onready var interaction: InteractComponent = $"InteractComponent"

func _ready() -> void:
	interaction.supports_primary = true
	interaction.interacted.connect(_on_interacted)
	interaction.display_name = spawner_name
	interaction.tooltip_provider = _get_tooltip_actions

func _on_interacted(player: Player) -> void:
	if is_instance_valid(player.held_edible):
		return

	if food_scene == null:
		return

	var food := food_scene.instantiate() as EdibleItem
	get_tree().current_scene.add_child(food)
	player.pick_up_edible(food)
	print("Pulled %s from the %s." % [food.ingredient_name, spawner_name])

func _get_tooltip_actions(_player: Player) -> Dictionary:
	return {
		"primary": "Take ingredient" if food_scene != null else "",
	}
