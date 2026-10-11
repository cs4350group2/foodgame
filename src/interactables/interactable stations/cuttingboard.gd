extends StaticBody3D
@onready var interaction: InteractComponent = $InteractComponent

const INGREDIENT_SCENES = {
	"res://models/physics/food/ingredients/meatRaw.tscn":
		preload("res://models/physics/food/ingredients/pattyRaw.tscn"),
	"res://models/physics/food/ingredients/tomatoWhole.tscn":
		preload("res://models/physics/food/ingredients/tomatoSliced.tscn"),
	"res://models/physics/food/ingredients/potato.tscn":
		preload("res://models/physics/food/ingredients/potatoSliced.tscn")
}

func _ready() -> void:
	interaction.interact_while_holding = true
	interaction.interacted.connect(_on_interacted)

func _on_interacted(player: Player) -> void:
	print("Cutting board interaction received")
	if not is_instance_valid(player.held_edible):
		return

	var original := player.held_edible
	var ingredient_path := original.scene_file_path

	# Buns, processed ingredients, and dishes remain unchanged.
	if not INGREDIENT_SCENES.has(ingredient_path):
		var ingredient_name := original.get_edible_item_name()
		if original.food_data != null:
			ingredient_name = original.food_data.edible_name

		print("Cannot chop ", ingredient_name, ".")
		return

	var output_scene: PackedScene = INGREDIENT_SCENES[ingredient_path]
	var instance := output_scene.instantiate()
	var chopped := instance as EdibleItem

	if chopped == null:
		push_error("The chopped ingredient needs the EdibleItem script.")
		instance.queue_free()
		return

	# Adding it initializes its @onready interaction reference.
	get_tree().current_scene.add_child(chopped)

	if not is_instance_valid(chopped.interaction):
		push_error("The chopped ingredient needs an InteractComponent.")
		chopped.queue_free()
		return

	# Pickup requires an empty hand.
	player.held_edible = null
	player.pick_up_edible(chopped)

	if player.held_edible == chopped:
		print("Chopped ", original.get_edible_item_name(), " into ", chopped.get_edible_item_name(), ".")
		original.queue_free()
	else:
		player.held_edible = original
		chopped.queue_free()
