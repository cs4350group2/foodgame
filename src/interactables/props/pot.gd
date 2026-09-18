extends StaticBody3D
@onready var interaction: InteractComponent = $InteractComponent

const INGREDIENT_SCENES = {
	"res://models/physics/food/steak/meatRaw.tscn":
		preload("res://models/physics/food/steak/meatRaw.tscn"),
	"res://models/physics/food/burger/buns.tscn":
		preload("res://models/physics/food/burger/buns.tscn"),
}
var ingredient_buffer: Array[String] = []

func _ready() -> void:
	interaction.interact_while_holding = true
	interaction.interacted.connect(_on_interacted)

func _on_interacted(player: Player) -> void:
	if is_instance_valid(player.held_food):
		_store_ingredient(player)
	else:
		_take_ingredient(player)


func _store_ingredient(player: Player) -> void:
	var food := player.held_food
	var ingredient_path := food.scene_file_path

	if not INGREDIENT_SCENES.has(ingredient_path):
		print("Only raw meat and burger buns can go in the pot.")
		return

	if ingredient_buffer.has(ingredient_path):
		print("The pot already contains ", food.food_name, ".")
		return

	ingredient_buffer.append(ingredient_path)

	player.held_food = null
	print("Put ", food.food_name, " in the pot.")
	food.queue_free()


func _take_ingredient(player: Player) -> void:
	if ingredient_buffer.is_empty():
		print("The pot is empty.")
		return

	var ingredient_path: String = ingredient_buffer.back()
	var food_scene: PackedScene = INGREDIENT_SCENES[ingredient_path]
	var food := food_scene.instantiate() as FoodItem

	get_tree().current_scene.add_child(food)
	player.pick_up_food(food)

	if player.held_food == food:
		ingredient_buffer.pop_back()
		print("Took ", food.food_name, " from the pot.")
	else:
		food.queue_free()
