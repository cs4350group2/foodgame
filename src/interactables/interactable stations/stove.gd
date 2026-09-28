extends Node3D

const MEAT_PATH = "res://models/physics/food/ingredients/meatRaw.tscn"
const BUNS_PATH = "res://models/physics/food/ingredients/buns.tscn"

@onready var interaction: InteractComponent = $InteractComponent
@onready var pot = $"../../pot/Cylinder_009/StaticBody3D"

@onready var restaurant_main: Node3D = $"../../.." # restaurant main node

const RHYTHM_MINIGAME_SCENE = preload("uid://bx7cw268w4v8j")

var active_player : Player = null
var selected_dish = "" # selected dish to cook
var completed_dish : Food # dish to be returned after player returns to restaurant 

func _ready() -> void:
	interaction.interact_while_holding = true
	interaction.interacted.connect(_on_interacted)

func _on_interacted(_player: Player) -> void:
	active_player = _player
	var has_meat: bool = pot.ingredient_buffer.has(MEAT_PATH)
	var has_buns: bool = pot.ingredient_buffer.has(BUNS_PATH)

	if not has_meat:
		print("invalid recipe")
		return
	elif has_buns:
		selected_dish = "burger"
	else:
		selected_dish = "steak"
	
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
	minigame_node.queue_free()
	
	restaurant_main.visible = true
	active_player.crosshair.visible = true
	active_player.process_mode = Node.PROCESS_MODE_INHERIT # re-enable player controls
	
	var dish_data = get_food_data(selected_dish)
	
	var price: float = dish_data.get("price") 
	var rarity: int = dish_data.get("rarity")
	var name: String = dish_data.get("name")
	
	completed_dish = Food.new(name, price, rarity, dish_quality)
	
	# check that all variables are initialised correctly
	print("Finished cooking %s (Price %s, Rarity %s, Dish Quality %s%%." % [
		completed_dish.edible_name,
		str(completed_dish.price),
		str(completed_dish.rarity_level),
		str(completed_dish.dish_quality)
	]) 
	
	return completed_dish
	
