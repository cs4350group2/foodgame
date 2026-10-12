extends Node3D

# ingredient scene files
const MEAT_PATH = "res://models/physics/food/ingredients/meatRaw.tscn" 
const CHOPPED_MEAT_PATH = "res://models/physics/food/ingredients/pattyRaw.tscn" 
const BUNS_PATH = "res://models/physics/food/ingredients/buns.tscn"
const CHOPPED_TOMATOES_PATH = "res://models/physics/food/ingredients/tomatoSliced.tscn"
const CHOPPED_POTATOES_PATH = "res://models/physics/food/ingredients/potatoSliced.tscn"

# dish scene files 
const BURGER_PATH = preload("res://models/physics/food/burger/burgerallPlated.tscn")
const STEAK_PATH = preload("res://models/physics/food/steak/meatCookedPlated.tscn")
const STEW_PATH = preload("res://models/physics/food/stew/stewPlate.tscn")

@onready var interaction: InteractComponent = $InteractComponent
@onready var pot = $"../../pot/Cylinder_009/StaticBody3D"

@onready var restaurant_main: Node3D = $"../../.." # restaurant main node
@onready var restaurant_ui: CanvasLayer = $"../../../RestaurantUi" # restaurant UI CanvasLayer node in restaurant_main
@onready var restaurant_stove: Node3D = $"../.." # stove Node3D in restaurant_main (gazini_re)
@onready var invalid_recipe_dialog: AcceptDialog = $"../../../RestaurantUi/InvalidRecipeDialog" # invalid recipe dialog in restaurant_main

@onready var dish_confirm_dialog: ConfirmationDialog = $"../../../RestaurantUi/DishConfirmDialog" # dish confirmation dialog in restaurant_main
@onready var dish_texture: TextureRect = $"../../../RestaurantUi/DishConfirmDialog/VBoxContainer/DishTexture" # dish confirmation dialog dish texture
@onready var dish_confirm_label: Label = $"../../../RestaurantUi/DishConfirmDialog/VBoxContainer/Label" # label for confirm dialog text

# preloaded dish textures for confirmation dialog
const RENDERED_BURGER = preload("uid://d3rorjypontk5")
const RENDERED_MEAT = preload("uid://cotpbx3nt4xan")
const PLACEHOLDER_STEW_IMAGE = preload("uid://cfw527mfd8dg1")

const RHYTHM_MINIGAME_POPUP_SCENE = preload("uid://bl5f06ugjmaiq")

var active_player : Player = null
var selected_dish : String = "" # selected dish to cook

@export var interact_distance: float = 1.2 # distance in front of stove for player to stand at
@export var camera_focus_height: float = 2 # vertical offset above stove for player to look at

func _ready() -> void:
	interaction.supports_secondary = true
	interaction.alt_interacted.connect(_on_alt_interacted)
	
	var invalid_dialog_label: Label = invalid_recipe_dialog.get_label()
	
	invalid_dialog_label.add_theme_color_override("font_color", Color.WHITE)
	dish_confirm_label.add_theme_color_override("font_color", Color.WHITE)

func _on_alt_interacted(_player: Player) -> void:
	active_player = _player
	var current_ingredients: Array = pot.ingredient_buffer.duplicate()
	current_ingredients.sort()
	
	var burger_recipe: Array = [BUNS_PATH, CHOPPED_MEAT_PATH, CHOPPED_TOMATOES_PATH]
	burger_recipe.sort()
	
	var steak_recipe: Array = [MEAT_PATH]
	steak_recipe.sort()
	
	var stew_recipe: Array = [CHOPPED_MEAT_PATH, CHOPPED_TOMATOES_PATH, CHOPPED_POTATOES_PATH]
	stew_recipe.sort()
	
	if current_ingredients == burger_recipe:
		selected_dish = "burger"
	elif current_ingredients == steak_recipe:
		selected_dish = "steak"
	elif current_ingredients == stew_recipe:
		selected_dish = "stew"
	else: # invalid recipe
		invalid_recipe_dialog.dialog_text = \
		"Current ingredients in stove: " \
		+ convert_ingredients_array_to_string(current_ingredients) \
		+ ". " + "\n" \
		+ "Invalid recipe! Please try another combination of ingredients." + "\n" \
		+ "(You can press the Esc key to close/cancel this window)"
		
		invalid_recipe_dialog.popup_centered()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE	# re-enable mouse control when dialog pops up
		return
	
	show_dish_confirmation(current_ingredients)

