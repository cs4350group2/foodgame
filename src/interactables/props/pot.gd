extends StaticBody3D
@onready var interaction: InteractComponent = $InteractComponent

const INGREDIENT_SCENES = {
	"res://models/physics/food/ingredients/meatRaw.tscn":
		preload("res://models/physics/food/ingredients/meatRaw.tscn"),
	"res://models/physics/food/ingredients/pattyRaw.tscn":
		preload("res://models/physics/food/ingredients/pattyRaw.tscn"),
	"res://models/physics/food/ingredients/buns.tscn":
		preload("res://models/physics/food/ingredients/buns.tscn"),
	"res://models/physics/food/ingredients/fishRaw.tscn":
		preload("res://models/physics/food/ingredients/fishRaw.tscn"),
	"res://models/physics/food/ingredients/potato.tscn":
		preload("res://models/physics/food/ingredients/potato.tscn"),
	"res://models/physics/food/ingredients/potatoSliced.tscn":
		preload("res://models/physics/food/ingredients/potatoSliced.tscn"),
	"res://models/physics/food/ingredients/tomatoWhole.tscn":
		preload("res://models/physics/food/ingredients/tomatoWhole.tscn"),
	"res://models/physics/food/ingredients/tomatoSliced.tscn":
		preload("res://models/physics/food/ingredients/fishSliced.tscn"),
	"res://models/physics/food/ingredients/fishSliced.tscn":
		preload("res://models/physics/food/ingredients/fishSliced.tscn"),
	"res://models/physics/food/ingredients/rice.tscn":
		preload("res://models/physics/food/ingredients/rice.tscn")
}

const INGREDIENT_NAMES = {
	"res://models/physics/food/ingredients/meatRaw.tscn":
		"raw meat",
	"res://models/physics/food/ingredients/pattyRaw.tscn":
		"chopped meat",
	"res://models/physics/food/ingredients/fishRaw.tscn":
		"raw fish",
	"res://models/physics/food/ingredients/fishSliced.tscn":
		"chopped fish",
	"res://models/physics/food/ingredients/buns.tscn":
		"burger buns",
	"res://models/physics/food/ingredients/potato.tscn":
		"potato",
	"res://models/physics/food/ingredients/potatoSliced.tscn":
		"chopped potato",
	"res://models/physics/food/ingredients/tomatoWhole.tscn":
		"tomato",
	"res://models/physics/food/ingredients/tomatoSliced.tscn":
		"chopped tomato",
	"res://models/physics/food/ingredients/rice.tscn":
		"rice"
}

var ingredient_buffer: Array[String] = []

func _ready() -> void:
	interaction.supports_primary = true
	interaction.accepts_primary_while_holding = true
	interaction.interacted.connect(_on_interacted)

	var ancestor := get_parent()
	while ancestor != null and not ancestor is Level:
		ancestor = ancestor.get_parent()

	var level := ancestor as Level
	if is_instance_valid(level):
		level.clear_temp.connect(_clear_ingredients)
	
	interaction.display_name = "Cooking Pot"
	interaction.tooltip_provider = _get_tooltip_actions
	
func _clear_ingredients() -> void:
	ingredient_buffer.clear()

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

	player._release_held_edible()
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

func _get_contents_text() -> String:
	if ingredient_buffer.is_empty():
		return "Empty"

	var ingredient_names: PackedStringArray = []

	for ingredient_path in ingredient_buffer:
		ingredient_names.append(str(
			INGREDIENT_NAMES.get(ingredient_path, "unknown ingredient")
		))

	return ", ".join(ingredient_names)


func _get_tooltip_actions(player: Player) -> Dictionary:
	var primary := ""
	var details := "Contents: %s" % _get_contents_text()

	if is_instance_valid(player.held_edible):
		var ingredient := player.held_edible
		var ingredient_path := ingredient.scene_file_path
		var item_name := ingredient.get_edible_item_name()

		if not INGREDIENT_SCENES.has(ingredient_path):
			details += "\nCannot put %s in the pot" % item_name
		elif ingredient_buffer.has(ingredient_path):
			details += "\nThe pot already contains %s" % item_name
		else:
			primary = "Add ingredient"
	elif not ingredient_buffer.is_empty():
		primary = "Take last ingredient"

	return {
		"details": details,
		"primary": primary,
	}
