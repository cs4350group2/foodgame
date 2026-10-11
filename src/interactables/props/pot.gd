extends StaticBody3D
@onready var interaction: InteractComponent = $InteractComponent

const INGREDIENT_SCENES = {
	"res://models/physics/food/ingredients/meatRaw.tscn":
		preload("res://models/physics/food/ingredients/meatRaw.tscn"),
	"res://models/physics/food/ingredients/pattyRaw.tscn":
		preload("res://models/physics/food/ingredients/pattyRaw.tscn"),
	"res://models/physics/food/ingredients/buns.tscn":
		preload("res://models/physics/food/ingredients/buns.tscn"),
	"res://models/physics/food/ingredients/potato.tscn":
		preload("res://models/physics/food/ingredients/potato.tscn"),
	"res://models/physics/food/ingredients/potatoSliced.tscn":
		preload("res://models/physics/food/ingredients/potatoSliced.tscn"),
	"res://models/physics/food/ingredients/tomatoWhole.tscn":
		preload("res://models/physics/food/ingredients/tomatoWhole.tscn"),
	"res://models/physics/food/ingredients/tomatoSliced.tscn":
		preload("res://models/physics/food/ingredients/tomatoSliced.tscn")
}
var ingredient_buffer: Array[String] = []

func _ready() -> void:
	interaction.supports_primary = true
	interaction.accepts_primary_while_holding = true
	interaction.interacted.connect(_on_interacted)

func _on_interacted(player: Player) -> void:
	if is_instance_valid(player.held_edible):
		_store_ingredient(player)
	else:
		_take_ingredient(player)


func _store_ingredient(player: Player) -> void:
	var ingredient := player.held_edible
	var ingredient_path := ingredient.scene_file_path

	if not INGREDIENT_SCENES.has(ingredient_path):
		print("Only raw meat, burger buns, tomatoes and potatoes can go in the pot.")
		return

	if ingredient_buffer.has(ingredient_path):
		print(
			"The pot already contains ",
			ingredient.get_edible_item_name(),
			"."
		)
		return

	var item_name := ingredient.get_edible_item_name()

	player.release_held_edible()
	ingredient_buffer.append(ingredient_path)
	ingredient.queue_free()

	print("Put ", item_name, " in the pot.")


func _take_ingredient(player: Player) -> void:
	if ingredient_buffer.is_empty():
		print("The pot is empty.")
		return

	var ingredient_path: String = ingredient_buffer.back()
	var ingredient_scene: PackedScene = INGREDIENT_SCENES[ingredient_path]
	var ingredient := ingredient_scene.instantiate() as EdibleItem

	get_tree().current_scene.add_child(ingredient)
	player.pick_up_edible(ingredient)

	if player.held_edible == ingredient:
		ingredient_buffer.pop_back()
		print("Took ", ingredient.get_edible_item_name(), " from the pot.")
	else:
		ingredient.queue_free()
