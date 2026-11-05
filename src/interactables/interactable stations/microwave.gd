extends Node3D

@onready var interaction: InteractComponent = $InteractComponent

const INGREDIENT_SCENES = {
	"res://models/physics/food/ingredients/meatRaw.tscn":
		preload("res://models/physics/food/ingredients/meatRaw.tscn"),
	"res://models/physics/food/ingredients/pattyRaw.tscn":
		preload("res://models/physics/food/ingredients/pattyRaw.tscn"),
	"res://models/physics/food/ingredients/buns.tscn":
		preload("res://models/physics/food/ingredients/buns.tscn"),
	"res://models/physics/food/ingredients/fishSkinned.tscn":
		preload("res://models/physics/food/ingredients/fishSkinned.tscn"),
	"res://models/physics/food/ingredients/cleanPotato.tscn":
		preload("res://models/physics/food/ingredients/cleanPotato.tscn"),
	"res://models/physics/food/ingredients/potatoSliced.tscn":
		preload("res://models/physics/food/ingredients/potatoSliced.tscn"),
	"res://models/physics/food/ingredients/cleanTomato.tscn":
		preload("res://models/physics/food/ingredients/cleanTomato.tscn"),
	"res://models/physics/food/ingredients/tomatoSliced.tscn":
		preload("res://models/physics/food/ingredients/tomatoSliced.tscn"),
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
	"res://models/physics/food/ingredients/fishSkinned.tscn":
		"raw skinned fish",
	"res://models/physics/food/ingredients/fishSliced.tscn":
		"chopped fish",
	"res://models/physics/food/ingredients/buns.tscn":
		"burger buns",
	"res://models/physics/food/ingredients/cleanPotato.tscn":
		"clean potato",
	"res://models/physics/food/ingredients/potatoSliced.tscn":
		"chopped potato",
	"res://models/physics/food/ingredients/cleanTomato.tscn":
		"clean tomato",
	"res://models/physics/food/ingredients/tomatoSliced.tscn":
		"chopped tomato",
	"res://models/physics/food/ingredients/rice.tscn":
		"rice"
}

# ingredient scene files
const MEAT_PATH = "res://models/physics/food/ingredients/meatRaw.tscn" 
const CHOPPED_MEAT_PATH = "res://models/physics/food/ingredients/pattyRaw.tscn" 
const BUNS_PATH = "res://models/physics/food/ingredients/buns.tscn"
const CHOPPED_TOMATOES_PATH = "res://models/physics/food/ingredients/tomatoSliced.tscn"
const CHOPPED_POTATOES_PATH = "res://models/physics/food/ingredients/potatoSliced.tscn"
const UNCHOPPED_FISH_PATH = "res://models/physics/food/ingredients/fishSkinned.tscn"
const CHOPPED_FISH_PATH = "res://models/physics/food/ingredients/fishSliced.tscn"
const RICE_PATH = "res://models/physics/food/ingredients/rice.tscn"

# dish scene files 
const BURGER_PATH = preload("res://models/physics/food/burger/burgerallPlated.tscn")
const STEAK_PATH = preload("res://models/physics/food/steak/meatCookedPlated.tscn")
const STEW_PATH = preload("res://models/physics/food/stew/stewPlate.tscn")
const SUSHI_PATH = preload("res://models/physics/food/sushi/sushi.tscn")
const RICE_BOWL_PATH = preload("res://models/physics/food/riceBowl/riceBowl.tscn")
const GRILLED_FISH_PATH = preload("res://models/physics/food/grilledFish/grilledFish.tscn")

# preloaded dish textures for confirmation dialog
const BURGER_TEXTURE = preload("uid://c0xyyibaje6e3")
const STEAK_TEXTURE = preload("uid://b6tpa6sao7ri6")
const STEW_TEXTURE = preload("uid://2no7u8k2e01j")
const SUSHI_TEXTURE = preload("uid://cmeeivvg18fe2")
const RICE_BOWL_TEXTURE = preload("uid://deyvt7atxh5xd")
const GRILLED_FISH_TEXTURE = preload("uid://ddfmoioq0rtj7")
const MISTAKE_TEXTURE = preload("uid://b03jbfo8j711j")

