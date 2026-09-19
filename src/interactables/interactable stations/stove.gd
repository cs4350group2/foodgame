extends Node3D

const MEAT_PATH = "res://models/physics/food/steak/meatRaw.tscn"
const BUNS_PATH = "res://models/physics/food/burger/buns.tscn"

@onready var interaction: InteractComponent = $InteractComponent
@onready var pot = $"../../pot/Cylinder_009/StaticBody3D"

@onready var restaurant_main: Node3D = $"../../.." # restaurant main node

const RHYTHM_MINIGAME_SCENE = preload("uid://bx7cw268w4v8j")

var active_player : Player = null

func _ready() -> void:
	interaction.interact_while_holding = true
	interaction.interacted.connect(_on_interacted)

func _on_interacted(_player: Player) -> void:
	active_player = _player
	var has_meat: bool = pot.ingredient_buffer.has(MEAT_PATH)
	var has_buns: bool = pot.ingredient_buffer.has(BUNS_PATH)
	
	var selected_dish = ""

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

func _on_cooking_end() -> void: # when results screen appears in minigame
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_return_to_restaurant(dish_quality: float, minigame_node: Node) -> void:
	print("Dish completed with quality " + str(dish_quality) + "%")
	
	# can handle further logic with dish quality here after MVP 
	
	minigame_node.queue_free()
	
	restaurant_main.visible = true
	active_player.crosshair.visible = true
	active_player.process_mode = Node.PROCESS_MODE_INHERIT # re-enable player controls
	
