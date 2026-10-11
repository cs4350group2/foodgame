extends RigidBody3D
class_name EdibleItem

@export var ingredient_name: String = "" # for ingredients

@export var food_data: Food
@export var drink_data: Drink
var is_drink: bool = false
# for now implementation is simple as we only have food. will make adjustments in future iterations

@onready var interaction: InteractComponent = $InteractComponent

func _ready() -> void:
	interaction.supports_primary = true
	interaction.interacted.connect(_on_interacted)

func initialize_data(item_name: String, is_drink: bool = false) -> void:
	if is_drink:
		self.is_drink = true
		var drinks_menu: Dictionary = RestaurantManager.get_drinks_menu()
		var drinks_list: Array = drinks_menu.get("drinks")
		
		for drink in drinks_list:
			if drink["name"] == item_name:
				drink_data = Drink.new(drink["name"], drink["price"], drink["description"], 
				drink["usage"])
	else:
		var restaurant_menu: Dictionary = RestaurantManager.get_menu()
		var foods_list: Array = restaurant_menu.get("foods")
		
		for food in foods_list:
			if food["name"] == item_name:
				food_data = Food.new(food["name"], food["price"], food["rarity"], 
				100.0)

func is_ingredient() -> bool:
	return food_data == null && drink_data == null

func _on_interacted(player: Player) -> void:
	if is_ingredient():
		print("Picked up ingredient: ", ingredient_name)
	elif is_drink:
		print("Picked up edible: ", drink_data.get_edible_name())
	else: # dish/drink
		print("Picked up edible: ", food_data.get_edible_name())
	# Add shared food pickup behavior here later.
	player.pick_up_edible(self)

func get_data() -> Edible:
	if is_drink:
		return drink_data
	else:
		return food_data

func get_edible_item_name() -> String:
	if is_ingredient():
		return ingredient_name
	elif is_drink:
		return drink_data.get_edible_name()
	else:
		return food_data.get_edible_name()

# Mainly used by drinks which will affect customers
func affect_customer(customer: Customer) -> bool:
	return true