var ingredient_buffer: Array[String] = []

@onready var restaurant_main: Level = $".." # restaurant main node

@onready var invalid_recipe_dialog: AcceptDialog = $"../RestaurantUi/InvalidRecipeDialog" # invalid recipe dialog in restaurant_main
@onready var dish_confirm_dialog: ConfirmationDialog = $"../RestaurantUi/DishConfirmDialog" # dish confirmation dialog in restaurant_main
@onready var dish_texture: TextureRect = $"../RestaurantUi/DishConfirmDialog/VBoxContainer/DishTexture" # dish confirmation dialog dish texture
@onready var dish_confirm_label: Label = $"../RestaurantUi/DishConfirmDialog/VBoxContainer/Label" # label for confirm dialog text
@onready var microwave_cooking_alert: AcceptDialog = $"../RestaurantUi/MicrowaveCookingAlert" # alert produced if a dish is still cooking in the microwave
@onready var microwave_cooking_alert_label: Label = $"../RestaurantUi/MicrowaveCookingAlert/VBoxContainer/Label"
@onready var microwave_cooking_alert_dish_texture: TextureRect = $"../RestaurantUi/MicrowaveCookingAlert/VBoxContainer/DishTexture" 

var is_cooking: bool = false # boolean to track whether microwave is currently cooking something
var cooking_duration: float # duration to cook in microwave for, in seconds, determined by dish rarity
var active_player: Player = null
var selected_dish: String = "" # selected dish to cook

func _ready() -> void:
	interaction.display_name = "Microwave"
	interaction.secondary_description = "Check recipe / Cook"
	interaction.supports_primary = true
	interaction.accepts_primary_while_holding = true
	interaction.supports_secondary = true
	interaction.interacted.connect(_on_interacted)
	interaction.alt_interacted.connect(_on_alt_interacted)
	interaction.tooltip_provider = _get_tooltip_actions
	
	var invalid_dialog_label: Label = invalid_recipe_dialog.get_label()
	
	invalid_dialog_label.add_theme_color_override("font_color", Color.WHITE)
	dish_confirm_label.add_theme_color_override("font_color", Color.WHITE)
	microwave_cooking_alert_label.add_theme_color_override("font_color", Color.WHITE)

func _process(delta: float) -> void:
	if not is_cooking:
		return
	
	cooking_duration -= delta 
	
	if cooking_duration <= 0:
		cooking_duration = 0.0
		is_cooking = false
		finish_cooking()
	
func _on_interacted(player: Player) -> void:
	if is_cooking:
		microwave_cooking_alert_label.text = "Currently cooking " + selected_dish.capitalize() + " inside microwave. Please wait until it is fully cooked!"
		microwave_cooking_alert_dish_texture.texture = dish_texture.texture
		microwave_cooking_alert.popup_centered()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE	# re-enable mouse control when dialog pops up
		return
		
	if is_instance_valid(player.held_edible):
		_store_ingredient(player)
	else:
		_take_ingredient(player)