func start_cooking(dish_string: String) -> void:
	active_player.crosshair.visible = false
	# if restaurant_main.ui_nodes:
	#	for ui: Node in restaurant_main.ui_nodes as Array[Node]:
	#		ui.visible = false
	
	active_player.process_mode = Node.PROCESS_MODE_DISABLED # disable camera movement during minigame
	
	# instantiate minigame popup and instance
	var minigame_popup = RHYTHM_MINIGAME_POPUP_SCENE.instantiate()
	var minigame_instance = minigame_popup.get_node("MinigameFrame/SubViewportContainer/SubViewport/RhythmMain")
	
	minigame_instance.dish_string = dish_string
	
	minigame_instance.cooking_end.connect(_on_cooking_end)
	minigame_instance.return_to_restaurant.connect(_on_return_to_restaurant.bind(minigame_popup))
	
	# handle camera tweening by moving player in front of stove and moving camera to face straight at stove
	var target_player_pos = restaurant_stove.global_position + (restaurant_stove.global_transform.basis.x * interact_distance)
	target_player_pos.y = active_player.global_position.y # keep y-coord the same
	
	var focus_point = restaurant_stove.global_position + Vector3(0, camera_focus_height, 0) 
	
	var tween_pos = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT) 
	
	tween_pos.tween_property(active_player, "global_position", target_player_pos, 0.3) # move player to front of stove in 0.6s
	
	await tween_pos.finished
	
	var camera3d = active_player.get_node("Head/Camera3D")
	var target_camera_transform = camera3d.global_transform.looking_at(focus_point, Vector3.UP)
	
	var tween_rot = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	tween_rot.tween_property(camera3d, "global_transform:basis", target_camera_transform.basis, 0.3) # move camera transform to point above stove
	
	await tween_rot.finished
	
	# finally add minigame popup to restaurant scene
	restaurant_ui.add_child(minigame_popup)

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

func _on_return_to_restaurant(dish_quality: float, minigame_node: Node) -> void:
	# clear ingredients in pot
	pot.ingredient_buffer.clear()
	
	minigame_node.queue_free()
	
	restaurant_main.visible = true
	if restaurant_main.ui_nodes:
		for ui: Node in restaurant_main.ui_nodes as Array[Node]:
			ui.visible = true
	active_player.crosshair.visible = true
	restaurant_main.process_mode = Node.PROCESS_MODE_INHERIT # re-enable restaurant scene
	active_player.process_mode = Node.PROCESS_MODE_INHERIT # re-enable player controls
	active_player.capture_mouse() # restore mouse capture and the controller's capture flag
	
	var target_scene: PackedScene = null
	
	match selected_dish:
		"burger":
			target_scene = BURGER_PATH
		"steak":
			target_scene = STEAK_PATH
		"stew":
			target_scene = STEW_PATH
	
	var completed_edible_item := target_scene.instantiate() as EdibleItem
	restaurant_main.add_child(completed_edible_item)
	
	# each cooked item is already instantiated with correct name, price, rarity. only need to update dish quality
	completed_edible_item.food_data.dish_quality = dish_quality
	
	# Give the completed dish a useful position even if pickup fails.
	completed_edible_item.global_position = \
		active_player.hold_point.global_position

	if not is_instance_valid(active_player.held_edible):
		active_player.pick_up_edible(completed_edible_item)
	else:
		print("Hands occupied; completed dish placed in front of player.")

	print("Finished cooking %s (Price %s, Rarity %s, Dish Quality %s%%)." % [
		completed_edible_item.food_data.edible_name,
		str(completed_edible_item.food_data.price),
		str(completed_edible_item.food_data.rarity_level),
		str(completed_edible_item.food_data.dish_quality)
	])
	
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
	
func show_dish_confirmation(current_ingredients: Array) -> void:
	if not dish_confirm_dialog.confirmed.is_connected(_on_dish_confirmed):
		dish_confirm_dialog.confirmed.connect(_on_dish_confirmed)
	
	var formatted_dish_name = selected_dish.capitalize()
	
	match selected_dish:
		"burger":
			dish_texture.texture = RENDERED_BURGER
		"steak":
			dish_texture.texture = RENDERED_MEAT
		"stew":
			dish_texture.texture = PLACEHOLDER_STEW_IMAGE
		
	dish_confirm_label.text = "Start cooking " + formatted_dish_name + "?" + "\n" 
		
	dish_confirm_dialog.popup_centered()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE	# re-enable mouse control when dialog pops up

func _on_dish_confirmed() -> void:
	start_cooking(selected_dish)
