extends Node3D

# ingredient scene files
const MEAT_PATH = "res://models/physics/food/ingredients/meatRaw.tscn" 
const CHOPPED_MEAT_PATH = "res://models/physics/food/ingredients/pattyRaw.tscn" 
const BUNS_PATH = "res://models/physics/food/ingredients/buns.tscn"
const CHOPPED_TOMATOES_PATH = "res://models/physics/food/ingredients.tomatoSliced.tscn" 

# dish scene files 
const BURGER_PATH = preload("res://models/physics/food/burger/burgerallPlated.tscn")
const STEAK_PATH = preload("res://models/physics/food/steak/meatCookedPlated.tscn")

@onready var interaction: InteractComponent = $InteractComponent
@onready var pot = $"../../pot/Cylinder_009/StaticBody3D"

@onready var restaurant_main: Node3D = $"../../.." # restaurant main node

const RHYTHM_MINIGAME_SCENE = preload("uid://bx7cw268w4v8j")

var active_player : Player = null
var selected_dish : String = "" # selected dish to cook
var completed_dish : Food # dish to be returned after player returns to restaurant 

func _ready() -> void:
	interaction.interact_while_holding = true
	interaction.interacted.connect(_on_interacted)

func _on_interacted(_player: Player) -> void:
	active_player = _player
	var current_ingredients: Array = pot.ingredient_buffer.duplicate()
	current_ingredients.sort()
	
	var burger_recipe: Array = [BUNS_PATH, CHOPPED_MEAT_PATH, CHOPPED_TOMATOES_PATH]
	burger_recipe.sort()
	
	var steak_recipe: Array = [MEAT_PATH]
	steak_recipe.sort()
	
	if current_ingredients == burger_recipe:
		selected_dish = "burger"
	elif current_ingredients == steak_recipe:
		selected_dish = "steak"
	else:
		print(
			"Current ingredients in stove: " 
			+ convert_ingredients_array_to_string(current_ingredients) 
			+ ". " + "Invalid recipe!")
		return
	
	start_cooking(selected_dish)

func start_cooking(dish_string: String) -> void:
	restaurant_main.visible = false
	active_player.crosshair.visible = false
	active_player.process_mode = Node.PROCESS_MODE_DISABLED # disable camera movement during minigame
	
	var minigame_instance = RHYTHM_MINIGAME_SCENE.instantiate()
	
	minigame_instance.dish_string = dish_string
	
	minigame_instance.cooking_end.connect(_on_cooking_end)
	minigame_instance.return_to_restaurant.connect(_on_return_to_restaurant.bind(minigame_instance))
	
	get_tree().root.add_child(minigame_instance)

func get_food_data(dish_name: String) -> Dictionary:
	# helper function to return info for specific dish in menu.json
	var restaurant_menu: Dictionary = RestaurantManager.get_menu()
	var foods_list: Array = restaurant_menu.get("foods")
	
	for food_dict in foods_list:
		# match case-insensitively so "burger" matches "Burger"
		if food_dict["name"].nocasecmp_to(dish_name) == 0:
			return food_dict
			
	print("Warning: Dish name '%s' not found in menu.json!" % dish_name)
	return {}
	
func _on_cooking_end() -> void: # when results screen appears in minigame
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_return_to_restaurant(dish_quality: float, minigame_node: Node) -> Food:
	# clear ingredients in pot
	pot.ingredient_buffer.clear()
	
	minigame_node.queue_free()
	
	restaurant_main.visible = true
	active_player.crosshair.visible = true
	active_player.process_mode = Node.PROCESS_MODE_INHERIT # re-enable player controls
	
	var dish_data = get_food_data(selected_dish)
	
	var price: float = dish_data.get("price") 
	var rarity: int = dish_data.get("rarity")
	var name: String = dish_data.get("name")
	
	completed_dish = Food.new(name, price, rarity, dish_quality)
	
	var target_scene: PackedScene = null
	
	match selected_dish:
		"burger":
			target_scene = BURGER_PATH
		"steak":
			target_scene = STEAK_PATH
		
	var completed_edible_item := target_scene.instantiate() as EdibleItem
	
	completed_edible_item.food_data = completed_dish
	
	get_tree().root.add_child(completed_edible_item)
	
	if active_player:
			active_player.pick_up_edible(completed_edible_item)
		
	# check that all variables are initialised correctly after calling pick_up_edible()
	print("Finished cooking %s (Price %s, Rarity %s, Dish Quality %s%%)." % [
		active_player.held_edible.food_data.edible_name,
		str(active_player.held_edible.food_data.price),
		str(active_player.held_edible.food_data.rarity_level),
		str(active_player.held_edible.food_data.dish_quality)
	]) 
	
	return completed_dish

func convert_ingredients_array_to_string(arr : Array) -> String:
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
			"res://models/physics/food/ingredients/tomatoWhole.tscn":
				names.append("Unchopped tomatoes")
			"res://models/physics/food/ingredients/potatoSliced.tscn":
				names.append("Chopped potatoes")
			"res://models/physics/food/ingredients/potato.tscn":
				names.append("Unchopped potatoes")
	
	return ", ".join(names)
			
			
				
			
	