func _on_alt_interacted(_player: Player) -> void:
	if is_cooking:
		microwave_cooking_alert_label.text = "Currently cooking " + selected_dish.capitalize() + " inside microwave. Please wait until it is fully cooked!"
		microwave_cooking_alert_dish_texture.texture = dish_texture.texture
		microwave_cooking_alert.popup_centered()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE	# re-enable mouse control when dialog pops up
		return
		
	active_player = _player
	var current_ingredients: Array = self.ingredient_buffer.duplicate()
	current_ingredients.sort()
	
	var burger_recipe: Array = [BUNS_PATH, CHOPPED_MEAT_PATH, CHOPPED_TOMATOES_PATH]
	burger_recipe.sort()
	
	var steak_recipe: Array = [MEAT_PATH]
	steak_recipe.sort()
	
	var stew_recipe: Array = [CHOPPED_MEAT_PATH, CHOPPED_TOMATOES_PATH, CHOPPED_POTATOES_PATH]
	stew_recipe.sort()
	
	var sushi_recipe: Array = [RICE_PATH, CHOPPED_FISH_PATH]
	sushi_recipe.sort()
	
	var rice_bowl_recipe: Array = [RICE_PATH, CHOPPED_MEAT_PATH]
	rice_bowl_recipe.sort()
	
	var grilled_fish_recipe: Array = [UNCHOPPED_FISH_PATH]
	
	if current_ingredients == burger_recipe:
		selected_dish = "burger"
	elif current_ingredients == steak_recipe:
		selected_dish = "steak"
	elif current_ingredients == stew_recipe:
		selected_dish = "stew"
	elif current_ingredients == sushi_recipe:
		selected_dish = "sushi"
	elif current_ingredients == rice_bowl_recipe:
		selected_dish = "rice_bowl"
	elif current_ingredients == grilled_fish_recipe:
		selected_dish = "grilled_fish"
	else: # invalid recipe
		invalid_recipe_dialog.dialog_text = \
		"Current ingredients in microwave: " \
		+ convert_ingredients_array_to_string(current_ingredients) \
		+ ". " + "\n" \
		+ "Invalid recipe! Please try another combination of ingredients." + "\n" \
		+ "(You can press the Esc key to close/cancel this window)"
		
		invalid_recipe_dialog.popup_centered()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE	# re-enable mouse control when dialog pops up
		return
	
	show_dish_confirmation(current_ingredients)

func _store_ingredient(player: Player) -> void:
	var ingredient := player.held_edible
	var ingredient_path := ingredient.scene_file_path

	if not INGREDIENT_SCENES.has(ingredient_path):
		var error_message = NotificationManager.get_notification_data()["error"].get("only_ingredients_valid_in_microwave")
		NotificationManager.show_error(error_message)
		return

	if ingredient_buffer.has(ingredient_path):
		print(
			"The microwave already contains ",
			ingredient.get_edible_item_name(),
			"."
		)
		return

	var item_name := ingredient.get_edible_item_name()

	player._release_held_edible()
	ingredient_buffer.append(ingredient_path)
	ingredient.queue_free()

	print("Put ", item_name, " in the microwave.")

func _take_ingredient(player: Player) -> void:
	if ingredient_buffer.is_empty():
		print("The microwave is empty.")
		var error_message: String = NotificationManager.get_notification_data()["error"].get("empty_microwave")
		NotificationManager.show_error(error_message)
		return

	var ingredient_path: String = ingredient_buffer.back()
	var ingredient_scene: PackedScene = INGREDIENT_SCENES[ingredient_path]
	var ingredient := ingredient_scene.instantiate() as EdibleItem

	get_tree().current_scene.add_child(ingredient)
	player.pick_up_edible(ingredient)

	if player.held_edible == ingredient:
		ingredient_buffer.pop_back()
		print("Took ", ingredient.get_edible_item_name(), " from the microwave.")
	else:
		ingredient.queue_free()

func start_cooking(dish_string: String):
	is_cooking = true
	print("Started cooking: ", dish_string, " for ", cooking_duration, " seconds.")
	var message: String = NotificationManager.get_notification_data()["action_notification"].get("microwave_start_cooking")
	message = message % [dish_string, cooking_duration]
	NotificationManager.show_side(message)
	
func finish_cooking() -> void:
	print("Cooking complete! Spawning dish: ", selected_dish)
	var message: String = NotificationManager.get_notification_data()["action_notification"].get("microwave_finish_cooking")
	message = message % [selected_dish]
	NotificationManager.show_side(message)
	
	self.ingredient_buffer.clear()
	
	var target_scene: PackedScene = null
	
	match selected_dish:
		"burger":
			target_scene = BURGER_PATH
		"steak":
			target_scene = STEAK_PATH
		"stew":
			target_scene = STEW_PATH
		"sushi":
			target_scene = SUSHI_PATH
		"rice_bowl":
			target_scene = RICE_BOWL_PATH
		"grilled_fish":
			target_scene = GRILLED_FISH_PATH
	
	var completed_edible_item := target_scene.instantiate() as EdibleItem
	restaurant_main.add_child(completed_edible_item)
	
	# each cooked item is already instantiated with correct name, price, rarity. only need to update dish quality
	completed_edible_item.food_data.dish_quality = 50.0
	
	# Give the completed dish a useful position even if pickup fails.
	completed_edible_item.global_position = \
		global_position + Vector3(0, 0, 1.0)

	print("Finished cooking %s (Price %s, Rarity %s, Dish Quality %s%%)." % [
		completed_edible_item.food_data.edible_name,
		str(completed_edible_item.food_data.price),
		str(completed_edible_item.food_data.rarity_level),
		str(completed_edible_item.food_data.dish_quality)
	])
	
func convert_ingredients_array_to_string(arr: Array) -> String:
	# helper function for debugging that converts the current_ingredients array into a clean string with the actual ingredient names
	if arr.size() == 0:
		return "Nothing"
		
	var names = []
	for ingredient in arr:
		var ingredient_string = ""
		match ingredient:
			"res://models/physics/food/ingredients/buns.tscn":
				names.append("Burger buns")
			"res://models/physics/food/ingredients/meatRaw.tscn":
				names.append("Unchopped meat")
			"res://models/physics/food/ingredients/pattyRaw.tscn":
				names.append("Chopped meat")
			"res://models/physics/food/ingredients/tomatoSliced.tscn":
				names.append("Chopped tomatoes")
			"res://models/physics/food/ingredients/cleanTomato.tscn":
				names.append("Unchopped tomatoes")
			"res://models/physics/food/ingredients/potatoSliced.tscn":
				names.append("Chopped potatoes")
			"res://models/physics/food/ingredients/cleanPotato.tscn":
				names.append("Unchopped potatoes")
			"res://models/physics/food/ingredients/fishSkinned.tscn":
				names.append("Unchopped skinned fish")
			"res://models/physics/food/ingredients/fishSliced.tscn":
				names.append("Chopped fish")
			"res://models/physics/food/ingredients/rice.tscn":
				names.append("Rice")
	
	return ", ".join(names)

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
	var details := ""
	
	if is_cooking:
		details = "Currently cooking: %s\nTime remaining: %.1f seconds left" % [selected_dish.capitalize(), cooking_duration]
	else:
		details = "Contents: %s" % _get_contents_text()

	if is_instance_valid(player.held_edible):
		var ingredient := player.held_edible
		var ingredient_path := ingredient.scene_file_path
		var item_name := ingredient.get_edible_item_name()

		if not INGREDIENT_SCENES.has(ingredient_path):
			details += "\nCannot put %s in the microwave" % item_name
		elif ingredient_buffer.has(ingredient_path):
			details += "\nThe microwave already contains %s" % item_name
		else:
			primary = "Add ingredient"
	elif not ingredient_buffer.is_empty():
		primary = "Take last ingredient"
	
	return {
		"details": details,
		"primary": primary,
	}

func show_dish_confirmation(current_ingredients: Array) -> void:
	if not dish_confirm_dialog.confirmed.is_connected(_on_dish_confirmed):
		dish_confirm_dialog.confirmed.connect(_on_dish_confirmed)
	
	var formatted_dish_name = selected_dish.capitalize()
	
	match selected_dish:
		"burger":
			dish_texture.texture = BURGER_TEXTURE
			cooking_duration = 10.0
		"steak":
			dish_texture.texture = STEAK_TEXTURE
			cooking_duration = 20.0
		"stew":
			dish_texture.texture = STEW_TEXTURE
			cooking_duration = 15.0
		"sushi":
			dish_texture.texture = SUSHI_TEXTURE
			cooking_duration = 15.0
		"rice_bowl":
			dish_texture.texture = RICE_BOWL_TEXTURE
			cooking_duration = 15.0
		"grilled_fish":
			dish_texture.texture = GRILLED_FISH_TEXTURE
			cooking_duration = 10.0
	
	dish_confirm_label.text = "Start cooking " + formatted_dish_name + " in the microwave?" + "\n" + "Cooking duration: " + str(cooking_duration) + " seconds" 
		
	dish_confirm_dialog.popup_centered()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE	# re-enable mouse control when dialog pops up

func _on_dish_confirmed() -> void:
	start_cooking(selected_dish)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_dish_confirm_dialog_canceled() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_invalid_recipe_dialog_confirmed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_invalid_recipe_dialog_canceled() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_microwave_cooking_alert_canceled() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_microwave_cooking_alert_confirmed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
